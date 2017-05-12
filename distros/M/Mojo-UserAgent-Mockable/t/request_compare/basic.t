use 5.014;
use Test::Most;

my $class;
BEGIN {
    $class = 'Mojo::UserAgent::Mockable::Request::Compare';
    use_ok $class;
}

new_ok($class);

done_testing;
