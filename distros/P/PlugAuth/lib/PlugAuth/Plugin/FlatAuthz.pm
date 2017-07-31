package PlugAuth::Plugin::FlatAuthz;

# ABSTRACT: Authorization using flat files for PlugAuth
our $VERSION = '0.38'; # VERSION


use strict;
use warnings;
use 5.010001;
use Log::Log4perl qw( :easy );
use Text::Glob qw( match_glob );
use Clone qw( clone );
use Role::Tiny::With;
use File::Touch;
use List::Util qw( uniq );

with 'PlugAuth::Role::Plugin';
with 'PlugAuth::Role::Authz';
with 'PlugAuth::Role::Refresh';
with 'PlugAuth::Role::Flat';

our %all_users;
our %groupUser;           # $groupUser{$group}{$user} is true iff $user is in $group
our %userGroups;          # $userGroups{$user}{$group} is true iff $user is in $group
our %resourceActionGroup; # $resourceActionGroup{$resource}{$action}{$group} is true iff $group can do $action on $resource
our %actions;             # All defined actions $actions{$action} = 1;
our %hostTag;             # $hostTag{$host}{$tag} is true iff $user has tag $tag


sub refresh
{
  my($class) = @_;
  my $config = $class->global_config;
  if ( has_changed( $config->group_file ) )
  {
    %all_users = map { $_ => 1 } __PACKAGE__->app->auth->all_users;
    %groupUser = ();
    my %data = __PACKAGE__->read_file( $config->group_file, nest => 1, lc_values => 1, lc_keys => 1 );
    for my $k (keys %data)
    {
      my %users;
      for my $v (keys %{ $data{$k} })
      {
        my @matches = match_glob( $v, keys %all_users);
        next unless @matches;
        @users{ @matches } = (1) x @matches;
      }
      $groupUser{$k} = \%users;
    }
    %userGroups = __PACKAGE__->_reverse_nest(%groupUser);
  }
  if ( has_changed( $config->resource_file ) )
  {
    %all_users = map { $_ => 1 } __PACKAGE__->app->auth->all_users;
    %resourceActionGroup = __PACKAGE__->read_file( $config->resource_file, nest => 2, lc_values => 1 );

    foreach my $resource (keys %resourceActionGroup)
    {
      # TODO: maybe #g for group
      if($resource =~ /#u/) {
        my $value = delete $resourceActionGroup{$resource};

        foreach my $user (keys %all_users)
        {
          my $new_resource = $resource;
          my $new_value = clone $value;

          $new_resource =~ s/#u/$user/g;

          foreach my $users (values %$new_value)
          {
            if(defined $users->{'#u'})
            {
              delete $users->{'#u'};
              $users->{$user} = 1;
            }
          }

          $resourceActionGroup{$new_resource} = $new_value;
        }
      }
    }

    %actions = map { map { $_ => 1} keys %$_ } values %resourceActionGroup;
  }
  my $h = $config->host_file(default => '');
  if ( ( $h ) && has_changed( $h ) )
  {
    %hostTag = __PACKAGE__->read_file( $h, nest => 1 );
  }
  1;
}

sub init
{
  # When the user list has changed, the group files need to be reloaded, because
  # each user has his/her own group, so we touch the group file

  my($self) = @_;
    
  $self->flat_init;
    
  my $touch = File::Touch->new(
    mtime_only => 1,
    no_create => 1,
  );
  my @list = ($self->app->config->group_file(default => []));
    
  $self->app->on(user_list_changed => sub {
    $touch->touch(@list);
  });
}


sub can_user_action_resource
{
  my ($class, $user,$action,$resource) = @_;
  $user = lc $user;
  my $found;
  GROUP:
  for my $group ( $user, keys %{ $userGroups{$user} } )
  {
    # check exact match on the resource so / will match
    if($resourceActionGroup{$resource} 
    && $resourceActionGroup{$resource}{$action} 
    && $resourceActionGroup{$resource}{$action}{$group})
    {
      $found = "group: $group resource: $resource";
      last GROUP;
    }
    for my $subresource (__PACKAGE__->_prefixes($resource))
    {
      next unless $resourceActionGroup{$subresource}
      &&          $resourceActionGroup{$subresource}{$action}
      &&          $resourceActionGroup{$subresource}{$action}{$group};
      $found = "group: $group resource: $subresource";
      last GROUP;
    }
  }
  return $found;
}


