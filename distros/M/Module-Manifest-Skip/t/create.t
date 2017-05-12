use strict;
my $t; use lib ($t = -e 't' ? 't' : 'test');
use TestModuleManifestSkip;

use Test::More tests => 2;

my $dir = "$t/dir1";
my $file = "$dir/MANIFEST.SKIP";

unlink $file;
die if -e $file;
chdir $dir or die;

system("$^X -I$LIB -MModule::Manifest::Skip=create") == 0
    or die;

chdir $HOME or die;

ok -e $file,
    "MANIFEST.SKIP created";

is read_file($file),
    $TEMPLATE,
    'MANIFEST.SKIP is correct';

unlink $file or die;
