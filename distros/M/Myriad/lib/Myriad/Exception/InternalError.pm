package Myriad::Exception::InternalError;

use strict;
use warnings;

our $VERSION = '0.004'; # VERSION
our $AUTHORITY = 'cpan:DERIV'; # AUTHORITY

no indirect qw(fatal);

use utf8;

=encoding utf8

=head1 NAME

Myriad::Exception::InternalError - common exception when the error is not relevant to the client.

=head1 DESCRIPTION

See L<Myriad::Exception> for the rôle that defines the exception API.

=cut

use base qw(Myriad::Exception::Base);

use Role::Tiny::With;

with 'Myriad::Exception';

sub category { 'internal' }
sub message { shift->{message} //= 'Internal error' }

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>.

See L<Myriad/CONTRIBUTORS> for full details.

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.

