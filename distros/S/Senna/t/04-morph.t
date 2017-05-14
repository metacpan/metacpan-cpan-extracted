#!perl
#
# $Id: /mirror/Senna-Perl/t/04-morph.t 2736 2006-08-17T18:40:03.173184Z daisuke  $
#
# Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More (tests => 13);
use File::Temp;

BEGIN
{
    use_ok("Senna::Index");
    use_ok("Senna::Constants", ':all');
}

my $temp = File::Temp->new(UNLINK => 1);
my $index = Senna::Index->create(
    path => $temp->filename,
    key_size => SEN_VARCHAR_KEY,
);
ok($index, 'check index');
is($index->path, $temp->filename, "check path");

my $rc = $index->insert(key => "file1", value => "東京都");
is($rc, SEN_RC_SUCCESS, "insert value returned $rc");
is($index->nrecords_keys, 1, "1 record available");

my $r = $index->select(query => "東京");
ok($r);
isa_ok($r, "Senna::Records");
is($r->nhits, 1);

while (my $result = $r->next) {
    is($result->key, "file1", "check key for \$r");
}

# 形態素解析ではヒットしないはず
$r = $index->select(query => "京都");
ok($r);
isa_ok($r, "Senna::Records");
is($r->nhits, 0);

