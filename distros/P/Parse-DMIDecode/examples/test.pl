#!/usr/bin/perl -w

#BEGIN { chdir '../' if -d '../examples/'; }

use strict;
use lib qw(./lib ../lib);
use Getopt::Std qw(getopts);
use Fcntl qw(:mode);
use Parse::DMIDecode;
use Parse::DMIDecode::Constants qw(@TYPES);

# Get some command line options
my $opts = {};
Getopt::Std::getopts('f:g:Kk:hV',$opts);
$opts->{g} ||= 'processor';
display_help(),exit if defined $opts->{h};

my $decoder = new Parse::DMIDecode;
my $dmidecode = '/usr/sbin/dmidecode';
my @stat = stat($dmidecode);

# If we've been given a dmidecode output file, parse that
if ($opts->{f}) {
	die "File '$opts->{f}' does not exist.\n" unless -f $opts->{f};
	$decoder->parse(`cat $opts->{f}`);

# If we're root, or dmidecode is setuid root, then probe
} elsif ($> || ($stat[4] == 0 && $stat[2] & S_ISUID)) {
	$decoder->probe;

# Otherwise run dmidecode with sudo
} else {
	$decoder->parse(qx(sudo $dmidecode));
}

# Print all of the available keywords
if (defined $opts->{K}) {
	if (defined $opts->{V}) {
		for my $keyword ($decoder->keywords) {
			my $value = $decoder->keyword($keyword);
			$value = '' unless defined $value;
			printf("Keyword '%s' => '%s'\n",
					$keyword,
					(ref($value) eq 'ARRAY' ? join(', ',@{$value}) : $value)
				);
		}
	} else {
		print join("\n",$decoder->keywords)."\n";
	}
	exit;

# Print just one keyword
} elsif ($opts->{k}) {
	printf("Keyword '%s' => '%s'\n",
			$opts->{k},
			$decoder->keyword($opts->{k})
		);
	exit;
}

# Print some information about specific structure handles
for my $handle ($decoder->get_handles( group => $opts->{g} )) {
	printf(">>> Found handle at %s (%s):\n >> Description: %s\n >> Keywords: %s\n%s\n",
			$handle->address,
			$TYPES[$handle->dmitype],
			$handle->description,
			join(', ',$handle->keywords),
			$handle->raw
		);
	if (defined $opts->{V}) {
		for my $keyword ($handle->keywords) {
			my $value = $handle->keyword($keyword);
			$value = '' unless defined $value;
			printf("  > Keyword '%s' => '%s'\n",
					$keyword,
					(ref($value) eq 'ARRAY' ? join(', ',@{$value}) : $value)
				);
		}
	}
	print "\n";
}

sub display_help {
	print qq{Syntax: $0 [-h] [-V] [-K|-k <keyword>|-g <group>] [-f <filename>]
    -h              Display this help
    -K              List all valid keywords
    -V              Print more verbose output
    -g <group>      Display handle information match <group> group
    -f <filename>   Parse dmidecode information from <filename>
};
}


