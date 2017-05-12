# -*- perl -*-

use Test::More tests => 1;

use strict;
use warnings;
use Cwd;
use File::Copy;
use Data::Dumper;
use TaskForest::Test;

BEGIN {
    use_ok( 'TaskForest'  );
}


my $cwd = getcwd();
my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";
$ENV{TF_ONCE_ONLY} = 1;
my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR});
&TaskForest::Test::cleanup_files($log_dir);


my $bail_out_text = "Subsequent tests will fail for sure.  Make sure user running tests has permissions to create files in cwd ($cwd)\n";
if (! -d $dest_dir) {
    # couldn't create family dir
    BAIL_OUT ("Couldn't create family directory.  $bail_out_text");
}

&TaskForest::Test::cleanup_files($dest_dir);
copy("$src_dir/SIMPLE", $dest_dir);
if (! -e "$src_dir/SIMPLE") {
    BAIL_OUT ("Couldn't copy family file into family directory.  $bail_out_text");
}

if (open (OUT, "> $log_dir/SIMPLE.J1.0")) {
    print OUT "0\n";
    close OUT;
}
else { 
    BAIL_OUT ("Couldn't create log file $log_dir/SIMPLE.J1.0.  $bail_out_text");
}


if (open (OUT, "$log_dir/SIMPLE.J1.0")) {
    $_ = <OUT>;
    chop;
    if ($_ ne "0") {
        BAIL_OUT ("Couldn't read from log file $log_dir/SIMPLE.J1.0 - Got '$_'.  $bail_out_text");
    }
    close OUT;
}
else { 
    BAIL_OUT ("Couldn't open log file $log_dir/SIMPLE.J1.0.  $bail_out_text");
}




&TaskForest::Test::cleanup_files($log_dir);
