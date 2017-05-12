#!perl -T

use lib 'lib';
use strict;
use warnings;
use Test::More tests => 3;

use Monit::HTTP ':constants';

#my $hd = new Monit::HTTP(
#    hostname => 'localhost', 
#    port => 'port',
#    username => 'admin', 
#    password => 'monit', 
#    use_auth => 1);

my $hd = new Monit::HTTP(hostname=>'nonexistenthost');
eval {
    $hd->get_services();
} or do {
    like $@, qr{Bad hostname 'nonexistenthost'};
};

$hd->set_hostname('localhost');
eval {
    $hd->get_services();
} or do {
    print $@;
    like $@, qr{connect: Connection refused};
};

$hd->set_port(14566);
eval {
    $hd->get_services();
} or do {
    print $@;
    like $@, qr{connect: Connection refused};
};


