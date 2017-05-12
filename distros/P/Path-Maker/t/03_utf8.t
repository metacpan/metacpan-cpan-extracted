use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More;
use t::Util;

use Path::Maker;

my $tempdir = tempdir;
my $maker = Path::Maker->new( base_dir => $tempdir );
$maker->render_to_file('utf8.mt' => 'utf8.txt', 'かきくけこ');
my $file = catfile($tempdir, 'utf8.txt');
ok -f $file;
my $c = slurp($file);
like $c, qr/あいうえお かきくけこ/;

done_testing;

__DATA__

@@ utf8.mt
あいうえお <?= $_[0] ?>
