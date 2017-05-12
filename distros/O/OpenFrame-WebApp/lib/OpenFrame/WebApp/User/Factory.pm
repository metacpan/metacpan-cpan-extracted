=head1 NAME

OpenFrame::WebApp::User::Factory - a factory for creating users

=head1 SYNOPSIS

  use OpenFrame::WebApp::User::Factory;

  my $ufactory = new OpenFrame::WebApp::User::Factory()->type('webapp');
  my $user     = $ufactory->new_user( @args );

=cut

package OpenFrame::WebApp::User::Factory;

use strict;
use warnings::register;

use OpenFrame::WebApp::User;

our $VERSION = (split(/ /, '$Revision: 1.3 $'))[1];

use base qw ( OpenFrame::WebApp::Factory );

sub get_types_class {
    my $self = shift;
    return OpenFrame::WebApp::User->types->{$self->type};
}

sub new_user {
    my $self = shift;
    return $self->new_object( @_ );
}

1;

__END__

=head1 DESCRIPTION

The C<OpenFrame::WebApp::User::Factory> class should be used to create
user objects as needed.

This class inherits its interface from C<OpenFrame::WebApp::Factory>.
It uses C<OpenFrame::WebApp::User->types()> to resolve class names.

=head1 ADDITIONAL METHODS

=over 4

=item $new_user = $obj->new_user( ... )

creates a new user of the appropriate type.  passes all arguments on to the
users constructor.

=back

=head1 AUTHOR

Steve Purkis <spurkis@epn.nu>

=head1 COPYRIGHT

Copyright (c) 2003 Steve Purkis.  All rights reserved.
Released under the same license as Perl itself.

=head1 SEE ALSO

L<OpenFrame::WebApp::Factory>,
L<OpenFrame::WebApp::User>

=cut
