use Test::More tests => 4;

{
    package Foos;
    use Moos;
    has noos => 42;
}

my $f1 = Foos->new(noos => [2, 2, 2]);
my $f2 = Foos->new({noos => {2 => 2}});

is ref($f1), 'Foos', 'Object constructed with listed args';
is ref($f1->noos), 'ARRAY', 'noos is an ARRAY of two';
is ref($f2), 'Foos', 'Object constructed with hash args';
is ref($f2->noos), 'HASH', 'noos is an HASH of two';
