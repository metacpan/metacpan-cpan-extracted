package Session;

use strict;
use Apache::Session::Flex;
use base qw(Apache::Session::Flex);

$Session::VERSION = 0.01;

sub new
{
    my($class, $id, @args) = @_;
    my $self;
    eval
    {
        $self = $class->TIEHASH($id, (ref $args[0] ? $args[0] : {@args}));
    };
    Session->error($@) if $@;
    return $self;
}

sub session_id {shift->FETCH('_session_id')}
sub get {shift->FETCH(@_)}
sub set {shift->STORE(@_)}
sub remove {shift->DELETE(@_)}
sub clear {shift->CLEAR(@_)}
sub exists {shift->EXISTS(@_)}

sub keys {grep $_ ne '_session_id', keys %{shift->{data}}}
sub release {undef($_[0])}

sub error
{
    $Session::ERROR = $_[1] if defined $_[1];
    return $Session::ERROR;
}

1;

__END__

=pod

=head1 NAME

Session - Object Oriented wrapper around Apache::Session to avoid its tie mechanism

=head1 SYNOPSIS

    use Session;

    my %session_config = (
      Store     => 'DB_File',
      Lock      => 'Null',
      Generate  => 'MD5',
      Serialize => 'Storable',
      # DB_File backend option
      FileName  => 'sessions.db',
    );

    # make a fresh session for a first-time visitor
    my $session = new Session undef, %session_config;

    # stick some stuff in it
    $session->set(visa_number => '1234 5678 9876 5432';

    # ...time passes...

    # get the session data back out again during some other request
    my $session = new Session $session_id, %session_config;

    validate($session->get('visa_number'));

    # delete a session from the object store permanently
    $session->delete();

=head1 DESCRIPTION

This module is a simple wrapper around Apache::Session without the
C<tie> interface. Tie is too slow for web applications (think
mod_perl) and you may prefere a standard OO API instead of a poor tie
interface (I hate tie).

You should look for Apache::Session and Apache::Session::Flex man page
for more details on the session management. We will explain here only
things that differs from Apache::Session.

Note that neither Apache::Session nor Session are liked with mod_perl,
you should use Session in any programs for the web or not.

=head1 METHODS

=head2 new

  $session = new Session $id, %options

This method return a wrapped Apache::Session::Flex object (see related
manual for more details). The first element is the session id (undef
for create one), followed by Apache::Session::Flex's options.

Unlike Apache::Session, die isn't called if error appended while the
session initialization (Session do the eval for you). This method
return undef on error. You can get the error string by calling
Session->error();

=head2 session_id

  $session_id = $session->session_id();

  # trap errors
  die(Session->error()) unless defined $session_id;

Gets the session_id, it's equivalent to get the _session_id key with
Apache::Session.

=head2 get

  $value = $session->get("key");

Get value of the key from the session.

=head2 set

  $session->set(key => "value");

Affect a value to a key in the session.

=head2 remove

  $session->remove("key");

Removes a key from the session.

=head2 clear

  $session->clear();

Clear all keys in the session.

=head2 exists

  $boolean = $session->exists("key");

Test if key exists.

=head2 keys

  @keys = $session->keys();

Returns list of keys of parameters in session. Note that it doesn't
returns the "_session_id" key as Apache::Session do.

=head2 release

  $session->release();

Usually called at the destruction time of object, but can be called
manually. Same as calling undef of untie on an Apache::Session tied
hash.

=head2 delete

  $session->delete();

Permanently removing the session from storage. Same as calling
tied($session)->delete() on an Apache::Session tied hash.

=head2 error

  $session->error();

  Session->error();

Returns the last appended error message.

=head1 SEE ALSO

Apache::Session, Apache::Session::Flex

Session is a really basic module for avoiding the Apache::Session tie
mechanism. Nothing is really implemented in Session, all the job is
done by Apache::Session.

=head1 AUTHORS

Olivier Poitrey E<lt>rs@rhapsodyk.netE<gt> is the author of Session.

Jeffrey Baker E<lt>jwbaker@acm.orgE<gt> is the author of
Apache::Session.

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 2.1 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
USA

=cut
