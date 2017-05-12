use Test::More;

{
    package Foos;
    use Moos;
    has attr => (clearer => 1, predicate => 1);
}

my $obj = Foos->new(attr => 42);

can_ok($obj, qw/ attr clear_attr has_attr /);

ok $obj->has_attr;
is($obj->attr, 42);

$obj->clear_attr;
ok not $obj->has_attr;
is($obj->attr, undef);

done_testing();
