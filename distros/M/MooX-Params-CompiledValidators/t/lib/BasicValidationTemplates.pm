package BasicValidationTemplates;
use Moo::Role;

use Types::Standard qw( StrMatch );

sub ValidationTemplates {
    my $self = shift;
    return {
        customer => { type => StrMatch[ qr{^ .+ $}x ] },
    }
}

use namespace::autoclean;
1;

=head1 NAME

BasicValidationTemplates - Some basic validations with Types::Standard

=head1 DESCRIPTION

Although L<Params::ValidationCompiler> supports more than one Type/Content
validation scheme, these examples are all based on L<Types::Standard>.

The set-up with a single C<Role> where one specifies all the parameters used
throughout the entire application, helps one to create a consistent API, where
all validations are consistent.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 AUTHOR

(c) MMXXI - Abe Timmerman <abeltje@cpan.org>

=cut
