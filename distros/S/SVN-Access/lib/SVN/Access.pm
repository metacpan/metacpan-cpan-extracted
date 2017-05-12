package SVN::Access;

use SVN::Access::Group;
use SVN::Access::Resource;

use open ':encoding(utf8)';

use 5.006001;
use strict;
use warnings;

our $VERSION = '0.11';

sub new {
    my ($class, %attr) = @_;
    my $self = bless(\%attr, $class);
    
    # it's important that we have this.
    die "No ACL file specified!" unless $attr{acl_file};

    if (-e $attr{acl_file}) {
        # parse the file in.
        $self->parse_acl;
    } else {
        # empty acl.
        $attr{acl} = {};
    }
    return $self;
}

sub parse_acl {
    my ($self) = @_;
    open(ACL, '<', $self->{acl_file}) or die "Can't open SVN Access file " . $self->{acl_file} . ": $!";
    my $current_resource;
    my $statement;
    while (my $line = <ACL>) {
        # ignore comments (properly defined)
        next if $line =~ /^#/;
        $line =~ s/\s*#.*$// unless $self->{pedantic};

        # get rid of trailing whitespace.
        $line =~ s/[\s\r\n]+$//;
        next unless $line;

        # handle line continuations
        if ($line =~ /^\s+(.+)$/) {
            $statement .= " $1";
        } else {
            $statement = $line;
        }

        # lookahead and see if the next line is a line continuation
        my $pos = tell(ACL);
        my $nextline = <ACL>;
        seek(ACL, $pos, 0); # rewind the filehandle to where we were.
        if ($nextline && $nextline =~ /^[ \t]+\S/) {
            next;
        }

        next unless $statement;

        if ($statement =~ /^\[\s*(.+?)\s*\]$/) {
            # this statement is defining a new resource.
            $current_resource = $1;
            unless ($current_resource =~ /^(?:groups|aliases)$/) {
                $self->add_resource($current_resource);
            }
        } else {
            # both groups and resources need this parsed.
            my ($k, $v) = $statement =~ /^(.+?)\s*=\s*(.*?)$/;

            # if the previous split didn't work, there's a syntax error
            unless ($k) {
                warn "Unrecognized line $statement\n";
                next;
            }

            if ($current_resource eq "groups") {
                # this is a group
                $self->add_group($k, split(/\s*,\s*/, $v));
            } elsif ($current_resource eq "aliases") {
                # aliases are simple k=v, so let's just store them in ourselves.
                $self->add_alias($k, $v);
            } else {
                # this is a generic resource
                unless ($v =~ /^[rw\s]*$/) {
                    warn "Invalid character in authz rule $v\n";
                }
                if (my $resource = $self->resource($current_resource)) {
                    $resource->authorize($k => $v);
                } else {
                    $self->add_resource($current_resource, $k, $v);
                }
            }
        }

        $statement = undef;
    }
    
    # make sure this isn't empty.
    unless (ref($self->{acl}->{aliases}) eq "HASH") {
        $self->{acl}->{aliases} = {};
    }
    
    close (ACL);
}

sub verify_acl {
    my ($self) = @_;

    # Check for references to undefined groups (Thanks Jesse!)
    my (%groups, @errors);
    if ($self->groups) {
        # gather groups first, in case there are forward refs
        foreach my $group ($self->groups) {
            $groups{$group->name}++;
            # check for loops
            local $SIG{__WARN__} = sub { push @errors, @_; };
            my @g = $self->resolve('@' . $group->name);
        }
        foreach my $group ($self->groups) {
            foreach my $k ($group->members) {
                if ( $k =~ /^@(.*)/ ) {
                    unless ( $groups{$1} ) {
                        push(@errors, "[error] An authz rule (" . $group->name. ") refers to group '$1', which is undefined");
                    }
                } elsif ( $k =~ /^&(.*)/ ) {
                    unless ( $self->aliases->{$1} ) {
                        push(@errors, "[error] An authz rule (" . $group->name . ") refers to alias '$1', which is undefined");
                    }
                }
            }
        }
    }

    foreach my $resource ($self->resources) {
        if (defined($resource) && $resource->authorized) {
            foreach my $k (keys %{$resource->authorized}) {
                if ( $k =~ /^@(.*)/ ) {
                    unless ( $groups{$1} ) {
                        push(@errors, "[error] An authz rule (" . $resource->name . ") refers to group '\@$1', which is undefined");
                    }
                } elsif ( $k =~ /^&(.*)/ ) {
                    unless ( $self->aliases->{$1} ) {
                        push(@errors, "[error] An authz rule (" . $resource->name . ") refers to alias '\&$1', which is undefined");
                    }
                }
            }
        }
    }

    chomp @errors;
    return scalar(@errors) ? join("\n", @errors) : undef;
}

