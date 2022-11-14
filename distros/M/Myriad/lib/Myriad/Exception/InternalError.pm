package Myriad::Exception::InternalError;

use Myriad::Exception::Builder;

our $VERSION = '1.001'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

=encoding utf8

=head1 NAME

Myriad::Exception::InternalError - common exception when the error is not relevant to the client.

=head1 DESCRIPTION

See L<Myriad::Exception> for the rôle that defines the exception API.

=cut

declare_exception '' => (
    category => 'internal',
    message  => 'Internal error'
);

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2022. Licensed under the same terms as Perl itself.

