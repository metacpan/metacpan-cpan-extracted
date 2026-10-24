#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use utf8;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest;

use Skilletor::Cache qw( cache_root cache_name git_identity git_cache_dir url_cache_dir );

# Expected values: the reference's own cacheDir(), run once with Node against src/
# (GitSource/UrlSource with cacheRoot "/C"):
#   node -e 'import("./src/sources/git.ts").then(({GitSource}) =>
#     console.log(new GitSource({url, ref, cacheRoot: "/C"})["cacheDir"]()))'
my @git = (
  [ 'https://github.com/Getty/skills', undef,             '/C/ca0b2028c7d6eb0b' ],
  [ 'https://github.com/Getty/skills', 'main',            '/C/d2425b64323b2f4a' ],
  [ 'https://github.com/Getty/skills', 'v1.2.3',          '/C/73732e3e4d71cdc8' ],
  [ 'git@github.com:Getty/karr.git',   '0123abc',         '/C/2e5008ef68b60e12' ],
  [ '/srv/repo with space/"quoted"\\x', 'feature/ü-日本', '/C/31dee47a419984c9' ],
  [ "https://example.com/\x{1F600}",   "\x{1F600}",       '/C/a858f0949aecf8e0' ],
  [ "https://example.com/ctl\x01\x1f\x7f", "x\x{2028}y",  '/C/a8fc0c7c5bed38a3' ],
);
my @url = (
  [ 'https://skills.example.com/skills.tar.gz', '/C/478bfa87787353f4' ],
  [ 'https://example.com/a b/ü.tgz',            '/C/31da688107de3ea6' ],
);

for my $case (@git) {
  my ( $url, $ref, $dir ) = @$case;
  is( git_cache_dir( '/C', $url, $ref ), $dir, 'git cache of '.$url.' @ '.( $ref // 'HEAD' ) );
}
for my $case (@url) {
  my ( $url, $dir ) = @$case;
  is( url_cache_dir( '/C', $url ), $dir, 'url cache of '.$url );
}

is( git_identity( 'https://x/y', undef ), 'https://x/y', 'unpinned: the URL alone' );
is( git_identity( 'https://x/y', '' ), 'https://x/y', 'an empty ref is no ref' );
is( git_identity( 'https://x/y', 'main' ), '["https://x/y","main"]', 'pinned: JSON pair' );
is( cache_root('/home/u'), '/home/u/.claude/skilletor/cache', 'cache root under the home' );
is( git_cache_dir( '/C//', 'https://github.com/Getty/skills' ), '/C/ca0b2028c7d6eb0b', 'root joined as path.join does' );
like( cache_name('x'), qr/\A[0-9a-f]{16}\z/, '16 hex digits' );

done_testing;
