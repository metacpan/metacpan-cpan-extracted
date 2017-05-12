use strict;
use warnings;
use Algorithm::Diff;
use Cwd;
use Data::Dumper;
use File::Basename;
use File::Find qw(find);
use File::Spec;
use FindBin;
use Test::Exception;

#use Test::Most tests => 2;
use Test::Most;
use YAML qw'freeze thaw LoadFile';

my $case;

use_ok("Parse::Selenese");

dies_ok { Parse::Selenese::parse(); }
"dies trying to parse when given nothing to parse";

my $case_data_dir = "$FindBin::Bin/data";
my @selenese_testcase_data_files;
find sub {
    push @selenese_testcase_data_files, $File::Find::name if /_TestCase\.html$/;
}, $case_data_dir;

lives_ok { $case = Parse::Selenese::parse( $selenese_testcase_data_files[0] ); }
"detect a case";

done_testing();
