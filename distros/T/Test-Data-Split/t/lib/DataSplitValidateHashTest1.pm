package DataSplitValidateHashTest1;

use strict;
use warnings;

use Test::More ();

use parent 'Test::Data::Split::Backend::ValidateHash';

my %hash = ();

sub get_hash
{
    return \%hash;
}

sub run_id
{
    my ( $self, $id ) = @_;

    my $data = $self->lookup_data($id);

    Test::More::is( $data->{a} + $data->{b}, $data->{result}, "Testing $id." );
}

sub validate_and_transform
{
    my ( $self, $args ) = @_;

    return 'prefix_' . $args->{data};
}

__PACKAGE__->populate(
    [
        test_abc => "FooBar",
        test_foo => "JustAValue",
    ]
);
1;

