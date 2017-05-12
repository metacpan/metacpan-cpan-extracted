use strict;
use warnings;
use Test::More;
use File::Spec;
use Net::Azure::EventHubs;
use utf8;

my $test_config_file = File::Spec->catfile(qw/t sas.conf/);
my $config;

if (-e $test_config_file) {
    open my $fh, '<', $test_config_file or die $!;
    my $data = do {local $/; <$fh>};
    close $fh;
    $config = eval($data);
}

if (!$config) {
    plan skip_all => "$test_config_file is not exists or invalid.";
}

my $hub = Net::Azure::EventHubs->new(connection_string => $config->{connection_string});

my $req = $hub->message({Location => '六本木', Temperture => 14});
ok $req->do;

done_testing;