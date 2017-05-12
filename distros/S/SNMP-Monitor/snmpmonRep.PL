#! -*- perl -*-

my $script = <<'EOF';
~startperl~ -w
#
#
#   SNMP::Monitor - a Perl package for monitoring remote hosts via SNMP
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#

use strict;


use Getopt::Long ();
use SNMP::Monitor ();
use Time::Local ();


############################################################################
#
#   Constant variables
#
############################################################################

my $VERSION
   = 'snmpmonRep, 26-Apr-1999, Copyright (C) 1998-99 by Jochen Wiedmann';
my $ETC_DIR = "~etc_dir~";
my $CONFIG_FILE = "$ETC_DIR/configuration";
my $MAIL_COMMAND = "/usr/ucb/mail -s \$subject \$recipient";


############################################################################
#
#   Global variables
#
############################################################################

use vars qw($debugging $verbose);

$debugging = 0;


############################################################################
#
#   Name:    Usage
#
#   Purpose: Print usage message and exit
#
############################################################################

sub Usage () {
    print <<"USAGE";
Usage: $0 [options]

Possible options are:

    --config <file>     Read configuration from <file>, defaults to
                        $CONFIG_FILE.
    --daily             By default only a sum is printed. This option
			causes daily numbers being printed.
    --debug             Run in debugging mode; don't do anything, just
			show what would be done.
    --help		Show this message.
    --from <dd.mm.yyyy> Start report at the given date, defaults to the
			first day of the previous month.
    --scale <bytes>     Make output scaled by <bytes>. This is required,
		        if your counters exceed Perl's or MySQL's integer
			limits, typically around 2 GB. Examples:
		        --scale=1000 or --scale=1024
    --to <dd.mm.yyyy>   Stop report at the given date, defaults to the
			first day of the current month.
    --version		Print version number and exit.
    --verbose           Run in verbose mode.

$VERSION
USAGE
    exit 1;
}


############################################################################
#
#   Name:    GetTime
#
#   Purpose: Transfrom date string into Unix time.
#
#   Inputs:  Date string
#
#   Returns: Unix time; dies in case of error
#
############################################################################

sub GetTime ($) {
    my $str = shift;
    if ($str =~ /^(\d\d\d\d)[-\.](\d\d)[-\.](\d\d)$/) {
	return Time::Local::timelocal(0, 0, 0, $3, $2-1, $1-1900);
    }
    if ($str !~ /^(\d\d)[-\.](\d\d)[-\.](\d\d\d\d)$/) {
	die "Cannot parse date string $str; use dd.mm.yyyy or yyyy-mm-dd";
    }
    Time::Local::timelocal(0, 0, 0, $1, $2-1, $3-1900);
}


############################################################################
#
#   Name:    ReportInterface
#
#   Purpose: Generate interface report
#
#   Inputs:  $dbh       - Database handle
#            $host      - Config file host
#            $interface - Config file interface
#            $from, $to - Report times
#
#   Returns: Report data
#
############################################################################

sub _FromUnixTime {
    my($sec, $min, $hour, $mday, $mon, $year) = localtime(shift);
    sprintf('%04d-%02d-%02d %02d:%02d:%02d',
	    $year+1900, $mon+1, $mday, $hour, $min, $sec);
}

sub ReportInterface ($$$$$$) {
    my($o, $dbh, $host, $interface, $from, $to) = @_;

    my $inSum = $o->{'scale'} ?
         "ROUND(SUM(INOCTETS/$o->{'scale'}.0))" : "SUM(INOCTETS)";
    my $outSum = $o->{'scale'} ?
	 "ROUND(SUM(OUTOCTETS/$o->{'scale'}.0))" : "SUM(OUTOCTETS)";

    my $query = sprintf("SELECT $inSum AS INSUM, $outSum AS OUTSUM,"
			. " $inSum+$outSum AS SUM,"
			. " AVG(OPERSTATUS=1)*100 AS AVGSUM"
			. " FROM SNMPMON_IFLOAD WHERE"
			. " INTERVAL_END >= %s AND INTERVAL_END < %s "
			. " AND INTERFACE = %s AND HOST = %s",
			$dbh->quote(_FromUnixTime($from)),
			$dbh->quote(_FromUnixTime($to)),
			$interface->{'num'},
			$dbh->quote($host->{'name'}));
    if ($verbose) {
	print "Interface query: $query\n";
    }
    my $sth = $dbh->prepare($query);
    $sth->execute();
    my $ref = $sth->fetchrow_arrayref();

    my $ifInOctets = $ref ? $ref->[0] : 0;
    my $ifOutOctets = $ref ? $ref->[1] : 0;
    my $sumOctets = $ref ? $ref->[2] : 0;
    my $avg = $ref ? $ref->[3] : 0;
    my $result = { 'in' => $ifInOctets,
      'out' => $ifOutOctets,
      'sum' => $sumOctets,
      'avg' => $avg,
      'host' => $host->{'name'},
      'description' => $interface->{'short_message'} ||
	               $interface->{'description'},
      'interface' => $interface->{'num'}
    };

    if ($o->{'daily'}) {
	$query = sprintf("SELECT $inSum AS INSUM, $outSum AS OUTSUM,"
			 . " $inSum+$outSum AS SUM,"
			 . " AVG(OPERSTATUS=1)*100 AS AVGSUM,"
                         . " YEAR(INTERVAL_END) AS Y,"
			 . " MONTH(INTERVAL_END) AS M,"
			 . " DAYOFMONTH(INTERVAL_END) AS D FROM"
			 . " SNMPMON_IFLOAD WHERE"
			 . " INTERVAL_END >= %s AND INTERVAL_END < %s "
			 . " AND INTERFACE = %s AND HOST = %s"
			 . " GROUP BY Y, M, D ORDER BY Y, M, D",
			 $dbh->quote(_FromUnixTime($from)),
			 $dbh->quote(_FromUnixTime($to)),
			 $interface->{'num'},
			 $dbh->quote($host->{'name'}));
	my @days;
	$sth = $dbh->prepare($query);
	$sth->execute();
	while (my $ref = $sth->fetchrow_hashref()) {
	    push(@days, {%$ref});
	}
	$result->{'days'} = \@days;
    }

    $result;
}


