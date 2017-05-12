=head1 NAME

OpenFrame::WebApp::Session - sessions for OpenFrame-WebApp

=head1 SYNOPSIS

  use OpenFrame::WebApp::Session;

  my $session = new OpenFrame::WebApp::Session()
     ->set($key1, $val1)->set($key2, $val2);

  $val = $session->get( $key );

  my $id = $session->store();

  my $restored = OpenFrame::WebApp::Session->fetch( $id );

=cut

package OpenFrame::WebApp::Session;

use strict;
use warnings::register;

use Error;
use Digest::MD5 qw( md5_hex );
use Time::ParseDate;
use OpenFrame::WebApp::Error::Abstract;

our $VERSION = (split(/ /, '$Revision: 1.7 $'))[1];

use base qw( OpenFrame::Object );

our $TYPES = {
	      file_cache => 'OpenFrame::WebApp::Session::FileCache',
	      mem_cache  => 'OpenFrame::WebApp::Session::MemCache',
	     };

sub types {
    my $self = shift;
    if (@_) {
	$TYPES = shift;
	return $self;
    } else {
	return $TYPES;
    }
}

sub init {
    my $self = shift;
    $self->id( $self->generate_id );
}

sub id {
    my $self = shift;
    if (@_) {
	$self->{session_id} = shift;
	return $self;
    } else {
	return $self->{session_id};
    }
}

sub expiry {
    my $self = shift;
    if (@_) {
	$self->{expiry_period} = shift;
	return $self;
    } else {
	return $self->{expiry_period};
    }
}

sub get_expiry_seconds {
    my $self = shift;

    # using NOW => 0 causes parsedate() to uses the current time
    my ($time, $err) = parsedate($self->expiry, NOW => 1);

    if ($err) {
        $self->error( "got [$err] parsing expiry time: " . $self->expiry );
        return;
    }

    return ($time-1);
}

sub get {
    my $self = shift;
    my $key  = shift;
    return $self->{$key};
}

sub set {
    my $self      = shift;
    my $key       = shift;
    $self->{$key} = shift;
    return $self;
}

sub generate_id {
    my $self = shift;
    substr( md5_hex( time() . md5_hex(time(). {}. rand(). $$) ), 0, 32 );
}

sub store {
    my $self = shift;
    throw OpenFrame::WebApp::Error::Abstract( class => ref($self) );
}

sub fetch {
    my $class = shift;
    $class    = ref($class) || $class;
    throw OpenFrame::WebApp::Error::Abstract( class => $class );
}

sub remove {
    my $class = shift;
    $class    = ref($class) || $class;
    throw OpenFrame::WebApp::Error::Abstract( class => $class );
}


1;

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Session> class is an abstract wrapper around session
storing classes like C<Cache::FileCache>, C<CGI::Session>, C<Apache::Session>,
etc.

In WebApp, sessions are a storable hash with a session id, and an expiry
period.

Just incase something like Pixie is used to store the sessions, you should
always use the set/get methods to retrieve keys from the hash.

This class was meant to be used with C<OpenFrame::WebApp::Session::Factory>.

=head1 METHODS

=over 4

=item types

set/get the hash of $session_types => $class_names known to this class.

=item $session->id

set/get the session id (stored as 'session_id', FYI).

=item $session->expiry

set/get the expiry period (stored as 'expiry_period', FYI).  This should be
a string compatible with C<Time::ParseDate>.

=item $time = $session->get_expiry_seconds

parses the expiry period with C<Time::ParseDate>, and returns the result in
seconds.

Note: C<$time == undef> implies no expiry time, whereas C<$time <= 0> implies
expires immediately.

=item $session->set( $key, $val )

associates $key with $val, and returns this object.

=item $val = $session->get( $key )

returns value associated with $key.

=item $id = $session->store

abstract method, saves the session to disk and returns the session id.

=item $session = $class->fetch( $id )

abstract method, returns the session with the given $id or undef if not found
or expired.

=item $session->remove( [ $id ] )

abstract method, removes this object from the store, and returns this object.
if called as a class method, $id is expected.

=item $id = $session->generate_id

internal method to generate a new session id.

=back

=head1 SUB-CLASSING

Read through the source of this package and the known sub-classes first.
The minumum you need to do is this:

  use base qw( OpenFrame::WebApp::Session );

  OpenFrame::WebApp::Session->types->{my_type} = __PACKAGE__;

  sub store {
      ...
      return $id;
  }

  sub fetch {
      ...
      return new Some::Session();
  }

  sub remove {
      ...
      return $self;
  }

You must register your session type if you want to use the Session::Factory.

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

Based on C<OpenFrame::AppKit::Session> by James A. Duncan

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<Time::ParseDate>,
L<OpenFrame::WebApp::Sesssion::Factory>,
L<OpenFrame::WebApp::Sesssion::FileCache>,
L<OpenFrame::WebApp::Segment::Sesssion::Loader>

Similar modules:

L<OpenFrame::AppKit::Session>,
L<CGI::Session>,
L<Apache::Session>

=cut
