# $Id$
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More (tests => 64);
use File::Temp;

BEGIN
{
    use_ok("Senna");
    use_ok("Senna::Constants", ":all");
}

my $temp = File::Temp->new(UNLINK => 1);

my $index = Senna::Index->create(
    path => $temp->filename,
    key_size => SEN_VARCHAR_KEY,
);

for (my $i = 0; $i < 10; $i++) {
    my $rc = $index->insert(key => "key_$i", value => "日本語文章 その $i");
    is($rc, SEN_RC_SUCCESS, "Insert $i returned $rc");
}

my $records = $index->select(query => "日本語");
is($records->nhits, 10, "Should be 10 hits. Got " . $records->nhits);
my $count = 0;
while (my $r = $records->next) {
    ok($r->key, "key ok");
    ok($r->score, "score ok");
    is($r->pos, 0, "pos == 0");
    is($r->section, 0, "secion == 0");
    ok($r->n_subrecs, "n_subrecs ok");
    $count++;
}
is($count, 10, "Should actually be 10 hits. Got $count");
