#!/pro/bin/perl

use 5.014002;
use warnings;

our $VERSION = "0.04 - 20240408";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD [-f] [-d] CVE ...";
    say "    -f   --full     Return full report (default: summary)";
    say "    -d   --dump     Full data dump of JSON structure";
    say "                    Will use Data::Peek if available,";
    say "                    otherwise Data::Dumper";
    say "    -j   --json     Dump as json";
    say "    -J   --json-pp  Dump as json (formatted)";
    say "    -Q   --json-jq  Dump as json (formatted by jq)";
    say "    -c   --csv      Dump as CSV (NYI)";
    exit $err;
    } # usage

use Net::CVE;
use Data::Peek;
use Data::Dumper;
use JSON::MaybeXS;
use List::Util   qw( first          );
use Getopt::Long qw(:config bundling);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "f|full!"		=> \ my $opt_f,
    "d|dump!"		=> \ my $opt_d,
    "j|json!"		=> \ my $opt_j,
    "J|json-pp!"	=> \ my $opt_J,
    "Q|json-jq|jq!"	=> \ my $opt_Q,

    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or usage (1);

my $cr = Net::CVE->new;

my %cve;
first { $_ !~ m/^(?:cve-)?[0-9]{4}-[0-9]+$/i } @ARGV and
    die "Not all CVE's are of acceptable formate CVE-9999-99999\n";

$cve{$_} = $opt_f ? $cr->data ($_) : $cr->summary ($_) for @ARGV;

if ($opt_d) {
    eval "local \$_; require Data::Peek;";
    if ($@) {
	print STDERR Data::Dumper->Dump (\%cve);
	}
    else {
	print STDERR Data::Peek::DDumper (\%cve);
	}
    exit 0;
    }

if ($opt_j || $opt_J || $opt_Q) {
    $opt_Q and open STDOUT, "|-", "jq";
    if ($opt_J) {
	print JSON::MaybeXS->new (utf8 => 1, pretty => 1)->encode (\%cve);
	}
    else {
	say encode_json (\%cve);
	}
    exit 0;
    }

my @cve = sort keys %cve;
foreach my $cve (@cve) {
    my $r = $cve{$cve};
    if ($opt_f) {
	say $cve;
	say " State           : ", $r->{cveMetadata}{state};
	say " Published       : ", $r->{cveMetadata}{datePublished};
	my $cc = $r->{containers}{cna} or next;
	say " Title           : ", $cc->{title}      // "-none-";
	say " Public          : ", $cc->{datePublic} // "-unknown-";
	if (my $md = $cc->{providerMetadata}) {
	    printf " Provider        : %s:%s\n", $md->{shortName}, $md->{orgId};
	    }
	my $lead = " " x 19;
	foreach my $rd (@{$cc->{descriptions} || []}) {
	    printf "%16s : %s\n", $rd->{lang}, $rd->{value} =~ s/\n\K/$lead/gr;
	    }
	foreach my $rr (@{$cc->{references} || []}) {
	    my $trim = "References";
	    for (grep { length }
		 $rr->{name},
		 (join ", " => @{$rr->{tags} || []}),
		 $rr->{url}) {
		printf " %-15s : %s\n", $trim, $_;
		$trim = "";
		}
	    }
	foreach my $pt (@{$cc->{problemTypes} || []}) {
	    foreach my $ptd (@{$pt->{descriptions} || []}) {
		printf " Problem %7s : %-12s %s\n",
		    $ptd->{lang}, $ptd->{type}, $ptd->{description};
		}
	    }
	foreach my $af (@{$cc->{affected} || []}) {
	    ($af->{vendor}  || "n/a") eq "n/a" &&
	    ($af->{product} || "n/a") eq "n/a" and next;
	    say " Affected        : ", $af->{vendor}, " : ", $af->{product};
	    if (my $p = $af->{platforms}) {
		say "       Platforms : ", join ", " => @$p;
		}
	    foreach my $v (@{$af->{versions} || []}) {
		my ($vs, $vv, $vvt) = delete @{$v}{qw( status version versionType )};
		$vv && $vv eq "n/a" and $vvt ||= "n/a";
		$vs && $vs eq "affected" && $vvt eq "n/a" and next;
		printf "       Versions  : %-12s %s (%s)\n", $vs, $vv, $vvt;
		foreach my $vc (sort keys %$v) {
		    printf "%16s : %12s %s\n", "", $vc, $v->{$vc};
		    }
		}
	    say "       CPE       : ", $_ for @{$af->{cpes} || []};
	    }
	foreach my $m (@{$cc->{metrics} || []}) {
	    say " Metric          : ", $m->{format};
	    if (my $v31 = $m->{cvssV3_1}) {
		printf "  Severity %5s : %3d:%-8s %s\n", $v31->{version},
		    $v31->{baseScore}, $v31->{baseSeverity}, $v31->{vectorString};
		}
	    foreach my $s (@{$m->{scenarios} || []}) {
		printf " Scenario%7s : %s\n", $s->{lang}, $s->{value};
		}
	    }

	next;
	}
    # Print summary
    printf "%-20s %-9s %4s %-25.25s %s\n",
	map { $_ // "" } @{$r}{qw( id severity score problem description )};
    }