sub write_acl {
    my ($self, $out) = @_;

    # verify the ACL has no errors before writing it out
    if (my $error = $self->verify_acl) {
        die "Error found in ACL:\n$error\n";
    }

    if (ref \$out eq "GLOB" or ref $out) {
        *ACL = $out;
    }
    else {
        $out = $self->{acl_file} unless $out;
        open (ACL, '>', $out) or warn "Can't open ACL file " . $out . " for writing: $!\n";
    }
    
    # aliases now supported!
    if (scalar(keys %{$self->aliases})) {
        print ACL "[aliases]\n";
        foreach my $alias (keys %{$self->aliases}) {
            print ACL $alias . " = " . $self->aliases->{$alias} . "\n";
        }
        print ACL "\n";
    }
    
    # groups now second to aliases
    if ($self->groups) {
        print ACL "[groups]\n";
        foreach my $group ($self->groups) {
            print ACL $group->name . " = " . join(', ', $group->members) . "\n";
        }
        print ACL "\n";
    }
    
    foreach my $resource ($self->resources) {
        if (defined($resource) && $resource->authorized) {
            print ACL "[" . $resource->name . "]\n";
            while (my ($k, $v) = (each %{$resource->authorized})) {
                print ACL "$k = $v\n";
            }
            print ACL "\n";
        }
    }
    
    close(ACL);
}

sub write_pretty {
    my ($self) = @_;

    # verify the ACL has no errors before writing it out
    if (my $error = $self->verify_acl) {
        die "Error found in ACL:\n$error\n";
    }

    my $max_len = 0;

    # Compile a list of names that will appear on the left side
    my @names;
    if (scalar(keys %{$self->aliases})) {
        foreach my $alias (keys %{$self->aliases}) {
            push(@names, $alias);
        }
    }
    
    if ($self->groups) {
        for ($self->groups) {
            push(@names, $_->name);
        }
    }
    if ($self->resources) {
        for ($self->resources) {
            push(@names, keys(%{$_->authorized}));
        }
    }

    # Go through that list looking for the longest name
    for (@names) {
        $max_len = length($_) >= $max_len ? length($_) : $max_len;
    }

    open (ACL, '>', $self->{acl_file}) or warn "Can't open ACL file " . $self->{acl_file} . " for writing: $!\n";
    
    # aliases now fully supported!
    if (scalar(keys %{$self->aliases})) {
        print ACL "[aliases]\n";
        foreach my $alias (keys %{$self->aliases}) {
            print ACL $alias . " " x ($max_len - length($alias)) . " = " . $self->aliases->{$alias} . "\n";
        }
        print "\n";
    } 
    
    # groups now second?
    if ($self->groups) {
        print ACL "[groups]\n";
        foreach my $group ($self->groups) {
            print ACL $group->name . " " x ($max_len - length($group->name)) . " = " . join(', ', $group->members) . "\n";
        }
        print "\n";
    }
    
    foreach my $resource ($self->resources) {
        if (defined($resource) && $resource->authorized) {
            print ACL "[" . $resource->name . "]\n";
            while (my ($k, $v) = (each %{$resource->authorized})) {
                print ACL "$k" . " " x ($max_len - length($k)) . " = $v\n";
            }
            print ACL "\n";
        }
    }
    close(ACL);
}

sub add_alias {
    my ($self, $alias_name, $aliased) = @_;
    $self->{acl}->{aliases}->{$alias_name} = $aliased;
}

sub remove_alias {
    my ($self, $alias_name) = @_;
    delete $self->{acl}->{aliases}->{$alias_name};
}

sub alias {
    my ($self, $alias_name) = @_;
    if (exists ($self->{acl}->{aliases}->{$alias_name})) {
        return $self->{acl}->{aliases}->{$alias_name};
    }
    return undef;
}

sub aliases {
    my ($self) = @_;              
    # give em something if we got nothing!
    unless (ref($self->{acl}->{aliases}) eq "HASH") {
        $self->{acl}->{aliases} = {};
    }
    return $self->{acl}->{aliases};
}

