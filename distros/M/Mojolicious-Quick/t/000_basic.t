use Test::Most;

my $class;
BEGIN {
    $class = 'Mojolicious::Quick';
    use_ok($class);
}

my $ua = new_ok($class);
done_testing;
