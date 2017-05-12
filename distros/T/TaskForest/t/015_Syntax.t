# -*- perl -*-

# 
use Test::More tests => 18;
use strict;
use warnings;
use Data::Dumper;
use Cwd;
use File::Copy;
use TaskForest::Mark;
use TaskForest::Test;

BEGIN {
    use_ok( 'TaskForest::Family',     "Can use Family" );
    use_ok( 'TaskForest::LogDir',     "Can use LogDir" );
    use_ok( 'TaskForest::StringHandle',     "Can use StringHandle" );
    use_ok( 'TaskForest::Rerun',     "Can use Rerun" );
}

my $cwd = getcwd();
&TaskForest::Test::cleanup_files("$cwd/t/families");

my $src_dir = "$cwd/t/family_archive";
my $dest_dir = "$cwd/t/families";
mkdir $dest_dir unless -d $dest_dir;

copy("$src_dir/SYNTAX_1", $dest_dir);
copy("$src_dir/SYNTAX_2", $dest_dir);
copy("$src_dir/SYNTAX_3", $dest_dir);
copy("$src_dir/SYNTAX_4", $dest_dir);
copy("$src_dir/SYNTAX_5", $dest_dir);
copy("$src_dir/SYNTAX_6", $dest_dir);

$ENV{TF_RUN_WRAPPER} = "$cwd/blib/script/run";
$ENV{TF_LOG_DIR} = "$cwd/t/logs";
$ENV{TF_JOB_DIR} = "$cwd/t/jobs";
$ENV{TF_FAMILY_DIR} = "$cwd/t/families";

my $log_dir = &TaskForest::LogDir::getLogDir($ENV{TF_LOG_DIR});
&TaskForest::Test::cleanup_files($log_dir);

my $file_num;


eval {
    my $sf = TaskForest::Family->new(name=>"SYNTAX_1");
};
like($@, qr/No start time specified for Family SYNTAX_1/, "Missing close quote in family header is bad");

my $sf2 = TaskForest::Family->new(name=>"SYNTAX_2");
isa_ok($sf2, 'TaskForest::Family', "Missing comma in family header is ok");

eval {
    my $sf = TaskForest::Family->new(name=>"SYNTAX_3");
};
like($@, qr/No time zone specified for Family SYNTAX_3/, "Missing hash arrwow in family header is bad");

eval {
    my $sf = TaskForest::Family->new(name=>"SYNTAX_4");
};
like($@, qr/Day Tues is not a valid day.  Valid days are: Mon, Tue, Wed, Thu, Fri, Sat and Sun/, "Bad day of week");

eval {
    my $sf = TaskForest::Family->new(name=>"SYNTAX_5");
};
my @lines = split(/[\r\n]/, $@);
like($lines[0], qr/Family 'SYNTAX_5' has unparseable lines:/, "Line 0 is correct");
like($lines[1], qr/J1\( --- This line does not appear to contain a list of jobs that looks like \(for example\) 'J1\(\) J2\(\)'/, "Line 1 is correct");
like($lines[2], qr/J4\) --- This line does not appear to contain a list of jobs that looks like \(for example\) 'J1\(\) J2\(\)'/, "Line 2 is correct");
like($lines[3], qr/J12\(   J13\) --- Bareword "J13" not allowed while "strict subs" in use at \(eval .+\) line .+./, "Line 3 is correct");
like($lines[4], qr/^ *$/, "Line 4 is correct");
like($lines[5], qr/---------- ---------------------------------------------------------------------- --- This line does not appear to contain a list of jobs that looks like \(for example\) 'J1\(\) J2\(\)'/, "Line 5 is correct");
like($lines[6], qr/J5\(\)    J4\(\); --- This line does not appear to contain a list of jobs that looks like \(for example\) 'J1\(\) J2\(\)'/, "Line 6 is correct");
like($lines[7], qr/HELLO WORLD  --- This line does not appear to contain a list of jobs that looks like \(for example\) 'J1\(\) J2\(\)'/, "Line 7 is correct");
like($lines[8], qr/FOO --- This line does not appear to contain a list of jobs that looks like \(for example\) 'J1\(\) J2\(\)'/, "Line 8 is correct");

#like($@, qr/Family 'SYNTAX_5' has unparseable lines:
#    J1\( --- This line does not appear to contain a list of jobs that looks like \(for example\) 'J1\(\) J2\(\)'
#  J4\) --- This line does not appear to contain a list of jobs that looks like \(for example\) 'J1\(\) J2\(\)'
#J12\(   J13\) --- Bareword "J13" not allowed while "strict subs" in use at \(eval .+\) line .+.
#
#---------- ---------------------------------------------------------------------- --- This line does not appear to contain a list of jobs that looks like \(for example\) 'J1\(\) J2\(\)'
#  J5\(\)    J4\(\); --- This line does not appear to contain a list of jobs that looks like \(for example\) 'J1\(\) J2\(\)'
#HELLO WORLD  --- This line does not appear to contain a list of jobs that looks like \(for example\) 'J1\(\) J2\(\)'
#FOO --- This line does not appear to contain a list of jobs that looks like \(for example\) 'J1\(\) J2\(\)'/, "Bad lines in family file");


eval {
    my $sf = TaskForest::Family->new(name=>"SYNTAX_6");
};
is($@, qq^Family 'SYNTAX_6' has unparseable lines:
  J2(start => '00:12', foo=>1)  J3() --- 'foo' is not a recognized attribute\n^, "Bad param");

&TaskForest::Test::cleanup_files($log_dir);
