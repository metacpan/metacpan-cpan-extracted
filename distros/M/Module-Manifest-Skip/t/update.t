use strict;
my $t; use lib ($t = -e 't' ? 't' : 'test');
use TestModuleManifestSkip;

use Test::More tests => 1;

my $lib = abs_path 'lib';
my $dir = "$t/dir2";
my $src = "$dir/skip_file";
my $file = "$dir/MANIFEST.SKIP";

unlink $file;
die if -e $file;
copy_file($src, $file);
die unless -e $file;
chdir $dir or die;

system("$^X -I$lib -MModule::Manifest::Skip=create") == 0
    or die;

chdir $HOME or die;

my $prefix = <<'...';
# My stuff
Test1
- Test2
...

is read_file($file),
    "$prefix$TEMPLATE",
    'MANIFEST.SKIP is correct';

unlink $file or die;
