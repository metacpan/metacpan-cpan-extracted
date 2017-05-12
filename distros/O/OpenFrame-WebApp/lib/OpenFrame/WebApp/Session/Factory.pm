=head1 NAME

OpenFrame::WebApp::Session::Factory - a factory for various types of session
wrappers.

=head1 SYNOPSIS

  use OpenFrame::WebApp::Session::Factory;

  my $sfactory = new OpenFrame::WebApp::Session::Factory()
    ->type( 'file_cache' )
    ->expiry( $period );  # optional

  my $session = $sfactory->new_session( @args );
  my $session = $sfactory->fetch_session( $id );

=cut

package OpenFrame::WebApp::Session::Factory;

use strict;
use warnings::register;

use OpenFrame::WebApp::Session;

our $VERSION = (split(/ /, '$Revision: 1.4 $'))[1];

use base qw ( OpenFrame::WebApp::Factory );

sub expiry {
    my $self = shift;
    if (@_) {
	$self->{session_expiry} = shift;
	return $self;
    } else {
	return $self->{session_expiry};
    }
}

sub get_types_class {
    my $self = shift;
    return OpenFrame::WebApp::Session->types->{$self->type};
}

sub new_session {
    my $self = shift;
    my $sess = $self->new_object();
    $sess->expiry( $self->expiry ) if ($self->expiry);
    return $sess;
}

sub fetch_session {
    my $self = shift;
    my $id   = shift;
    $self->load_types_class->fetch( $id );
}


1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::Session::Factory> class should be used to create
sessions as needed.  For convenience, it lets you specify a default session
expiry period that is passed to all new sessions.

This class inherits its interface from C<OpenFrame::WebApp::Factory>.
It uses C<OpenFrame::WebApp::Session->types()> to resolve class names.

=head1 ADDITIONAL METHODS

=over 4

=item expiry()

set/get optional session expiry.

=item new_session( ... )

creates a new session wrapper of the appropriate C<session_type> and sets
its expiry() (if set).  passes all arguments to the sessions' constructor.

=item fetch_session( $id )

fetches the session with the given $id.  returns undef if not found.

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::Factory>,
L<OpenFrame::WebApp::Session>

=cut
