use strict;
use warnings FATAL => "all";
use Test::More;
use t::Util;

use Path::Maker;

my $tempdir = tempdir;
chdir $tempdir;

my $maker = Path::Maker->new(template_header => "? my \$arg = shift;\n");
$maker->render_to_file('with-header' => 'hello.txt', {arg1 => 1, arg2 => 2});
my $file = 'hello.txt';
ok -f $file;
like slurp($file), qr/12/;
chdir "/";

done_testing;

__DATA__

@@ with-header
<?= $arg->{arg1} ?><?= $arg->{arg2} ?>
