#!./perl -w

use Test; plan tests => 8;
use ObjStore;
use ObjStore::REP::Splash;

use lib './t';
use test;

&open_db;

ObjStore::_sv_dump_on_error(0); # suppress diagnostic output

begin 'update', sub {
    my $j = $db->root('hv');
    my $rep = 'ObjStore::REP::Splash::ObjAV';
    my $mk = sub { &{$rep.'::new'}('ObjStore::AV', $db->segment_of, 100)};
    my $av = $j->{$rep} = $mk->();
    
    $av->[0] = [1,2,3];
    ok defined $av->[0];
    ok $av->[0][2], 3;

    $av->[1] = { k=>'v' };
    ok defined $av->[1];
    ok $av->[1]{k}, 'v';

    ok !defined $av->[2];

    begin sub { $av->[0] = 'boom'; };
    ok $@, '/Expecting persistent/';

    $av->[0] = undef;
    ok !defined $av->[0];
};
die if $@;
