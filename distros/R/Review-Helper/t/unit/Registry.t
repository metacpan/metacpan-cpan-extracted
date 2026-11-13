# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use TestRepo qw/make_repo commit_file pinned_refs/;
use Review::Helper::VCS;
use Review::Helper::Registry;
use Review::Helper::Util qw/json_decode/;
use Encode();

my $dir      = make_repo();
my $revision = commit_file($dir, 'One', 'a.txt' => "a\n");
my $repo     = Review::Helper::VCS->detect($dir);
my $reg      = Review::Helper::Registry->new(repo => $repo);

subtest basics => sub {
    is($reg->path,    "$dir/.git/review-helper/registry.json", 'shared registry path');
    is($reg->reviews, {},                                      'no file, no reviews');
    like(dies { Review::Helper::Registry->new }, qr/'repo' is a required attribute/, 'needs repo');
};

subtest register => sub {
    TestRepo::write_file($dir, $_, '') for qw/kept.sqlite closed.sqlite/;
    $reg->register('id-open', "$dir/kept.sqlite");
    $reg->register('id-closed', "$dir/closed.sqlite", 'closed');
    is(
        $reg->reviews,
        {
            'id-open'   => {path => "$dir/kept.sqlite",   state => 'open'},
            'id-closed' => {path => "$dir/closed.sqlite", state => 'closed'},
        },
        'registered',
    );

    open(my $fh, '<', $reg->path) or die $!;
    my $raw = do { local $/; <$fh> };
    is(json_decode($raw)->{reviews}{'id-open'}{state}, 'open', 'stored in the FORMAT layout');

    like(dies { $reg->register('bad/id', 'x') }, qr/Invalid review id 'bad\/id'/, 'unsafe id refused');
    like(dies { $reg->register('*',      'x') }, qr/Invalid review id/,           'glob id refused');
    like(dies { $reg->register('ok', 'x', 'x') }, qr/must be 'open' or 'closed'/, 'bad state');
};

subtest set_state => sub {
    $reg->set_state('id-open', 'closed');
    is($reg->reviews->{'id-open'}{state}, 'closed', 'closed');
    $reg->set_state('id-open', 'open');
    like(dies { $reg->set_state('nope', 'closed') }, qr/Review 'nope' is not registered/, 'unknown id');
};

subtest prune => sub {
    $reg->register('id-gone',  "$dir/gone.sqlite");
    $reg->register('id-other', "$dir/kept.sqlite");
    $repo->pin("refs/review-helper/$_/1",        $revision) for qw/id-open id-closed id-gone id-unregistered/;
    $repo->pin('refs/review-helper/id-gone/2',   $revision);
    $repo->pin('refs/review-helper/id-gone-x/1', $revision);
    $reg->_update(sub ($reviews) {
        $reviews->{'../bad'} = {path => "$dir/kept.sqlite", state => 'closed'};
    });

    my @expect = qw{
        refs/review-helper/id-closed/1
        refs/review-helper/id-gone/1
        refs/review-helper/id-gone/2
    };

    is($reg->prune(dry_run => 1),           \@expect,                                        'dry run lists closed and orphaned refs');
    is(scalar(@{pinned_refs($repo->root)}), 6,                                               'dry run deletes nothing');
    is([sort keys %{$reg->reviews}],        [qw{../bad id-closed id-gone id-open id-other}], 'dry run keeps entries');

    is($reg->prune, \@expect, 'prune removes them');
    is(
        pinned_refs($repo->root),
        [qw{refs/review-helper/id-gone-x/1 refs/review-helper/id-open/1 refs/review-helper/id-unregistered/1}],
        'open and unregistered reviews keep their refs',
    );
    is([sort keys %{$reg->reviews}], [qw/id-open id-other/], 'pruned entries dropped, and one with an invalid id');
    ok(-e "$dir/$_", "$_ untouched") for qw/kept.sqlite closed.sqlite/;

    is($reg->prune, [], 'idempotent');
};

subtest non_ascii_path => sub {
    my $bytes = "$dir/caf\xc3\xa9/r.sqlite";    # the UTF-8 bytes of a path through 'café'
    TestRepo::write_file($dir, "caf\xc3\xa9/r.sqlite", '');
    $reg->register('id-accent', $bytes);
    $repo->pin('refs/review-helper/id-accent/1', $revision);

    open(my $fh, '<:raw', $reg->path) or die $!;
    my $raw = do { local $/; <$fh> };
    like($raw, qr{/caf\xc3\xa9/r\.sqlite"}, 'the file holds the UTF-8 path once');
    unlike($raw, qr{\xc3\x83}, 'not encoded twice');

    is($reg->reviews->{'id-accent'}{path}, $bytes, 'returned as the bytes given');
    ok(!utf8::is_utf8($reg->reviews->{'id-accent'}{path}), 'as a byte string');

    $reg->register('id-chars', Encode::decode('UTF-8', $bytes));
    is($reg->reviews->{'id-chars'}{path}, $bytes, 'a character path is stored the same way');

    $reg->prune;
    is([grep { m{/id-accent/} } @{pinned_refs($repo->root)}], ['refs/review-helper/id-accent/1'], 'prune keeps the open review');
    ok($reg->reviews->{'id-accent'}, 'and its entry');

    like(dies { $reg->register('id-latin1', "$dir/caf\xe9.sqlite") }, qr/must be valid UTF-8/, 'a path that is not UTF-8 is refused');
};

subtest close_review => sub {
    require Review::Helper::DB;
    my $file = "$dir/closing.sqlite";
    my $db   = Review::Helper::DB->create($file, id => 'id-closing', title => 'T');
    $reg->close_review($db, $file);
    is($db->review->{state},                 'closed', 'file marked closed');
    is($reg->reviews->{'id-closing'}{state}, 'closed', 'registry marked closed');
};

subtest not_a_registry => sub {
    my $reg = Review::Helper::Registry->new(repo => Review::Helper::VCS->detect(make_repo()));
    $reg->register('first', 'x');
    for my $content ('{"other":1}', '{"reviews":[]}', '[1]', '{cut off') {
        open(my $fh, '>', $reg->path) or die $!;
        print $fh $content;
        close($fh);
        my $error = "Registry '${\ $reg->path}' is not a review registry: expected a JSON object with a 'reviews' object\n";
        is(dies { $reg->reviews },             $error, "reading '$content' says what is wrong");
        is(dies { $reg->register('ok', 'x') }, $error, 'so does an update');
        open($fh, '<', $reg->path) or die $!;
        is(join('' => <$fh>), $content, 'which leaves the file alone');
    }
};

done_testing;
