use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More;
use t::Util;

use Path::Maker;

my $tempdir = tempdir;
my $template_dir = catdir($tempdir, "template");
mkdir $template_dir or die;
spew catfile($template_dir, 'file1'), 'hello <?= $_[0] ?>';
my $maker = Path::Maker->new( base_dir => $tempdir, template_dir => $template_dir );
like $maker->render('file1', 'John'), qr/hello John/;
like $maker->render('file2', 'John'), qr/morning John/;

done_testing;

__DATA__

@@ file2
morning <?= $_[0] ?>

