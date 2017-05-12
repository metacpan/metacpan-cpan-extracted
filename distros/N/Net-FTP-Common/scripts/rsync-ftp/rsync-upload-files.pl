use AppConfig qw(:argcount);
use Data::Dumper;
use File::Basename;
use Getopt::Long;
use Net::FTP::Common;
use strict;


my ($overwrite);
GetOptions('overwrite=i' => \$overwrite) or die;
defined ($overwrite) or die "must set overwrite to 1 or 0";





my $lockfile = '/tmp/net-ftp-rsync-upload-files.lck';
my $wanted = 'files-wanted.done';
my $upload_log = 'rsync-upload-files.dat';

sub cleanup {
    warn "closing dup handle";
    close(Net::FTP::Common::DUP);
    unlink $lockfile;
    1;
}

sub unwanted {
    # also do modtime stuff!

    my ($ez, $local_file, $local_dir, $remote_dir) = @_;

    # looks funny (RemoteFile => $local_file) but it's right!
    warn "if ($ez->exists(RemoteFile => $local_file, RemoteDir => $remote_dir)) {";
    if ($ez->exists(RemoteFile => $local_file, RemoteDir => $remote_dir)) {
      warn "$local_file already there in $remote_dir... skipping";
      return 1
    }

    return 0;
}

sub remotedir {
    my $dir = shift;
    $dir =~ s{Users/metaperl}{home/metaperl/backup};
    $dir

}

-e $lockfile and die "$lockfile must be removed before running script";

# 
# get connection info
#

my $config = AppConfig->new( {CASE => 1} ) ;
my $site   = 'urth_';

$config->define("$site$_", { ARGCOUNT => ARGCOUNT_ONE  } ) 
    for qw(User Pass Host RemoteDir Type);

$config->file($ENV{NET_FTP_BACKUP});

my %urth = $config->varlist("^$site", 1);

warn Data::Dumper->Dump([\%urth],[qw(urth)]);

#
# setup Net::FTP::Common object
#
our %netftp_cfg = (Debug => 1, Timeout => 120);
my $ez = Net::FTP::Common->new({ %urth, STDERR => $lockfile }, %netftp_cfg);

open W, $wanted or die "couldn't open $wanted: $!";
open U, ">$upload_log" or die "couldn't open $upload_log: $!";

our %mkdir;
while (<W>) {

    chomp;
    my $lf = $_;

    warn $lf;

    my ($filename, $ld, undef) = fileparse($lf);
    my $rd = remotedir $ld;

    next if unwanted($ez, $filename, $ld, $rd);

    warn "ld: $ld lf: $lf rd: $rd";

    {
      last if $mkdir{$rd};
      $ez->mkdir(RemoteDir => $rd, Recurse => 1);
      $mkdir{$rd}++;
    }
    

    warn "ez->send(LocalFile => $filename, LocalDir => $ld)";
    $ez->send(LocalFile => $filename, LocalDir => $ld);
    print U "$ld\t$filename\n";
}


