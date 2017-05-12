use Test::More;

{
    package Foos;
    use Moos;
    has attr => (required => 1);
}

ok eval { Foos->new(attr => 42) };
ok not eval { Foos->new(attx => 42) };

done_testing();
