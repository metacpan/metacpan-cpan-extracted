use Test::More tests => 5;

use Queue::Base;
use Data::Printer colored => 0;

our @testElements = (
    'aaa', 'bbb',
    {
        'hca' => 'a value',
        'hcb' => 'another value',
    },
    [ qw/lda ldb ldc ldd/, { key => 'value' } ]
);

# simple add/remove (queue size)
my $q = new Queue::Base;
$q->add($_) for @testElements;
is_deeply( $q->{list}, \@testElements );

@copy = $q->copy_elem();
is( scalar @copy, 4 );
is_deeply( \@copy, \@testElements );

$copy[0] = 'new-value';
is( $q->{list}->[0], 'aaa' );

$copy[2]->{hcb} = 'a whole new world';
is(
    $q->{list}->[2]->{hcb},
    'a whole new world',
    'changing deep in the copy will mess with the original'
);
