use Test::More;

use Net::Docker;
use Data::Dumper;

my $api = Net::Docker->new;
ok($api);

my @lines = $api->pull('busybox');
for (@lines) {
    ok(exists $_->{status});
}

my $version = $api->version;
ok($version->{GoVersion});
ok($version->{Version});

my $info = $api->info;
ok(exists $info->{Containers});
ok(exists $info->{Images});

my $inspect = $api->inspect('busybox');
#is($inspect->{id}, 'a9eb172552348a9a49180694790b33a1097f546456d041b6e82e4d7716ddb721');
ok($inspect->{id});

done_testing();

