#!/usr/local/bin/perl

use strict;
use warnings;
use Test::More;

my @implementations = qw(
    DB_File
    SQLite
);

plan tests => (scalar @implementations * 85) + 1;

### vars
my $DB_LOC = 't';
unlink "$DB_LOC/purple.db";
unlink "$DB_LOC/sequence";
unlink "$DB_LOC/sequence.index";
unlink "$DB_LOC/sequence.rindex";
rmdir "$DB_LOC/sequence.lck";

my $url1 = 'http://i.love.purple.net/EugeneKim';
my $url2 = 'http://i.love.purple.net/ChrisDent';

### load module (1)
use_ok('Purple');

foreach my $type (@implementations)
{
    my $p = new Purple(type => $type, store => $DB_LOC);
    ok($p);

    my @nids = (1 .. 9, 'A' .. 'Z', 10, 11);
    my $newNid;
    foreach my $nid (@nids) {
          $newNid = $p->getNext($url1);
          is($newNid, $nid);
    }

    $newNid = $p->getNext($url2);
    is($newNid, '12');

    foreach my $nid (@nids) {
            is($p->getURL($nid), $url1);
    }
    is($p->getURL('12'), $url2);

    $p->updateURL($url2, '3', '6');
    is($p->getURL('3'), $url2);
    is($p->getURL('6'), $url2);

    # XXX sort is a bit ambiguous here but in this case we are numeric
    @nids = sort {$a cmp $b} $p->getNIDs($url2);
    is(scalar @nids, 3);
    is($nids[1], '3');
    is($nids[2], '6');
    is($nids[0], '12');

    $p->deleteNIDs('2', '3');
    ok(!$p->getURL('2'));
    ok(!$p->getURL('3'));
}
