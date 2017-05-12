package Net::FTP::Backup;

our $Time = time;
$Time > 1e5 or die 'your system clock must not be set';

our $Location;

use AppConfig qw(:argcount);
use Data::Dumper;
use Getopt::Long;
use File::Find;
use File::stat;
use Net::FTP::Common;
use strict;

our $last_done;
my ($since_last_run, $blind, $seconds_mtime);

# when file exists server-side, 
# - check date?
# - 

GetOptions('since-last-run' => \$since_last_run, 'blind'  => \$blind, 'seconds-mtime' => \$seconds_mtime) or die;

my $sum = $since_last_run + $blind + $seconds_mtime;
my @option_name = qw(since-last-run blind seconds-mtime);
$sum == 1 or die "exactly one of @option_name must be specified";

my $lockfile = '/tmp/net-ftp-common-rsync-files.lck';

sub cleanup {
    warn "closing dup handle";
    close(Net::FTP::Common::DUP);
    unlink $lockfile;
    1;
}

-e $lockfile and 
    cleanup and die "$lockfile must be removed before running script";

my $config      = AppConfig->new( {CASE => 1} ) ;
my $location    = 'location';
my $install_dir = 'install_dir';



$config->define($location, { ARGCOUNT => ARGCOUNT_LIST });
$config->define($install_dir, { ARGCOUNT => ARGCOUNT_ONE });
$config->file($ENV{NET_FTP_BACKUP});

my $location = $config->get($location);
$install_dir = $config->get($install_dir);

my $done_file = "$install_dir/files-wanted.done";

warn Dumper($location, $install_dir);

if ($since_last_run) {
  my $tmp = stat($done_file);
  $last_done = $tmp->mtime;
  warn "last_done: $last_done";
} 

if ($seconds_mtime) {
   warn "calculating last_done from system time";
  $last_done = time - $seconds_mtime;
}

open RUNLOG, ">$done_file" or 
  die "could not open $done_file: $!";



foreach (@$location) {
  warn "testing $_";
  $Location = $_;
  find(\&wanted, $_);
}

sub unwanted {
    my $file = shift;

    return 1 if $file =~ /.DS_Store/;
    return 1 if $file =~ /.FBC/;
    return 1 if $file =~ /\.mp3$/;

    my $tmp = stat($file);
    my $mtime = $tmp->mtime;

    if ($since_last_run) {

      my $diff = $mtime - $last_done;

      if ($diff > 0) {
	warn "$file\tlast_done - mtime: $diff";
	return 0 
      } else {
	return 1
      }
    }
    return 0
}

sub wanted {

  last unless -f; 

  if ($Location eq '/Users/metaperl') {
    # do not enter subdirs for home dir
    last unless $File::Find::dir eq $Location;
  }

  last if /[\r\n]/s;
    
  my $lf = $_;

  last if unwanted($File::Find::name);

  print RUNLOG "$File::Find::name\n";

}


close(RUNLOG);

