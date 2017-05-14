# $Id: /mirror/Senna-Perl/t/01-sanity.t 2830 2006-08-24T02:53:18.040683Z daisuke  $
#
# Copyright (c) 2006 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Test::More (tests => 10);

BEGIN
{
    use_ok("Senna");
}

{
    # Test API
    my %api = (
        'Senna::Index' => [
            qw(create open close remove rename select update path query_exec) ],
        'Senna::OptArg::Select' => [
            qw(new mode similarity_threshold max_interval weight_vector func func_arg) ],
        'Senna::Query' => [ qw(open rest) ],
        'Senna::Record' => [ qw(new key score) ],
        'Senna::Records' => [
            qw(next find rewind nhits curr_score curr_key close),
            qw( union subtract intersect difference) ],
        'Senna::Snippet' => [ qw(new add_cond exec) ],
        'Senna::Symbol' => [ qw(create open close get at del size key next pocket_set pocket_get prefix_search suffix_search common_prefix_search) ],
        'Senna::Values' => [ qw(new open close add) ],
    );

    foreach my $package (sort keys %api) {
        my $api = $api{$package};
        can_ok($package, @$api);
    }
}

ok(&Senna::Constants::LIBSENNA_VERSION, sprintf("libsenna version = %s",
    &Senna::Constants::LIBSENNA_VERSION));

1;

__END__
use Test::More (tests => 46);
use File::Spec;

BEGIN
{
    use_ok("Senna::Index", ':all');
}

ok(SEN_INDEX_NORMALIZE);
ok(SEN_INDEX_SPLIT_ALPHA);
ok(SEN_INDEX_SPLIT_DIGIT);
ok(SEN_INDEX_SPLIT_SYMBOL);
ok(SEN_INDEX_NGRAM);

is(SEN_ENC_DEFAULT, 0);
ok(SEN_ENC_NONE);
ok(SEN_ENC_EUCJP);
ok(SEN_ENC_UTF8);
ok(SEN_ENC_SJIS);

is(SEN_VARCHAR_KEY, 0);
ok(SEN_INT_KEY);

my $index_name = 'test.db';
my $path       = File::Spec->catfile('t', $index_name);
my $index      = Senna::Index->create($path);
my $c;

is($index->key_size, 0);
is($index->encoding, SEN_ENC_EUCJP);

$index->put("日本語", "日本語とかで色々書きますと");

ok($c = $index->search("日本語"), "test search");
isa_ok($c, 'Senna::Cursor');
is($c->hits, 1, "should hit only 1 result");
my @list = $c->as_list;
is(scalar(@list), 1, "test as_list");

my $idx = 0;
while (my $r = $c->next) {
    isa_ok($r, 'Senna::Result');
    is($r->key, $list[$idx++]->key,
        "make sure next() returns the same thing as as_list()");
}
ok($c->rewind);

# now check when there are no hits
ok($c = $index->search("これは当たりません"));
isa_ok($c, 'Senna::Cursor');
is($c->hits, 0);
ok(! $c->next);
ok(! $c->rewind);

ok($index->del("日本語", "日本語とかで色々書きますと"));
ok($c = $index->search("日本語"));
isa_ok($c, 'Senna::Cursor');
is($c->hits, 0);

ok($index->remove());

# Now check for integer keys
{
    ok($index = Senna::Index->create($path, SEN_INT_KEY));
    ok($index->put(1, "数値型のキー"));
    ok($c = $index->search("数値型"));
    isa_ok($c, 'Senna::Cursor');
    is($c->hits, 1);
    ok($index->del(1, "数値型のキー"));
    ok($c = $index->search("数値型"));
    is($c->hits, 0);
    
    # Bad key type
    ok(!eval { $index->put("文字列", "数値型のキーのはず") });
    
    ok($index->put(2, "数値型のキー"));
    ok($index->replace(2, "数値型のキー", "数値型のキーを新しくしてみる"));
    ok($c = $index->search("新しくしてみる"));
    is($c->hits, 1);
    
    ok($index->remove());
}
