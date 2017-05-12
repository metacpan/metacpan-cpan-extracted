# This is -*-perl-*- !
use Test;
BEGIN { plan tests => 19 }

use ObjStore;
use ObjStore::Test qw(testofy_hv);
use lib './t';
use test;

#ObjStore::debug('hash');

&open_db;

require ObjStore::REP::Splash;
require ObjStore::REP::ODI;
begin 'update', sub {
    my $j = $db->root('John');
    $j or die "uninit db";
    
    my $rep = 'ObjStore::REP::Splash::HV';
    my $mk = sub { &{$rep.'::new'}('ObjStore::HV', $j->segment_of, 5) };
    testofy_hv(9, $mk);
    $rep = 'ObjStore::REP::ODI::HV';
    $mk = sub { &{$rep.'::new'}('ObjStore::HV', $j->segment_of, 5) };
    testofy_hv(9, $mk);
};
die if $@;
