#!/pro/bin/perl

use 5.014002;
use warnings;

our $VERSION = "0.01 - 20230522";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD [-f] [-d] CVE ...";
    say "    -f   --full   Return full report (default: summary)";
    say "    -d   --dump   Full data dump of JSON structure";
    exit $err;
    } # usage

use CSV;
use Net::CVE;
use List::Util   qw( first          );
use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "f|full!"		=> \ my $opt_f,
    "d|dump!"		=> \ my $opt_d,

    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or usage (1);

my $cr = Net::CVE->new;

my %cve;
first { $_ !~ m/^(?:cve-)?[0-9]{4}-[0-9]+$/i } @ARGV and
    die "Not all CVE's are of acceptable formate CVE-9999-99999\n";

$cve{$_} = $opt_f ? $cr->data ($_) : $cr->summary ($_) for @ARGV;

if ($opt_d) {
    DDumper \%cve;
    exit 0;
    }

my @cve = sort keys %cve;
foreach my $cve (@cve) {
    my $r = $cve{$cve};
    printf "%-20s %-9s %4s %-25.25s %s\n",
	map { $_ // "" } @{$r}{qw( id severity score problem description )};
    }
