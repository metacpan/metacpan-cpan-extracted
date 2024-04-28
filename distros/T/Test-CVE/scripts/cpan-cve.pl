#!/usr/bin/env perl

use 5.014002;
use warnings;

our $VERSION = "0.10 - 20240428";
our $CMD = $0 =~ s{.*/}{}r;

sub usage {
    my $err = shift and select STDERR;
    say "usage: $CMD [options] [file | module | dir ...]";
    say "    -d    --deps         Report on current deps too";
    say "    -m    --minimum      Report based on minimum (default recommended)";
    say "    -j F  --json=F       Use downloaded JSON instead of fetching";
    say "    -p    --perl         Report CVE's on required perl (default OFF)";
    say "    -c    --corelist     Replace 0 versions w*ith CORE version";
    say "    -v[#] --verbose[=#]  Set verbosity level";
    say "    -J F  --json-out=F   Output in JSON file F (- = STDOUT)";
    say "";
    say "For CVE's in the perl core, please use --perl and/or CPAN::Audit";
    say "Documentation should still be written";
    exit $err;
    } # usage

use Test::CVE;
use JSON::MaybeXS;
use Module::CoreList;
use Cwd          qw( getcwd abs_path);
use Getopt::Long qw(:config bundling noignorecase);
GetOptions (
    "help|?"		=> sub { usage (0); },
    "V|version"		=> sub { say "$CMD [$VERSION]"; exit 0; },

    "d|deps!"		=> \ my $opt_d,
    "m|minimum!"	=> \ my $opt_m,
    "j|json=s"		=> \ my $opt_j,
    "J|json-out=s"	=> \ my $opt_J,

    "p|perl!"		=> \ my $opt_p,
    "c|cl|corelist!"	=> \ my $opt_c,

    "v|verbose:1"	=> \(my $opt_v = 0),
    ) or usage (1);

@ARGV or push @ARGV => ".";
my $tld = abs_path (getcwd);
my %rpt;
foreach my $module (@ARGV) {
    my $cve = Test::CVE->new (
	deps    => $opt_d,
	perl    => $opt_p // 0,
	core    => $opt_c // 0,
	minimum => $opt_m,
	cpansa  => $opt_j,
	verbose => $opt_v,
	);

    # NEW! https://fastapi.metacpan.org/cve/CPANSA-YAML-LibYAML-2012-1152
    #      https://fastapi.metacpan.org/cve/release/YAML-1.20_001

    chdir $tld;
    if (-d $module) {
	chdir $module;
	}
    elsif (-s $module and open my $fh, "<", $module) {
	# prevent reading Makefile and cpanfile, but extract "use" and "require"
	my %mod;
	my $pl = do { local $/; <$fh> } =~ s/^\s*#.*;//gmr;
	my $v  = $pl =~ m/\$\s*VERSION\s*=\s*["']?(\S+?)['"]?\s*;/ ? $1 : "-";

	$cve->set_meta ($module, $v);
	while ($pl =~ m{\b (?: use | require ) [\s\r\n]+
			   ([\w:]+)
			   ([\s\r\n]+[.\w]+)?
			   (?: [\s\r\n]+ (?: "[^;]+" | '[^;]+' | qw[^;]+ ))?
			   [\s\r\n]*;
			   }gx) {
	    my ($m, $v) = ($1, $2 // 0);
	    $m =~ m/^(?: v?5 | warnings | strict )$/x and next;
	    $cve->want ($m, $v);
	    }
	}
    else {
	usage (1);
	}

    unless ($opt_J) {
	$cve->test->report;
	next;
	}

    my @err;
    local $SIG{__WARN__} = sub {
	push @err => map {
	    s/[\s\r\n]+\z//r =~ s{[\s\r\n]+at\s+\S+\s+line\s+[0-9]+}{}r
	    } @_;
	};
    say $module;
    eval {   $rpt{$module} = [ $cve->test->cve ]; };
    @err and $rpt{$module} = [{ error => [ @err ] }];
    }

chdir $tld;
if ($opt_J) {
    if ($opt_J eq "-") {
	say     encode_json (\%rpt);
	}
    else {
	open my $fh, ">:encoding(utf-8)", $opt_J or die "$opt_J: $!\n";
	say $fh encode_json (\%rpt);
	close $fh;
	}
    }
