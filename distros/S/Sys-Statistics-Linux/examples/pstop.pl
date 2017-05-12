#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Sys::Statistics::Linux;

my $o_file  = ();
my $o_help  = ();
my %pstop   = ();
my $fh      = ();
my $format  = "%6s %-8s %5s %5s %5s %1s %4s %5s %12s %s";
my $time    = qx{date};

GetOptions(
    "f|file=s" => \$o_file,
    "h|help"   => \$o_help,
);

if ($o_help) {
    print "\nUsage: $0 [ OPTIONS ]\n\n";
    print "-f, --file <file>\n";
    print "    Print the output to a file instead to STDOUT.\n";
    print "-h, --help\n";
    print "    Print the help and exit.\n\n";
    exit 0;
}

my $sys  = Sys::Statistics::Linux->new(
    memstats  => 1,
    processes => {
        init => 1,
        pages_to_bytes => 4,
    },
);

my $stat = $sys->get(1);

%pstop = map { $_ => 1 }
    $stat->pstop(ttime => 10),
    $stat->pstop(resident => 10),
    $stat->psfind({state => qr/[DR]/});

if ($o_file) {
    open $fh, ">>", $o_file
        or die "unable to open '$o_file'";
} else {
    $fh = \*STDOUT;
}

print $fh "$time\n";
printf $fh "$format\n",
    qw(PID USER VIRT RES SHR S %CPU %MEM TIME COMMAND);

foreach my $pid (keys %pstop) {
    my $vsize = $stat->processes($pid => "vsize");
    my $res   = $stat->processes($pid => "resident");
    my $share = $stat->processes($pid => "share");
    my $owner = substr($stat->processes($pid => "owner"), 0, 8);
    my $size  = sprintf("%.1f", $stat->processes($pid => "resident") * 100 / $stat->memstats->{memtotal});

    foreach my $s ($vsize) {
        if ($s > 9999) {
            $s = int($s / 1024 / 1024) . "M";
        }
    }

    foreach my $s ($res, $share) {
        if ($s > 9999) {
            $s = int($s / 1024) . "M";
        }
    }

    printf $fh "$format\n",
        $pid, $owner, $vsize, $res, $share,
        $stat->processes($pid => "state"),
        int($stat->processes($pid => "ttime")),
        $size, $stat->processes($pid => "actime"),
        $stat->processes($pid => "cmd");
}

print $fh "\n";