sub add_resource {
    my ($self, $resource_name, @access) = @_;
    if ($resource_name eq "name") {
        $resource_name = shift(@access);
    }
    
    my @acl;
    foreach my $entry (@access) {
        next if $entry eq "authorized";
        
        if (ref($entry) eq "HASH") {
            # unpack the hashref to a list.
            foreach my $key (keys %$entry) {
                push(@acl, $key, $entry->{$key});
            }
        } elsif (ref($entry) eq "ARRAY") {
            push(@acl, @$entry);
        } else {
            push(@acl, $entry);
        }
    }
    
    if ($self->resource($resource_name)) {
        die "Can't add new resource $resource_name: resource already exists!\n";
    } elsif ($resource_name !~ /^(?:\S+\:)?\/.*$/) { # Thanks Matt
        die "Invalid resource format in $resource_name! (format 'repo:/path')!\n";
    } else {
        my $resource = SVN::Access::Resource->new(
            name => $resource_name,
            authorized => \@acl,
        );
        push(@{$self->{acl}->{resources}}, $resource);
        return $resource;
    }
}

sub remove_resource {
    my ($self, $resource_name) = @_;
    my @resources;
    foreach my $resource ($self->resources) {
        push(@resources, $resource) unless $resource->name eq $resource_name;
    }
    $self->{acl}->{resources} = scalar(@resources) ? \@resources : undef;
}

sub resources {
    my ($self) = @_;
    if (ref($self->{acl}->{resources}) eq "ARRAY") {
        return (@{$self->{acl}->{resources}});
    } else {
        return (undef);
    }
}

sub resource {
    my ($self, $resource_name) = @_;
    foreach my $resource ($self->resources) {
        return $resource if defined($resource) && $resource->name eq $resource_name;
    }
    return undef;
}

sub add_group {
    my ($self, $group_name, @initial_members) = @_;

    # get rid of the @ symbol.
    $group_name =~ s/\@//g unless $self->{pedantic};

    if ($self->group($group_name)) {
        die "Can't add new group $group_name: group already exists!\n";
    } else {
        my $group = SVN::Access::Group->new(
            name        =>      $group_name,
            members     =>      \@initial_members,
        );
        push(@{$self->{acl}->{groups}}, $group);
        return $group;
    }
}

sub remove_group {
    my ($self, $group_name) = @_;
    my @groups;

    # get rid of the @ symbol.
    $group_name =~ s/\@//g;
    foreach my $group ($self->groups) {
        push(@groups, $group) unless $group->name eq $group_name;
    }

    $self->{acl}->{groups} = scalar(@groups) ? \@groups : undef;
}

sub groups {
    my ($self) = @_;
    if (ref($self->{acl}->{groups}) eq "ARRAY") {
        return (@{$self->{acl}->{groups}});
    } else {
        return (undef);
    }
}

sub group {
    my ($self, $group_name) = @_;
    foreach my $group ($self->groups) {
        return $group if defined($group) && $group->name eq $group_name;
    }
    return undef;
}

