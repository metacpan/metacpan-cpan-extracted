#!perl -T

use warnings;
use strict;

use Test::Config::System tests => 8;
use File::Temp qw/ tempfile tempdir /;

my $dir = tempdir();
my ($fh, $filename) = tempfile();

check_dir($dir, { '-mode' => 0700 }, 'check_dir(pass)');
check_dir($dir, { '-mode' => 1234 }, 'check_dir(badmode,fail,inverted)', 1);
check_dir('aoeu', { '-mode' => 0777 }, 'check_dir(fail,inverted)', 1);
check_file($filename, { '-mode' => 0600}, 'check_file(pass)');
check_file('asdf', { '-mode' => 0111 }, 'check_file(fail,inverted)', 1);
check_file($filename, { '-mode' => 1234}, 'check_file(badmode,fail,inverted)', 1);


### check_file and check_dir use the same internal sub, which this is testing.
check_file($filename, { '-mode' => 0600, '-aoeu' => 'fnord' },
    '_pathp(pass,bogus attr)');
check_dir($dir,
    'not a hashref. The test still passes (_pathp will ignore it)',
    '_pathp(pass,no hashref)');

### Difficult to test anything else in at least a semi-portable manner..