############################################################################
#
#   Name:    Report
#
#   Purpose: Generate report
#
#   Inputs:  $o - Hash ref of options
#            $from - From time
#            $to - To time
#
#   Returns: Nothing, dies in case of trouble.
#
############################################################################

sub Report ($$$) {
    my($o, $from, $to) = @_;
    my $configFile = $o->{'config'};
    my $config = SNMP::Monitor->Configuration($configFile);
    my $reports = {};

    my $dbh = DBI->connect($config->{'dbi_dsn'}, $config->{'dbi_user'},
			   $config->{'dbi_pass'}, { 'RaiseError' => 1 });

    foreach my $host (values %{$config->{'hosts'}}) {
	foreach my $interface (@{$host->{'interfaces'}}) {
	    if (my $addr = $interface->{'report'}) {
		if ($verbose) {
		    print("Reporting host ", $host->{'name'},
			  "interface ", $interface->{'num'}, "\n");
		}
		my $r = ReportInterface($o, $dbh, $host, $interface, $from,
                                        $to);
		foreach my $a (split(/,/, $addr)) {
		    $a =~ s/^\s+//;
		    $a =~ s/\s+$//;
		    if (!$reports->{$a}) {
			$reports->{$a} = [];
		    }
		    push(@{$reports->{$a}}, $r);
		}
	    } else {
		if ($verbose) {
		    print("Ignoring host ", $host->{'name'},
			  "interface ", $interface->{'num'}, "\n");
		}
	    }
	}
    }

    my($sec, $min, $hour, $to_d, $to_m, $to_y, $from_d, $from_m, $from_y);
    ($sec, $min, $hour, $from_d, $from_m, $from_y) = localtime($from);
    ($sec, $min, $hour, $to_d, $to_m, $to_y) = localtime($to);

    $from_y += 1900;
    $from_m += 1;
    $to_y += 1900;
    $to_m += 1;

    while (my ($a, $list) = each %$reports) {
	my($sInterface, $sIn, $sOut, $sSum, $sUp) =
	    (length("Interface"), length("Bytes In"), length("Bytes Out"),
	     length("Sum"), length("Uptime"));
	foreach my $l (@$list) {
	    $sInterface = length($l->{'description'})
		if (length($l->{'description'}) > $sInterface);
	    $sIn = length($l->{'in'}) if (length($l->{'in'}) > $sIn);
	    $sOut = length($l->{'out'}) if (length($l->{'out'}) > $sOut);
	    $sSum = length($l->{'out'} + $l->{'in'})
		if (length($l->{'out'} + $l->{'in'}) > $sSum);
	    $sUp = length($l->{'avg'}) if (length($l->{'avg'}) > $sUp);
	}
	my $format = sprintf("%%%ds %%%ds %%%ds %%%ds %%%d.2f",
			     $sInterface, $sIn, $sOut, $sSum, $sUp);

	my $msg = qq{

Interfaceauslastung vom $from_d.$from_m.$from_y - $to_d.$to_m.$to_y:

};
	$msg .= sprintf("\n$format\n",
			"Interface", "Bytes In", "Bytes Out", "Summe",
			"Uptime");
	$msg .= "\n";
	foreach my $l (@$list) {
	    $msg .= sprintf("$format\n",
			    $l->{'description'},
			    $l->{'in'}, $l->{'out'}, $l->{'sum'},
			    $l->{'avg'});
	    if ($l->{'days'}) {
		foreach my $d (@{$l->{'days'}}) {
		    $msg .= sprintf("$format\n",
				    sprintf("%02d.%02d.%04d",
				            $d->{'D'}, $d->{'M'},
					    $d->{'Y'}),
				    $d->{'INSUM'}, $d->{'OUTSUM'},
				    $d->{'SUM'},
				    $d->{'AVGSUM'});
		}
		$msg .= "\n";
	    }
	}

	if ($verbose) {
	    print "Sending message to $a:\n\n$msg\n\n";
	}
	if (!$debugging) {
	    my $command = $MAIL_COMMAND;
	    $command =~ s/\$subject/Interfaceauslastung/;
	    $command =~ s/\$recipient/$a/;
	    if (!open(PIPE, "| $command")  ||  !(print PIPE $msg)  ||
		!close(PIPE)) {
		print STDERR "Error while sending mail via $command: $!";
	    }
	}
    }

    $dbh->disconnect();
}


