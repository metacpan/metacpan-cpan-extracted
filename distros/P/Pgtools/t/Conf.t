use strict;
use warnings;

use Test::More;
use Data::Dumper;

use_ok('Pgtools::Conf');
use Pgtools::Conf;

my $dummy = {
    "version" => "0.0.1",
    "items" => {
        "test1" => -1,
        "test2" => 2,
        "test3" => "3",
    }
};
my $c = Pgtools::Conf->new($dummy);

ok $c;
isa_ok($c, "Pgtools::Conf");
is($c->{version}, "0.0.1");
is($c->{items}->{test1}, -1);
is($c->{items}->{test2}, 2);
is_deeply($c->{items}, {
    "test1" => -1,
    "test2" => 2,
    "test3" => "3",
});

done_testing;

