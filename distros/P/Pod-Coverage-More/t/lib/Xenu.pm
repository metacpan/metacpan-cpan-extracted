package Xenu;

use 5.036;
use warnings FATAL => q{all};

=head1 DESCRIPTION

Module for testing out Pod::Coverage::More

=head1 FUNCTIONS

=head2 test_signature(dog,cat)

Test that names in sigs under strategy 1 are successfully found.

=over 4

=item dog - string: name of dog

=item cat - integer: number of cats needed to screw in lightbulb

=back

=head2 test_case_insensitivity_sigs(DOG,CAT,GOAT,pig,llama,alpaca,chicken,rabbit,snake,horse,farmer)

Test that names in signatures are lc'd, and that the types are correct using method 1.

=over 4

=item DOG - SCALAR

=item CAT - SCALARREF

=item GOAT - ARRAYREF

=item PIG - hashref

=item llama - coderef

=item alpaca - typeglobref

=item chicken - INTEGER

=item rabbit - BOOLEAN

=item snake - FLOAT

=item horse - OBJECT

=item farmer - STRING

=back

=head2 test_array_sigs1(input)

=over 4

=item INPUT (array) - list it out

=back

=head2 test_hash_sigs1(input)

=over 4

=item INPUT (HASH) - get baked

=back

=head2 test_mixed_kind_sigs(count,stuff,items)

Test that each arg is checked against its own type, whatever order the types come in.

=over 4

=item count - INTEGER

=item stuff - MIXED

=item items - ARRAY

=back

=head2 test_scalar_sigs($dog,\$human,\@cat,\%cow,\&chupacabra,\*xenomorph)

=head2 test_array_sigs(@input)

=head2 test_hash_sigs(%input)

Test that the names in signatures are correctly searched for, and that the types are correct using method 2.

=cut

sub test_signature {
    my ( $dog, $cat ) = @_;
    return;
}

# One parameter per sigil that the POD can name.
sub test_scalar_sigs {    ## no critic (Subroutines::ProhibitManyArgs)
    my ( $dog, $human, $cat, $cow, $chupacabra, $xenomorph ) = @_;
    return;
}

sub test_array_sigs {
    my @input = @_;
    return;
}

sub test_hash_sigs {
    my %input = shift;
    return;
}

#Functions can't be passed directly to functions
#Neither can typeglobs.

# One parameter per type that the POD can name.
sub test_case_insensitivity_sigs {    ## no critic (Subroutines::ProhibitManyArgs)
    my ( $dog, $cat, $goat, $pig, $llama, $alpaca, $chicken, $rabbit, $snake, $horse, $farmer ) = @_;
    return;
}

sub test_array_sigs1 {
    my @input = @_;
    return;
}

sub test_hash_sigs1 {
    my %input = @_;
    return;
}

sub test_mixed_kind_sigs {
    my ( $count, $stuff, @items ) = @_;
    return;
}

1;
