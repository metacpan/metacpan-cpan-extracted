use Test::Most;

my $class;
BEGIN {
    $class = 'Mojo::UserAgent::Mockable';
    use_ok($class);
}

my $ua = new_ok($class);
isa_ok($ua, 'Mojo::UserAgent');
done_testing;