sub resolve {
    my $self = shift;
    my @res;
    my $seen = (ref $_[$#_] eq "ARRAY" ? pop @_ : []);

    foreach my $e (@_) {
        if ($e =~ /^\@(.+)/) {
            # check for loops
            if (grep($_ eq $e, @$seen)) {
                warn "Error: group loop detected ",join(", ", @$seen, $e),"\n";
                return undef;
            }
            push @$seen, $e;
            push @res, map $self->resolve($_, $seen),
                           $self->group($1)->members()
                if $self->group($1);
            pop @$seen;
        } elsif ($e =~ /^\&(.+)/) {
            push @res, map $self->resolve($_), $self->alias($1)
                if $self->alias($1);
        } else {
            push @res, $e;
        }
    }

    return @res;
}

1;
__END__
=head1 NAME

SVN::Access - Perl extension to manipulate SVN Access files

=head1 SYNOPSIS

  use SVN::Access;
  my $acl = SVN::Access->new(acl_file   =>  '/usr/local/svn/conf/my_first_dot_com.conf');

  # add a group to the config
  $acl->add_group('stooges', qw/larry curly moe shemp/);

  # write out the acl (thanks Gil)
  $acl->write_acl;

  # give the stooges commit access to the production version of 
  # our prized intellectual property, the free car giver-awayer.. 
  # (thats how we get users to the site.)
  $acl->add_resource(
      # resource path
      '/free_car_giver_awayer/branches/prod_1.21-sammy_hagar',

      # permissions
      '@stooges' => 'rw',
  );

  $acl->write_pretty; # with the equals signs all lined up.

=head1 DESCRIPTION

B<SVN::Access> includes both an object oriented interface for manipulating 
SVN access files (AuthzSVNAccessFile files), as well as a command line 
interface to that object oriented programming interface (B<svnaclmgr.pl>) in 
the examples/ directory.

=head1 METHODS

=over 4

=item B<new>

the constructor, takes key / value pairs.  only one is required.. in fact 
only one is used right now.  acl_file.

Example:

  my $acl = SVN::Access->new(acl_file   =>  '/path/to/my/acl.conf');

=item B<add_resource>

adds a resource to the current acl object structure.  note: the changes 
are only to the object structure in memory, and one must call the B<write_acl>
method, or the B<write_pretty> method to commit them.

Example:

  $acl->add_resource('/',
    rick    =>  'rw',
    steve   =>  'rw',
    gibb    =>  'r',
  );

=item B<remove_resource>

removes a resource from the current acl object structure.  as with B<add_resource>
these changes are only to the object structure in memory, and must be commited 
with a write_ method.

Example:

  $acl->remove_resource('/');

=item B<resources>

returns an array of resource objects, takes no arguments.

Example:

  for($acl->resources) {
      print $_->name . "\n";
  }

=item B<resource>

resolves a resource name to its B<SVN::Access::Resource> object.

Example:

  my $resource = $acl->resource('/');

=item B<add_group>

adds a group to the current acl object structure.  these changes are 
only to the object structure in memory, and must be written out with 
B<write_acl> or B<write_pretty>.

Example:

  $acl->add_group('stooges', 'larry', 'curly', 'moe', 'shemp');

=item B<remove_group>

removes a group from the current acl object structure.  these changes
are only to the object structure in memory, and must be written out 
with B<write_acl> or B<write_pretty>.

Example:

  $acl->remove_group('stooges');

=item B<groups>

returns an array of group objects, takes no arguments.

Example:

  for($acl->groups) {
      print $_->name . "\n";
  }

=item B<group>

resolves a group name to its B<SVN::Access::Group> object.

Example:

  $acl->group('pants_wearers')->add_member('ralph');

=item B<write_acl>

takes no arguments, writes out the current acl object structure to 
the acl_file specified in the constructor.

Example:

  $acl->write_acl;

=item B<write_pretty>

the same as write_acl, but does it with extra whitespace to line 
things up.

Example:

  $acl->write_pretty;

=item B<verify_acl>

does a pre-flight check of the acl, and returns any errors found 
delimited by new lines.  this routine is called by write_acl and
write_pretty, where these errors will be considered fatal.  be
sure to either call this before $acl->write_*, OR use eval { } 
to capture the return of verify_acl into $@.

Example:

  if (my $error = $acl->verify_acl) {
    print "Problem found in your ACL: $error\n";
  } else {
    $acl->write_acl;
  }

=item B<add_alias>

adds an alias to [aliases], takes 2 arguments: the alias name and
the aliased user.

Example: 
  $acl->add_alias('mikey', 'uid=mgregorowicz,ou=people,dc=mg2,dc=org');

=item B<remove_alias>

removes an alias by name, takes the alias name as an argument.

Example:
  $acl->remove_alias('mikey');
  
=item B<alias>

returns the value of an alias, uses exists() first so it will not
autovivify the key in the hash.

Example:
  print $acl->alias('mikey') . "\n";
  
=item B<aliases>

returns a hashref that contains the aliases.  editing this hashref
will edit the data inside the $acl object.

Example:
  foreach my $alias (keys %{$acl->aliases}) {
    print "$alias: " . $acl->aliases->{$alias} . "\n";
  }

=item B<resolve>

Returns a fully resolved list of users part of the given groups and/or
aliases.  Groups must be specified with a leading "@" and aliases with
a leading "&", all else will be returned verbatim.  This recurses
through all definitions to get actual user names (so groups within
groups will be handled properly).

=back

=head1 SEE ALSO

subversion (http://subversion.tigris.org/), SVN::ACL, svnserve.conf

=head1 AUTHOR

Michael Gregorowicz, E<lt>mike@mg2.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2017 by Michael Gregorowicz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
