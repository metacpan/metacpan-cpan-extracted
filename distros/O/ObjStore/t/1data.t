#-*-perl-*-
use Test 1.03;
BEGIN { plan tests => 43 }

use strict;
use ObjStore ':ALL';
use lib './t';
use test;

&open_db;
begin 'update', sub {
    my $john = $db->root('John');
    die 'no db' if !$john;
    my $fatty = $john->{'fatty'} ||= new ObjStore::AV($db, 100);

    my $ok=1;
    for my $x (0..90) {
	$fatty->[$x] = $x + 32760;
	$ok &&= $fatty->[$x] == $x + 32760;
    }
    ok($ok);

    $fatty->[0] = undef;
    ok(!defined $fatty->[0]);
    $fatty->[0] = 0;
    ok($fatty->[0] == 0);
    $fatty->[0] = 70000;
    ok($fatty->[0] == 70000);
    $fatty->[0] = 1.5;
    ok($fatty->[0] == 1.5);
    $fatty->[0] = 'Welcome!'x4097;  #will be truncated
    ok $fatty->[0], '/^Welcome/';

    my $expect = '';
    $fatty->[0] = '';
    for ('a'..'q') { $fatty->[0] .= $_; $expect .= $_; ok($fatty->[0],$expect) }
    for ('a'..'q') { chop $fatty->[0]; chop $expect; ok($fatty->[0],$expect) }

    ok defined $fatty->[0] && length $fatty->[0] == 0, 1;
    $fatty->[0] = undef;
    ok(!defined $fatty->[0]);
};
die if $@;
