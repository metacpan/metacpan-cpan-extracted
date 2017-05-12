
use strict;
use warnings;

use Test::More tests => 2;
use File::Temp qw( tempdir );
use FindBin;

use Path::IsDev is_dev => { set => 'Basic' };

my $dir = tempdir();

ok( !is_dev($dir),               'empty dirs should not be dev dirs' );
ok( is_dev("$FindBin::Bin/../"), 'dirname(dirname(__FILE__)) is dev' );
