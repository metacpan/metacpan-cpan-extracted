package PlugAuth::Client;

use strict;
use warnings;
use 5.010001;
use Log::Log4perl qw(:easy);
use Clustericious::Client;

# ABSTRACT: PlugAuth Client
our $VERSION = '0.38'; # VERSION


route welcome      => 'GET', '/';


route auth         => 'GET', '/auth';


route_doc authz    => "user action resource";
sub authz
{
  my($self, $user, $action, $resource) = @_;

  my $url = Mojo::URL->new( $self->server_url );

  $resource = "/$resource" unless $resource =~ m{^/};
  
  $url->path("/authz/user/$user/$action$resource");

  $self->_doit('GET', $url);
}


route user         => 'GET', '/user';


route create_user => 'POST', '/user', \("--user username --password password");
route_args create_user => [
  { name => 'user',     type => '=s', required => 1, modifies_payload => 'hash' },
  { name => 'password', type => '=s', required => 1, modifies_payload => 'hash' },
  { name => 'groups',   type => '=s', required => 0, modifies_payload => 'hash' },
];


route delete_user  => 'DELETE',  '/user', \("user");
route_args delete_user => [
  { name => 'user', type => '=s', required => 1, modifies_url => 'append' },
];


route groups       => 'GET', '/groups', \("user");


route_doc change_password => 'username password';
sub change_password
{
  my($self, $user, $password) = @_;
  my $url = Mojo::URL->new( $self->server_url );
  $url->path("/user/$user");
  $self->_doit('POST', $url, { password => $password });
}


route group        => 'GET', '/group';


route users        => 'GET', '/users', \("group");


route create_group => 'POST', '/group', \("--group group --users user1,user2,...");
route_args create_group => [
  { name => 'group', type => '=s', required => 1, modifies_payload => 'hash'  },
  { name => 'users', type => '=s', required => 1, modifies_payload => 'hash'  },
];


