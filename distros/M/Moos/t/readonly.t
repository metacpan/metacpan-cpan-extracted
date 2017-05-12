use Test::More;

{
    package Foos;
    use Moos;
    has attr1 => (is => 'rw');
    has attr2 => (is => 'ro');
}

my $obj = Foos->new(attr1 => 1, attr2 => 2);

ok eval { $obj->attr1(0); 1 };
ok not eval { $obj->attr2(0); 1 };

done_testing;
