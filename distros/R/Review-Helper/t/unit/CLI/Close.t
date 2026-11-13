# Test origin: AI
use v5.36;
use Test2::V0;
use lib 't/lib';

use TestRepo qw/make_repo/;
use TestCLI qw/cli/;
use Review::Helper::DB;
use Review::Helper::VCS;
use Review::Helper::Registry;

my $dir  = make_repo();
my $repo = Review::Helper::VCS->detect($dir);
my $reg  = Review::Helper::Registry->new(repo => $repo);

my $file = $repo->state_dir . '/one.sqlite';
my $id   = Review::Helper::DB->create($file)->review->{id};
$reg->register($id, $file);

my ($exit, $out, $err) = cli($dir, 'close', $file);
is([$exit, $out, $err],                              [0, '', ''],                        'close prints nothing');
is(Review::Helper::DB->open($file)->review->{state}, 'closed',                           'closed in the file');
is($reg->reviews->{$id},                             {path => $file, state => 'closed'}, 'closed in the registry');

my $other = $repo->state_dir . '/two.sqlite';
my $id2   = Review::Helper::DB->create($other)->review->{id};
($exit) = cli($dir, 'close', $other);
is([$exit, $reg->reviews->{$id2}], [0, {path => $other, state => 'closed'}], 'an unregistered review is registered as closed');

(undef, undef, $err) = cli($dir, 'close');
like($err, qr/Usage: review-helper close FILE/, 'needs a file');

(undef, undef, $err) = cli($dir, 'close', "$dir/none.sqlite");
like($err, qr/No such review file/, 'missing file');

done_testing;
