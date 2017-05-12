# -*- perl -*-

# 
use Test::More tests => 3;
use strict;
use warnings;
use Data::Dumper;
use Cwd;

BEGIN {
    use_ok( 'TaskForest::LogDir',     "Can use Logdir" );
}

my $cwd = getcwd();


my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my $YYYYMMDD = sprintf("%4d%02d%02d", $year+1900, $mon+1, $mday);

my $root = "$cwd/t/logs";
my $todays_log_dir = "$root/$YYYYMMDD";
if (-d $todays_log_dir) {
    cleanup($todays_log_dir);
}

my $log_dir = &TaskForest::LogDir::getLogDir($root);

ok(-d $log_dir, 'Log dir is a directory');
is($log_dir, $todays_log_dir,  '  and is correct');

cleanup($todays_log_dir);


sub cleanup {
    my $dir = shift;
	local *DIR;
    
	opendir DIR, $dir or die "opendir $dir: $!";
	my $found = 0;
	while ($_ = readdir DIR) {
        next if /^\.{1,2}$/;
        my $path = "$dir/$_";
		unlink $path if -f $path;
		cleanup($path) if -d $path;
	}
	closedir DIR;
	rmdir $dir or print "error - $!";
}
