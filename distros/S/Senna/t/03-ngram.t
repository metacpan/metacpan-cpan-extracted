#!perl
#
# $Id: /mirror/Senna-Perl/t/03-ngram.t 2735 2006-08-17T18:39:40.937191Z daisuke  $
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More (tests => 14);
use File::Temp;

BEGIN
{
    use_ok("Senna");
    use_ok("Senna::Constants", ":all");
}

my $temp = File::Temp->new(UNLINK => 1);

my $index = Senna::Index->create(
    path => $temp->filename,
    flags => SEN_INDEX_NGRAM,
);

ok($index, 'check index');
is($index->path, $temp->filename, "check path");

my $rc = $index->insert(key => "file1", value => "まずは日本語の値");
is($rc, SEN_RC_SUCCESS, "insert value returned $rc");
is($index->nrecords_keys, 1, "1 record available");

my $r = $index->select(query => "日本語");
ok($r);
isa_ok($r, "Senna::Records");
is($r->nhits, 1);

while (my $result = $r->next) {
    is($result->key, "file1", "check key for \$r");
}

$r = $index->select(query => "本語");
ok($r);
isa_ok($r, "Senna::Records");
is($r->nhits, 1);

while (my $result = $r->next) {
    is($result->key, "file1", "check key for \$r");
}


__END__
ok($c, 'search() 1');
is($c->hits, 1, 'hits() 1');

$c = $index->search("本語");
ok($c, 'search() 2');
is($c->hits, 1, 'hits() 2');	# n-gram ならヒットするはず

ok($index->remove(), 'remove()');
