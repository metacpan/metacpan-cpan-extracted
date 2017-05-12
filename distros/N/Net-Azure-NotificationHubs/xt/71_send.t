use strict;
use warnings;
use Test::More;
use Net::Azure::NotificationHubs;
use utf8;
use Time::Piece;
use Encode;
use File::Spec;

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
};

my $nh = Net::Azure::NotificationHubs->new(%$config);

subtest 'apple' => sub {
    my $req = $nh->send(
        { 
            aps => {
                alert => "Test From Net-Azure-NotificationHubs / テストです",
            },  
        }, 
        format => 'apple', 
    );

    isa_ok $req, 'Net::Azure::NotificationHubs::Request';
    my $res = $req->do;
    isa_ok $res, 'Net::Azure::NotificationHubs::Response';
};

subtest 'gcm' => sub {
    my $req = $nh->send(
        { 
            data => {
                message => "Test From Net-Azure-NotificationHubs / テストです",
            } 
        }, 
        format => 'gcm', 
    );

    isa_ok $req, 'Net::Azure::NotificationHubs::Request';
    my $res = $req->do;
    isa_ok $res, 'Net::Azure::NotificationHubs::Response';
};


done_testing;