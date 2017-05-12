package DataSplitHashTest;

use strict;
use warnings;

use Test::More ();

use parent 'Test::Data::Split::Backend::Hash';

my %hash =
(
    a => { a => 1, b => 1, result => 2, },
    b => { a => 20, b => 4, result => 24,},
    c => { a => 0, b => 0, result => 0,},
    d => { a => 10, b => 5, result => 15, },
    'e100_99' => { a => 100, b => 9, result => 109, },
);

sub get_hash
{
    return \%hash;
}

sub run_id
{
    my ($self, $id) = @_;

    my $data = $self->lookup_data($id);

    Test::More::is ($data->{a} + $data->{b}, $data->{result}, "Testing $id.");
}

1;