sub match_resources {
  my($class, $resourceregex) = @_;
  return (grep /$resourceregex/, keys %resourceActionGroup);
}

sub _reverse_nest {
  my $class = shift;
  # Given a nested hash ( a => b => c), return one with (b => a => c);
  my %h = @_;
  my %new;
  while (my ($a,$bc) = each %h)
  {
    while (my ($b,$c) = each %$bc)
    {
      $new{$b}{$a} = $c;
    }
  }
  return %new;
}

sub _prefixes {
  my $class = shift;
  # Given a string "/a/b/c/d" return an array of prefixes :
  #  "/", "/a", "/a/b", /a/b/c", "/a/b/c/d"
  my $str = shift;
  my @p = split /\//, $str;
  my @prefixes = ( map { '/'. join '/', @p[1..$_] } 0..$#p );
  return @prefixes;
}


sub host_has_tag {
  my ($class, $host, $tag) = @_;
  return exists($hostTag{$host}{$tag});
}


sub actions {
  return sort keys %actions;
}


sub groups_for_user {
  my $class = shift;
  my $user = shift or return ();
  $user = lc $user;
  return unless $all_users{$user};
  return [ sort $user, keys %{ $userGroups{ $user } || {} } ];
}


sub all_groups {
  return sort keys %groupUser;
}


sub users_in_group {
  my($class, $group) = @_;
  return unless defined $group;
  $group = lc $group;
  return unless defined $groupUser{$group};
  return [keys %{ $groupUser{$group} }];
}


sub create_group
{
  my($self, $group, $users) = @_;

  unless(defined $group)
  {
    WARN "Group not provided";
    return 0;
  }

  if(defined $groupUser{$group})
  {
    WARN "Group $group already exists";
    return 0;
  }

  $users = '' unless defined $users;

  my $filename = $self->global_config->group_file;

  my $ok = $self->lock_and_update_file($filename, sub {
    use autodie;
    my($fh) = @_;

    my $buffer = '';
    while(! eof $fh)
    {
      my $line = <$fh>;
      chomp $line;
      $buffer .= "$line\n";
    }
    $buffer .= "$group : $users\n";
    
    $buffer;
  });
    
  return 0 unless $ok;

  INFO "created group $group with members $users";
  return 1;
}


sub delete_group
{
  my($self, $group) = @_;
    
  $group = lc $group;

  unless($group && defined $groupUser{$group})
  {
    WARN "Group $group does not exist";
    return 0;
  }

  my $filename = $self->global_config->group_file;

  my $ok = $self->lock_and_update_file($filename, sub {
    use autodie;
    my($fh) = @_;
    my $buffer = '';
    while(! eof $fh)
    {
      my $line = <$fh>;
      chomp $line;
      my($thisgroup, $password) = split /\s*:/, $line;
      next if defined $thisgroup && lc $thisgroup eq $group;
      $buffer .= "$line\n";
    }

    $buffer;
  });

  return 0 unless $ok;

  INFO "deleted group $group";
  return 1;
}


sub update_group
{
  my($self, $group, $users) = @_;

  $group = lc $group;
    
  unless($group && defined $groupUser{$group})
  {
    WARN "Group $group does not exist";
    return 0;
  }

  return 1 unless defined $users;

  my $filename = $self->global_config->group_file;

  my $ok = $self->lock_and_update_file($filename, sub {
    use autodie;
    my($fh) = @_;

    my $buffer = '';
    while(! eof $fh)
    {
      my $line = <$fh>;
      chomp $line;
      my($thisgroup) = split /\s*:/, $line;
      $line =~ s{:.*$}{: $users} if defined $thisgroup && lc($thisgroup) eq $group;
      $buffer .= "$line\n";
    }
    $buffer;
  });
  
  return 0 unless $ok;
  INFO "update group $group set members to $users";
  return 1;
}


sub add_user_to_group
{
  my($self, $group, $user) = @_;
  $group = lc $group;
  $user  = lc $user;

  unless($group && defined $groupUser{$group})
  {
    WARN "Group $group does not exist";
    return 0;
  }
  
  my $new_user_list;
  my $filename = $self->global_config->group_file;
  
  my $ok = $self->lock_and_update_file($filename, sub {
    use autodie;
    my ($fh) = @_;
    
    my $buffer = '';
    while(! eof $fh)
    {
      my $line = <$fh>;
      chomp $line;
      my($thisgroup, $users) = split /\s*:\s*/, $line;
      if(defined $thisgroup && lc($thisgroup) eq $group)
      {
        $users = join ',', uniq (split(/\s*,\s*/, $users), $user);
        $buffer .= "$thisgroup: $users\n";
        $new_user_list = $users;
      }
      else
      {
        $buffer .= "$line\n";
      }
    }
    
    $buffer;
  });
  
  return unless $ok;
  INFO "update group $group set members to $new_user_list";
  return $new_user_list;
}


sub remove_user_from_group
{
  my($self, $group, $user) = @_;
  $group = lc $group;
  $user  = lc $user;

  unless($group && defined $groupUser{$group})
  {
    WARN "Group $group does not exist";
    return 0;
  }
  
  my $new_user_list;
  my $filename = $self->global_config->group_file;
  
  my $ok = $self->lock_and_update_file($filename, sub {
    use autodie;
    my ($fh) = @_;
    
    my $buffer = '';
    while(! eof $fh)
    {
      my $line = <$fh>;
      chomp $line;
      my($thisgroup, $users) = split /\s*:\s*/, $line;
      if(defined $thisgroup && lc($thisgroup) eq $group)
      {
        $users = join ',', grep { lc($_) ne $user } uniq @{ $self->users_in_group($group) };
        $buffer .= "$thisgroup: $users\n";
        $new_user_list = $users;
      }
      else
      {
        $buffer .= "$line\n";
      }
    }
    
    $buffer;
  });
  
  return unless $ok;
  INFO "update group $group set members to $new_user_list";
  return $new_user_list;
}


sub grant
{
  my($self, $group, $action, $resource) = @_;
    
  $group = lc $group;

  unless($group && (defined $groupUser{$group} || defined $all_users{$group}))
  {
    WARN "Group (or user) $group does not exist";
    return 0;
  }

  $resource =~ s{^/?}{/};

  if($resourceActionGroup{$resource}->{$action}->{$group})
  {
    WARN "grant already added $group $action $resource";
    return 1;
  }

  my $filename = $self->global_config->resource_file;

  my $ok = $self->lock_and_update_file($filename, sub {
    use autodie;
    my($fh) = @_;

    my $buffer = '';
        
    while(! eof $fh)
    {
      my $line = <$fh>;
      chomp $line;
      $buffer .= "$line\n";
    }
    $buffer .= "$resource ($action) : $group\n";
    $buffer;
  });
  
  return 0 unless $ok;
  INFO "grant $group $action $resource";
  return 1;
}


sub revoke
{
  my($self, $group, $action, $resource) = @_;
    
  $group = lc $group;

  unless($group && (defined $groupUser{$group} || defined $all_users{$group}))
  {
    WARN "Group (or user) $group does not exist";
    return 0;
  }

  $resource = '/' . $resource unless $resource =~ /\//;

  unless($resourceActionGroup{$resource}->{$action}->{$group})
  {
    WARN "Group (or user) $group not authorized to $action on $resource";
    return 0;
  }
    
  my $filename = $self->global_config->resource_file;

  my $ok = $self->lock_and_update_file($filename, sub {
    use autodie;
    my($fh) = @_;

    my $buffer = '';
    while(! eof $fh)
    {
      my $line = <$fh>;
      chomp $line;
      if($line =~ /^#/)
      {
        $buffer .= "$line\n";
      }
      elsif($line =~ m{^\s*(.*?)\s*\((.*?)\)\s*:\s*(.*?)\s*$} && $1 eq $resource && $2 eq $action)
      {
        my(@groups) = grep { $_ ne $group } split /,/, $3;
        $buffer .= "$resource ($action) : " . join(',', @groups) . "\n"
          if @groups > 0;
      }
      else
      {
        $buffer .= "$line\n";
      }
    }
    $buffer;
  });
  
  return 0 unless $ok;
  INFO "revoke $group $action $resource";
  return 1;
}


sub granted
{
  my($self) = @_;
    
  my $filename = $self->global_config->resource_file;
    
  my @granted_list;
    
  my $ok = $self->lock_and_read_file($filename, sub {
    use autodie;
    my($fh) = @_;
    
    while(! eof $fh)
    {
      my $line = <$fh>;
      next if $line =~ /^#/;
      push @granted_list, "$1 ($2): $3" 
        if $line =~ m{^\s*(.*?)\s*\((.*?)\)\s*:\s*(.*?)\s*$};
    }
  });
    
  return \@granted_list;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Plugin::FlatAuthz - Authorization using flat files for PlugAuth

=head1 VERSION

version 0.38

=head1 SYNOPSIS

In your /etc/PlugAuth.conf

 ---
 url: http://localhost:1234
 group_file: /etc/plugauth/group.txt
 resource_file: /etc/plugauth/resource.txt
 host_file: /etc/plugauth/host.txt

touch the storage files:

 % touch /etc/plugauth/group.txt \
         /etc/plugauth/resource.txt \
         /etc/plugauth/host.txt

Start PlugAuth:

 % plugauth start

=head1 DESCRIPTION

This is the default Authorization plugin for L<PlugAuth>.  It is designed to work closely
with L<PlugAuth::Plugin::FlatAuth> which is the default Authentication plugin.

This plugin provides storage for groups, hosts and access control for PlugAuth.  In addition
it provides a mechanism for PlugAuth to alter the group, host and access control databases.

=head1 CONFIGURATION

=head2 group_file

The group file looks similar to a standard UNIX /etc/group file.  Entries can be changed using
either your favorite editor, or by using L<PlugAuth::Client>.  In this example there is a group
both to which both  bob and alice belong:

 both: alice, bob

Group members can be specified using a glob (see L<Text::Glob>) which match against the set of all users:

 all: *

Each user automatically gets his own group, so if there are users named bob and alice, this is 
unnecessary:

 alice: alice
 bob: bob

=head2 resource_file

Each line of resource.txt has a resource, an action (in parentheses), and then a list of users or groups.  
The line grants permission for those groups to perform that action on that resource :

 /house/door (enter) : alice, bob
 /house/backdoor (enter) : both
 /house/window (break) : alice
 /house (GET) : bob

=head2 host_file

The host file /etc/pluginauth/host.txt looks like this :

 192.168.1.99:trusted
 192.168.1.100:trusted

The IP addresses on the right represent hosts from which authorization should succeed.

=head1 METHODS

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>refresh

Refresh the data (checks the files, and re-reads if necessary).

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>can_user_action_resource( $user, $action, $resource )

If $user can perform $action on $resource, return a string containing
the group and resource that permits this.  Otherwise, return false.

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>match_resources( $regex )

Given a regex, return all resources that match that regex.

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>host_has_tag( $host, $tag )

Returns true if the given host has the given tag.

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>actions

Returns a list of actions.

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>groups_for_user( $user )

Returns the groups the given user belongs to as a list ref.
Returns undef if the user does not exist.

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>all_groups

Returns a list of all groups.

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>users_in_group( $group )

Return the list of users (as an array ref) that belong 
to the given group.  Each user belongs to a special 
group that is the same as their user name and just 
contains themselves, and this will be included in the 
list.

Returns undef if the group does not exist.

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>create_group( $group, $users )

Create a new group with the given users.  $users is a comma
separated list of user names.

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>delete_group( $group )

Delete the given group.

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>update_group( $group, $users )

Update the given group, setting the set of users that belong to that
group.  The existing group membership will be replaced with the new one.
$users is a comma separated list of user names.

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>add_user_to_group( $group, $user )

Add the given user to the given group.

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>remove_user_from_group( $group, $user )

Remove the given user from the given group

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>grant( $group, $action, $resource )

Grant the given group or user ($group) the authorization to perform the given
action ($action) on the given resource ($resource).

=head2 PlugAuth::Plugin::FlatAuthz-E<gt>revoke( $group, $action, $resource )

Revoke the given group or user ($group) the authorization to perform the given
action ($action) on the given resource ($resource).

=head2 $plugin-E<gt>granted

Returns a list of granted permissions

=head1 SEE ALSO

L<PlugAuth>, L<PlugAuth::Plugin::FlatAuth>

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