route_doc 'update_group' => 'group --users user1,user2,...';
route_args update_group => [
  { name => 'group', type => '=s', required => 1, modifies_url => 'append', 'positional' => 'one' },
  { name => 'users', type => '=s', required => 1 },
];
sub update_group
{
  my $self = shift;
  my $group = shift;
  my $args = ref($_[0]) eq 'HASH' ? $_[0] : {@_}; 

  LOGDIE "group needed for update"
    unless $group;

  my $url = Mojo::URL->new( $self->server_url );
  $url->path("/group/$group");

  TRACE("updating $group ", $url->to_string);

  $self->_doit('POST', $url, { users => $args->{users} // $args->{'--users'} });
}


route delete_group => 'DELETE', '/group', \("group");


route 'group_add_user' => 'POST' => '/group';
route_args 'group_add_user' => [
  { name => 'group', type => '=s', modifies_url => 'append', 'positional' => 'one' },
  { name => 'user',  type => '=s', modifies_url => 'append', 'positional' => 'one' },
];


route 'group_delete_user' => 'DELETE' => '/group';
route_args 'group_delete_user' => [
  { name => 'group', type => '=s', modifies_url => 'append', 'positional' => 'one' },
  { name => 'user',  type => '=s', modifies_url => 'append', 'positional' => 'one' },
];


route 'grant' => 'POST' => '/grant';
route_args 'grant' => [
  { name => 'user',     type => '=s', modifies_url => 'append', positional => 'one' },
  { name => 'action',   type => '=s', modifies_url => 'append', positional => 'one' },
  { name => 'resource', type => '=s', modifies_url => 'append', positional => 'one' },
];


route 'revoke' => 'DELETE' => '/grant';
route_args 'revoke' => [
  { name => 'user',     type => '=s', modifies_url => 'append', positional => 'one' },
  { name => 'action',   type => '=s', modifies_url => 'append', positional => 'one' },
  { name => 'resource', type => '=s', modifies_url => 'append', positional => 'one' },
];


route granted      => 'GET', '/grant';


route actions      => 'GET', '/actions';


route host_tag     => 'GET', '/host', \("host tag");


route resources    => 'GET', '/authz/resources', \("user action resource_regex");


sub _remove_prefixes
{
  my @in = sort @_;
  my @out;
  while(my $item = shift @in)
  {
    @in = grep { substr($_, 0, length $item) ne $item } @in;
    push @out, $item;
  }
  @out;
}

route_doc action_resources => "user";
sub action_resources
{
  my($self, $user) = @_;
  my %table;
  foreach my $action (@{ $self->actions })
  {
    my $resources = $self->resources($user, $action, '/');
    $table{$action} = [_remove_prefixes(@$resources)] if @$resources > 0;
  }
  \%table;
}


route_doc action_resource => 'audit';
sub audit
{
  my($self, $year, $month, $day) = @_;
  my $uri;
  if(defined $day)
  {
    $uri = join('/', '', 'audit', $year, sprintf("%02d", $month), sprintf("%02d", $day));
  }
  else
  {
    # TODO: Clustericious::Client doesn't handle 302 correctly
    $uri = join('/', '', 'audit', 'today');
  }
  $self->_doit(GET => $uri);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

PlugAuth::Client - PlugAuth Client

=head1 VERSION

version 0.38

=head1 SYNOPSIS

In a perl program :

 my $r = PlugAuth::Client->new;

 # Check auth server status and version
 my $check = $r->status;
 my $version = $r->version;

 # Authenticate user "alice", pw "sesame"
 $r->login("alice", "sesame");
 if ($r->auth) {
    print "authentication succeeded\n";
 } else {
    print "authentication failed\n";
 }

 # Authorize "alice" to "POST" to "/board"
 if ($r->authz("alice","POST","board")) {
     print "authorization succeeded\n";
 } else {
     print "authorization failed\n";
 }

=head1 DESCRIPTION

This module provides a perl front-end to the PlugAuth API.  For a stripped
down interface to just the authentication and authorization API (that is
not including the user/group/authorization management functions), see
L<PlugAuth::Client::Tiny>.

=head1 METHODS

=head2 $client-E<gt>auth

Returns true if the PlugAuth server can authenticate the user.  
Username and passwords can be specified with the login method or
via the application's configuration file, see L<Clustericious::Client>
for details.

=head2 $client-E<gt>authz($user $action, $resource)

Returns true if the given user ($user) is authorized to perform the
given action ($action) on the given resource ($resource).

=head2 $client-E<gt>user

Returns a list reference containing all usernames.

=head2 $client-E<gt>create_user( %args )

Create a user with the given username and password.

=over 4

=item * user

The new user's username

REQUIRED

=item * password

The new user's password

REQUIRED

=item * groups

List of groups as a comma separated string.  Using this option requires that
the server is running PlugAuth 0.21 or better.

=back

=head2 $client-E<gt>delete_user( $username )

Delete the user with the given username.

=head2 $client-E<gt>groups($user)

Returns a list reference containing the groups that the given user ($user)
belongs to.

=head2 $client-E<gt>change_password($user, $password)

Change the password of the given user ($user) to a new password ($password).

=head2 $client-E<gt>group

Returns a list reference containing all group names.

=head2 $client-E<gt>users($group)

Returns the list of users belonging to the given group ($group).

=head2 $client-E<gt>create_group( \%args )

Create a group.

=over 4

=item * group

The name of the new group

=item * users

Comma separated list (as a string) of the users that
should initially belong to this group.

=back

=head2 $client-E<gt>update_group( $group, '--users' => $users )

Update the given group ($group) replacing the existing list with
the new list ($users), which is a comma separated list as a string.

=head2 $client-E<gt>delete_group( $group )

Delete the given group ($group).

=head2 $client-E<gt>group_add_user( $group, $user )

Adds the given user ($user) to the given group ($group)

=head2 $client-E<gt>group_delete_user( $group, $user )

Delete the given user ($user) from the given group ($group)

=head2 $client-E<gt>grant( $user, $action, $resource )

Grants the given user ($user) the authorization to perform the given
action ($action) on the given resource ($resource).

=head2 $client-E<gt>revoke( $user, $action, $resource )

Revokes permission for the give user ($user) to perform the given action ($action)
on the given resource ($resource).

=head2 $client-E<gt>granted

Returns a list of granted permissions

=head2 $client-E<gt>actions

Returns a list reference containing the actions that the PlugAuth server
knows about.

=head2 $client-E<gt>host_tag($ip_address, $tag)

Returns true if the host specified by the given IP address ($ip_address)
has the given host tag ($tag).

=head2 $client-E<gt>resources( $user, $action, $resource_regex )

Returns a list reference containing the resources that match the regex
provided ($resource_regex) that the given user ($user) can perform the
given action ($action).  To see all the resources that the user can
perform the given action against, pass in '.*' as the regex.

=head2 $client-E<gt>action_resources( $user )

Returns a hash reference of all actions and resources that the given
user ($user) can perform.  The keys in the returned hash are the 
actions and the values are list references containing the resources
where those actions can be performed by the user.

=head2 $client-E<gt>audit( $year, $month, $day )

Interface to the L<Audit|PlugAuth::Plugin::Audit> plugin, if it is available.

=head1 SEE ALSO

L<Clustericious::Client>, 
L<PlugAuth>, 
L<plugauthclient>, 
L<plugauthpasswd>,
L<PlugAuth::Client::Tiny>

=head1 AUTHOR

Graham Ollis <gollis@sesda3.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by NASA GSFC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
