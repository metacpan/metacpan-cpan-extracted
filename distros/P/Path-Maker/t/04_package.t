use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More;
use t::Util;

use t::My;
use Path::Maker;

my $tempdir = tempdir;
my $maker = Path::Maker->new( base_dir => $tempdir, package => 't::My' );
like $maker->render('my1', 'baz'), qr/foo bar baz/;

done_testing;

