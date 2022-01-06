use strict;
use warnings;
use Test2::V0;
use lib "t/lib";
use Util;

use utf8;

use Module::cpmfile;
use YAML::PP ();

my $yaml = YAML::PP->new;

my $cpmfile = Module::cpmfile->load("t/data/cpm.yml");
my $string = $cpmfile->to_string;
like $string, qr/description: ディスクリプション/;
my $v1 = $yaml->load_string($string);

my $v2 = $yaml->load_file("t/data/cpm.yml");

is $v1, $v2;

done_testing;
