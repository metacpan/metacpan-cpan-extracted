#!/usr/bin/perl

use vars qw/$VERSION/;
$VERSION = '0.1';
use Getopt::Std;
use POSIX qw/strftime/;

my $USAGE = <<EOF;
snap_charge [-c client] [-y year] [-m month] <chargefile>

Options:

	-c client to return for, implies -n
	-i charges for in-progress month, will set -y and -m
	-m month to total for, requires -y
	-n number only, no K/M/G/T, no text if -c
	-p charges for previous month, will set -y and -m
	-y year to total for

EOF

=head1 NAME

snap_charge -- add together charges for snapback2

=head1 SYNOPSIS

snap_charge [-p|-i] [-c client] [-y year] [-m month] <chargefile>

=head1 DESCRIPTION

When passed a snapback2 charge log filename, compiles and prints a report.
The report will be in N.N[KMGT] format, i.e:

	100  is 100 bytes
	100K is 100 kilobytes where a kilobyte is 1024 bytes
	100M is 100 megabytes where a megabyte is 1024 kilobytes
	100G is 100 gigabytes where a gigabyte is 1024 megabytes
	100T is 100 terabytes where a terabyte is 1024 gigabytes

The charges are based on the bytes read statement returned by
rsync at backup time. All directories under a client domain
name are added together.

=head1 OPTIONS

=over 4

=item -c client

Selects one client domain to report for. If passed -p, -i, or -y YYYY and
-m MM, prints only the number of bytes for that month and nothing else.
If no year/month combination (that includes -i or -p) is sent, then prints
a tab-delimited numeric report line for each month:

	YYYYMM	NNNNNNNNN

Implies the -n option.

=item -i

Summarize charges for current month -- same as passing -y and -m set
to the current year and month.

=item -m MM

The month to report on. Requires -y.

=item -n 

Print numbers only. Forced if -c option is passed. Otherwise, the
report looks like:

	foo.org in 2004-01: 288.6M
	bill.bar.net in 2004-01: 8.5G
	bob.bar.net in 2004-01: 1.2T

=item -p

Summarize charges for last month -- same as passing -y and -m set
to the previous month (and year if in January).

=item -y YYYY

The year to report on.

=back

=head1 BUGS

Should be enhanced to read snapback2 configuration file and figure
out the charge log. That will happen when the functions of snapback2
are modularized -- if they ever are.

=head1 AUTHOR

Mike Heins, <snapback2@perusion.org>.

=cut

use strict;

my %opt;
getopts('c:im:npy:', \%opt) 
	or die $USAGE;

my %monthly;

if($opt{i}) {
	die "Cannot set -y or -m with -i\n\n$USAGE" if $opt{y} or $opt{m};
	die "Cannot set -p with -i\n\n$USAGE" if $opt{p};
	my @t = localtime();
	$opt{y} = strftime("%Y", @t);
	$opt{m} = strftime("%m", @t);
}

if($opt{p}) {
	die "Cannot set -y or -m with -p\n\n$USAGE" if $opt{y} or $opt{m};
	die "Cannot set -i with -p\n\n$USAGE" if $opt{i};
	my $was  = time();
	my $cur_month = $opt{m} = strftime("%m", localtime($was));
	do {
		$was -= 86400;
		my @t = localtime($was);
		$opt{y} = strftime("%Y", @t);
		$opt{m} = strftime("%m", @t);
	} while $cur_month eq $opt{m};
}

if($opt{y}) {
	$opt{y} =~ s/^0+//;
	$opt{y} += 2000 if $opt{y} < 100;
}

if($opt{m}) {
	$opt{m} =~ s/^0+//;
	$opt{m} = sprintf "%02d", $opt{m};
}

if($opt{c}) {
	$opt{n} = 1;
}

while(<>) {
	chomp;
	my($client, $date, $bytes) = split /:/, $_;
	$date =~ m{(\d{4})(\d\d)(\d\d)};
	my ($yr, $mon, $day) = ($1, $2, $3);
	$monthly{$client}{$yr}{$mon} += $bytes;
}

use Data::Dumper;
$Data::Dumper::Terse = 1;

for my $c (sort keys %monthly) {
	next if $opt{c} and $c ne $opt{c};
	my $cref = $monthly{$c};
	for my $y (sort keys %$cref) {
		next if $opt{y} and $y ne $opt{y};
		my $yref = $cref->{$y};
		for my $m (sort keys %$yref) {
			next if $opt{m} and $m ne $opt{m};
			my $total = $yref->{$m};

			if($opt{n}) {
				if($opt{c} and $opt{y} and $opt{m}) {
					print "$total\n";
				}
				else {
					print "$y$m\t$total\n";
				}
			}
			else {
				my $desig;
				for my $lab (qw/K M G T/) {
					last unless $total >= 1024;
					$total /= 1024;
					$desig = $lab;
				}

				$total = sprintf("%.1f", $total);
				print "$c in $y-$m: $total$desig\n";
			}
		}
	}
}
