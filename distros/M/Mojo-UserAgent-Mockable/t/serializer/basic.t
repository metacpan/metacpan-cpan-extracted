use 5.014;
use Test::Most;
use Test::Moose;

my $class;
BEGIN {
    $class = 'Mojo::UserAgent::Mockable::Serializer';
    use_ok($class);
}

my $obj = new_ok($class);

for my $method (qw/serialize deserialize store retrieve/) {
    can_ok($obj, $method);
}

done_testing;
