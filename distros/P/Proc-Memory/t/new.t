use Test::More;

BEGIN {
    use_ok 'Proc::Memory';
}

my $proc = Proc::Memory->new($$);

isnt $proc, undef;

done_testing;