############################################################################
#
#   This is main().
#
############################################################################

{
    my $o = {
        'config' => $CONFIG_FILE,
        'debug' => \$debugging,
        'help' => \&Usage,
        'verbose' => \$verbose,
        'version' => sub { print "$VERSION\n"; exit 0; }
    };
    &Getopt::Long::GetOptions($o, '--from=s', '--to=s', '--daily',
                              '--debug',
			      '--help', '--config=s', '--verbose',
			      '--version');
    ++$verbose if $debugging and !$verbose;

    my $from;
    if ($o->{'from'}) {
	$from = GetTime($o->{'from'});
    } else {
	my($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
	if (--$mon < 0) {
	    $mon = 11;
	    --$year;
	}
	$from = Time::Local::timelocal(0, 0, 0, 1, $mon, $year);
    }

    my $to;
    if ($o->{'to'}) {
	$to = GetTime($o->{'to'});
    } else {
	my($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
	$to = Time::Local::timelocal(0, 0, 0, 1, $mon, $year);
    }

    Report($o, $from, $to);
}


__END__

=pod

=head1 NAME

  snmpmonRep - Create SNMP-Monitor reports


=head1 SYNOPSIS

  snmpmonRep [--config <file>] [--daily] [--debug] [--from <fromtime>]
	     [--help] ] [--scale <bytes>] [--to <totime>] [--verbose]
             [--version]


=head1 DESCRIPTION

This is a small utility for extracting statistics from an SNMP-Monitor
database. It is typically called every month for generating accounting
data.

The report generator reads a list of all hosts and interfaces from
its config file, by default F<~etc_dir~/configuration>. For any
interface and host it finds, the sums of inoctets, outoctets and
the average uptime are computed. Defaults are sent via email to
the recipients configured in the config file.

Available options are:

=over 8

=item --config <file>

This option forces reading the configuration from <file>. The default
config file is F<~etc_dir~/configuration>.

=item --daily

By default only total sums are computed. This option will add daily
sums to the generated report. Daily sums can slow down the report
drastically, because they require grouping and sorting.

=item --debug

This option suppresses sending reports. Implies verbose mode.

=item --from <yyyy-mm-dd>

This option is used to set the reports start time. By default the
previous month is reported, thus --from defaults to the first day of
the previous month. Dates can be in the format yyyy-mm-dd or
dd-mm-yyyy. See also the --to option.

=item --help

Print a usage message and exit with error status.

=item --scale <bytes>

If your counters exceed Perl's or MySQL's integer limits, you can reduce
the reports granularity to avoid overflow of numbers. This is typically
required, if the counters exceed 2 GB. Examples:

  --scale=1000

or

  --scale=1024

=item --to <yyyy-mm-dd>

Similar to --from, setting the reports stop time. This option is used to
set the reports start time. By default the previous month is reported,
thus --to defaults to the first day of the current month. Dates can be
in the format yyyy-mm-dd or dd-mm-yyyy. See also the --from option.

=item --version

Print version number and exit.

=item --verbose

Turn on verbose mode, usefull mainly for debugging.

=back


=head1 AUTHOR AND COPYRIGHT

This program is Copyright (C) 1998-99 by

    Jochen Wiedmann
    Am Eisteich 9
    72555 Metzingen
    Germany

    Phone: +49 7123 14887
    Email: joe@ispsoft.de

All rights reserved.

You may distribute this program under the terms of either the GNU General
Public License or the Artistic License, as specified in the Perl README file.


=head1 FILES

   ~etcdir~/configuration	Default config file


=head1 SEE ALSO

  L<snmpmon(1)>, L<SNMP::Monitor(3)>
EOF

require SNMP::Monitor;
my $config = SNMP::Monitor->Configuration('configuration');

require Config;
$config->{'startperl'} = $Config::Config{'startperl'};
$config->{'startperl'} = $Config::Config{'startperl'}; # Make -w happy ...


$script =~ s/\~(\w+)\~/$config->{$1}/eg;

if (!open(FILE, ">snmpmonRep")  ||  !print FILE ($script)  ||  !close(FILE)) {
    die "Error while writing snmpmonRep script: $!";
}
