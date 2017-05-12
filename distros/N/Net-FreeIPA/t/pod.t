
use Test::More;
use Test::Pod;

use Net::FreeIPA;

use File::Basename qw(dirname);
my $filename = $INC{"Net/FreeIPA.pm"};
my $dir = dirname($filename);

all_pod_files_ok(all_pod_files($dir));
