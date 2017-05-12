#!perl
use strict;
use warnings;

# built-in modules
use English qw( -no_match_vars );
use Getopt::Long;

# CPAN modules
use Date::Calc qw(Days_in_Month);
use DBIx::Simple;
use MIME::Lite;
use Net::SMTP;
use Text::CSV;
use Pod::Usage;
use Config::Std { def_sep => '=' };

# Local modules
use lib "lib";
use RTG::Report;
my $report = RTG::Report->new();

###########    SITE CONFIGURATION    ###########
# Load named config file into specified hash...
read_config '/usr/local/etc/rtgreport.conf' => my %config;

my $db_user      = $config{Database}{user};
my $db_pass      = $config{Database}{pass};
my $dsn          = $config{Database}{dsn};
my $emails_ref   = $config{Email}{address};
my $smart_host   = $config{Email}{host};
my $report_units = $config{Report}{units} * 1;
my $skip_desc    = $config{Report}{skip_desc};
my $skip_name    = $config{Report}{skip_name};
my $skip_zero    = $config{Report}{skip_zero};
my $networks_ref = $config{Networks}{network};
my $isp_uplinks  = $config{Summary}{isp};
my $uplinks      = $config{Summary}{uplink};
my $downlinks    = $config{Summary}{downlink};

my %networks;
if ( $report->is_arrayref($networks_ref) ) {
	foreach ( @$networks_ref ) {
	    my ($net, $db, $dc, $num) = $_ =~ /^\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*$/;
	    $networks{$net} = { db=>$db, dc=>$dc, num=>$num };
	};
}
else {
    my ($net, $db, $dc, $num) = $networks_ref =~ /^\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*$/;
    $networks{$net} = { db=>$db, dc=>$dc, num=>$num };
}


###########   COMMAND LINE OPTIONS   ###########
my @cli_args = @ARGV;
my %cmd_line_options = (
    'all_ifs' => \my $all_records,
    'back=i'  => \my $eom_days,
    'desc=s'  => \my $opt_description,
    'email=s' => \my $opt_email,
    'help'    => \my $opt_help,
    'max=i'   => \my $max_ifs,
    'no95th'  => \my $opt_no_95th,
    'norates' => \my $opt_no_rates,
    'nosum'   => \my $opt_no_summaries,
    'net=s'   => \my $opt_net,
    'start=s' => \my $start_day,
    'stop=s'  => \my $end_day,
    'units=s' => \my $opt_units,
    'utiliz'  => \my $opt_utilization,
    'verbose' => \my $debug,
);
GetOptions(%cmd_line_options);

$debug ? pod2usage({-verbose=>2}) : pod2usage({-verbose=>0}) if $opt_help;
my @emails;
if ($opt_email) {
    @emails = $opt_email 
}
else {
    if ( $report->is_arrayref($emails_ref) ) {
        foreach my $email (@$emails_ref) { push @emails, $email };
    }
    else {
        push @emails, $emails_ref;
    }
};

if ( $opt_units ) {
    if    ($opt_units =~ /k/i ) { $report_units = 1000       }
    elsif ($opt_units =~ /m/i ) { $report_units = 1000000    }
    elsif ($opt_units =~ /g/i ) { $report_units = 1000000000 };
};

if ($opt_net) { 
    die "invalid net!\n" if !$networks{$opt_net};
    %networks = ( $opt_net => $networks{$opt_net} );
};

my $description_format = 'pattern';
my %descriptions;
if ( $opt_description ) {
    my @descriptions;
    if ( -f $opt_description ) {      # test for existence of file
        $description_format = 'file'; # change our default search type
        open my $DESC, "<", $opt_description;
            @descriptions = <$DESC>; chomp @descriptions;
        close $DESC;
    }

    # put our descriptions in a hash so it is easy to tell if a value exists
    foreach my $desc (@descriptions) { $descriptions{uc($desc)} = 1; }
};


###########       DATE VARIABLES     ###########
# if today is less than the Nth day of the month, set date variables 
# to N days ago for a report of the previous month)
$eom_days  ||= 5; 
$start_day ||= '01';    # these are intentionally strings
$end_day   ||= '30';
$max_ifs   ||= undef;

# sets up date variables based on today date
my ($dd, $mm, $yy, $lm, $hh, $mn, $ss) = $report->get_the_date();

if ($dd < $eom_days ) { 
	($dd, $mm, $yy, $lm, $hh, $mn, $ss) = $report->get_the_date($eom_days);
	$end_day = Days_in_Month($yy,$mm);
}
else {
	$end_day = sprintf "%02i", $dd - 1;    # yesterday is the last day in the report
}

my $start_date = $yy . $mm . $start_day . '000000';  # begin timestamp
my $end_date   = $yy . $mm . $end_day   . '235959';  # end   timestamp
my $range      = "dtime>$start_date AND dtime<=$end_date";  # sql format
#my $range     = "dtime BETWEEN $start_date AND $end_date"; # or this

###########   PRINT DEBUGGING INFO   ###########
my $status;
$OUTPUT_AUTOFLUSH++;           # don't buffer screen output
my $ru = $report_units == 1000       ? 'KB' :
         $report_units == 1000000    ? 'MB' :
         $report_units == 1000000000 ? 'GB' :
         die "Report Units is not set properly!\n";
$status .= $report->status( "command line  : $0 " . join(" ", @cli_args ), undef, 1 );
$status .= $report->status( "report period : $yy/$mm/$start_day to $end_day (eom=$eom_days)", undef, 1);
$status .= $report->status(                    "report units  : $ru" , undef, 1);
$status .= $report->status( $opt_net         ? "networks      : ".$opt_net : "networks      : all", undef, 1);
$status .= $report->status( $all_records     ? "all records   : on" : "all records   : off", undef, 1);
$status .= $report->status(                    "max ifs       : ".$max_ifs, undef, 1) if $max_ifs;
$status .= $report->status( !$opt_no_rates   ? "show rates    : on" : "show rates    : off", undef, 1);
$status .= $report->status( !$opt_no_95th    ? "show 95th     : on" : "show 95th     : off", undef, 1);
$status .= $report->status( $opt_utilization ? "show util %   : on" : "show util %   : off", undef, 1);
$status .= $report->status( "description : ".$opt_description ." ($description_format)", undef, 1 ) if $opt_description;
$status .= $report->status( "recipients : " . join(' ', @emails), undef, 1 );


main();
exit;

sub main {

    my $start_time = `date "+%Y-%m-%d %H:%M:%S"`; chomp $start_time;

    # get the CSV file header 
    my $csv = Text::CSV->new();
    my $r   = $csv->combine( 
        $report->formatted_header(
            $report_units, $opt_no_rates, $opt_utilization, $opt_no_95th) );
    my $report = $csv->string() . "\n";

    # get the data from RTG and populate global %networks
    foreach my $net ( 
        sort { $networks{$a}->{'num'} <=> $networks{$b}->{'num'} } keys %networks
    ) {
        $networks{$net}->{'interfaces'} = get_bandwidth_data($net);
    };

    # format each networks data into CSV
    foreach my $net ( 
        sort { $networks{$a}->{'num'} <=> $networks{$b}->{'num'} } keys %networks ) {
        $report .= network_csv($net);
    };

    my $end_time = `date "+%Y-%m-%d %H:%M:%S"`;

    # append missing description report
    if ( $opt_description && $description_format eq 'file' ) {
        $status .= "\n\tMISSING DESCRIPTION REPORT\n";
        foreach my $desc ( keys %descriptions ) {
            $status .= "$desc\n";
        };
    };

#    print $report;    # print report to stdout
    email_report( $report, $start_time, $end_time, $status );
};

sub email_report {

    my ($report, $start_time, $end_time, $status) = @_;

    my $msg = MIME::Lite->new (
        From    => 'RTG Reporter <no_reply@' . `hostname` . '>',
        To      => shift @emails,
        CC      => join(', ', @emails),
        Subject => "Bandwidth Billing Report for $mm/$start_day to $mm/$end_day",
        Type    => 'multipart/mixed',
    ) or die "Error creating multipart container: $!\n";

    $msg->attach(
        Type     => 'TEXT',
        Data     => "Attached is a RTG Bandwidth Billing Report\n\n\n",
    );

    $msg->attach(
        Type        => 'text/csv',
        Data        => $report,
        Disposition => 'attachment',
        Filename    => "rtg_bw_${yy}_${mm}_$start_day-$end_day.csv",
    );

    $msg->attach(
        Type     => 'TEXT',
        Data     => "\n\n
         © 2008 Layered Technologies
 Bandwidth Billing Report (bandwidth_report.pl)
            by: Matt Simerson

        report initiated: $start_time
        report completed: $end_time

$status \n\n",
    );

    $msg->send('smtp', $smart_host );
}

sub formatted_interface {

    my ($net_num, $interface) = @_;

    my $bandwidth  = $interface->{'bandwidth'};

    my $format = $report_units == 1000000000 ? '%.3f' : '%.0f';

    # note the conversion of numbers from from bit/bytes to $report_units
    my @fields = (
        $net_num,
        $interface->{'rid'}, 
        $interface->{'r_name'},
        $interface->{'id'}, 
        $interface->{'name'}, 
        $interface->{'speed'}, 
        $interface->{'description'},
        $bandwidth->{'bytes_in'}  ? sprintf($format, $bandwidth->{'bytes_in'} / $report_units) : 0,
        $bandwidth->{'bytes_out'} ? sprintf($format, $bandwidth->{'bytes_out'}/ $report_units) : 0,
    );

    if ( !$opt_no_rates ) {
        push @fields, 
            sprintf($format, $bandwidth->{'rate_in_avg'}   / $report_units),
            sprintf($format, $bandwidth->{'rate_out_avg'}  / $report_units),
            sprintf($format, $bandwidth->{'rate_in_peak'}  / $report_units),
            sprintf($format, $bandwidth->{'rate_out_peak'} / $report_units);
    };

    if ( $opt_utilization ) {
        push @fields, 
            $bandwidth->{'util_in_avg'},
            $bandwidth->{'util_out_avg'},
            $bandwidth->{'util_in_peak'},
            $bandwidth->{'util_out_peak'};
    };

    if ( !$opt_no_95th ) {
        push @fields,
            $bandwidth->{'rate_in_95th'}  ? sprintf($format, $bandwidth->{'rate_in_95th'}  / $report_units) : 0,
            $bandwidth->{'rate_out_95th'} ? sprintf($format, $bandwidth->{'rate_out_95th'} / $report_units) : 0;
    };

    push @fields, substr($start_date,0,8), substr($end_date,0,8);
    return @fields;
};

sub formatted_summary {

    my ($net, $num, $type, $if_count) = @_;

    my $links = $networks{$net}->{'interfaces'}->{$type};
    delete $networks{$net}->{'interfaces'}->{$type};

    # generate the CSV record for net uplinks
    my @fields = (
        $num, 
        'all', 
        $type,
        $type eq "totals" ? $if_count : 'n/a',
        $type, 
        'n/a', 
        "$net $type",
        $links->{'bytes_in'}  ? int($links->{'bytes_in'} / $report_units + .5) : 0,
        $links->{'bytes_out'} ? int($links->{'bytes_out'}/ $report_units + .5) : 0,
    );

    if ( !$opt_no_rates ) {         # rate in/out averages
        push @fields, 
            $links->{'rate_in_avg'}  ? sprintf("%.1f", $links->{'rate_in_avg'}  / $report_units) : 0,
            $links->{'rate_out_avg'} ? sprintf("%.1f", $links->{'rate_out_avg'} / $report_units) : 0,
            $links->{'rate_in_peak'} ? sprintf("%.1f", $links->{'rate_in_peak'} / $report_units) : 0,
            $links->{'rate_out_peak'}? sprintf("%.1f", $links->{'rate_out_peak'}/ $report_units) : 0;
    };

    if ( $opt_utilization ) {         # rate in/out peak
        push @fields, 'n/a', 'n/a', 'n/a', 'n/a';
    };

    if ( !$opt_no_95th ) {
        push @fields, 'n/a', 'n/a';
    };

    push @fields, substr($start_date,0,8), substr($end_date,0,8);

    return @fields;
};

sub get_bandwidth_data {

    my $net = shift;

    my $db  = DBIx::Simple->connect( $dsn, $db_user, $db_pass) 
            or die "couldn't connect to database: $!\n";

    my $db_name    = $networks{$net}->{'db'};
    my $ifs_query  = "SELECT id,rid,name,speed,description FROM $db_name.interface";
    my @interfaces = $db->query( $ifs_query )->hashes;

    $report->status( "\nprocessing $net which has " . scalar @interfaces . " interfaces.");

    my $if_count = 0;
    my %interface_vals;

    foreach my $interface (@interfaces) {

        $if_count++; next if ($max_ifs && $if_count > $max_ifs);

        my $iid      = $interface->{'id'};
        my $rid      = $interface->{'rid'},
        my $if_name  = $interface->{'name'},
        my $if_speed = $interface->{'speed'};
        my $if_desc  = $interface->{'description'} || '';

        if ( ! $iid ) { warn "strange, no iid?!\n"; next; };
        if ( ! $rid ) { warn "strange, no rid?!\n"; next; };

        # weed out interfaces not useful to billing
        if ( $opt_description ) {
            if ( $description_format eq 'pattern' ) {
                next if $if_desc !~ m/$opt_description/i;
            } 
            elsif ( $description_format eq 'file' ) {
                next unless $descriptions{ uc($if_desc) };
                delete $descriptions{ uc($if_desc) };
            }
        }
        else {
            $if_count % 100 == 0 ? $report->status($if_count, 1)
                : $if_count % 10 == 0 ? $report->status(".",1) : print '';

            if ( !$all_records ) {
                next if $report->should_i_skip_it($if_desc, $if_name, $skip_desc, $skip_name);
            };
        }

        # get the routers IP (which is stored in the 'name' field)
        my $rid_query  = "SELECT name FROM $db_name.router WHERE rid=$rid";
        my $router_row = $db->query( $rid_query )->hash or warn $db->error;
        my $router_name = $router_row->{'name'};

        # get the interface stats ( bytes rate_peak rate_avg rate_95th )
        my $in  = $report->get_interface_stats(
            { db=>$db, iid=>$iid, range=>$range, table=>$db_name.'.ifInOctets_'.$rid  });
        my $out = $report->get_interface_stats(
            { db=>$db, iid=>$iid, range=>$range, table=>$db_name.'.ifOutOctets_'.$rid });

        # ignore interfaces that have not passed any traffic
        if ( !$all_records ) {
            if ( $skip_zero ) {
                next if ( !$in->{'bytes'} && !$out->{'bytes'});   # if not defined
                next if ( $in->{'bytes'} == 0 && $out->{'bytes'} == 0 );  # if equal to zero
            };
        };

        my $util_in_avg = my $util_out_avg = my $util_in_peak = my $util_out_peak = 0;  

        if ($if_speed != 0) {       # calculate the utilization rate of the port
            $util_in_avg   = sprintf("%.0f", ($in->{'rate_avg'}   / $if_speed) * 100);
            $util_out_avg  = sprintf("%.0f", ($out->{'rate_avg'}  / $if_speed) * 100);
            $util_in_peak  = sprintf("%.0f", ($in->{'rate_peak'}  / $if_speed) * 100);
            $util_out_peak = sprintf("%.0f", ($out->{'rate_peak'} / $if_speed) * 100);
        }

        # put interface summaries into %interface_vals
        $interface_vals{$iid}->{'id'}          = $iid;
        $interface_vals{$iid}->{'name'}        = $if_name;
        $interface_vals{$iid}->{'rid'}         = $rid;
        $interface_vals{$iid}->{'r_name'}      = $router_name;
        $interface_vals{$iid}->{'speed'}       = $if_speed;
        $interface_vals{$iid}->{'description'} = $if_desc;
        $interface_vals{$iid}->{'bandwidth'}   =
            {
                bytes_in      => $in->{'bytes'},
                bytes_out     => $out->{'bytes'},
                rate_in_peak  => $in->{'rate_peak'},
                rate_out_peak => $out->{'rate_peak'},
                rate_in_avg   => $in->{'rate_avg'},
                rate_out_avg  => $out->{'rate_avg'},
                rate_in_95th  => $in->{'rate_95th'},
                rate_out_95th => $out->{'rate_95th'},
                util_in_avg   => $util_in_avg,
                util_out_avg  => $util_out_avg,
                util_in_peak  => $util_in_peak,  
                util_out_peak => $util_out_peak,
            };

        my $totals = 'totals';          # the default summary entry

        if    ( $if_desc =~ /$isp_uplinks/i ) { $totals = 'isp_uplinks'; }
        elsif ( $if_desc =~ /$uplinks/i )     { $totals = 'uplinks';     }
        elsif ( $if_desc =~ /$downlinks/i )   { $totals = 'downlinks';   };

        # add interface values to summary totals
        $interface_vals{$totals}->{'rate_in_avg'}   += $in->{'rate_avg'};
        $interface_vals{$totals}->{'rate_out_avg'}  += $out->{'rate_avg'};
        $interface_vals{$totals}->{'rate_in_peak'}  += $in->{'rate_peak'};
        $interface_vals{$totals}->{'rate_out_peak'} += $out->{'rate_peak'};
        $interface_vals{$totals}->{'bytes_in'}      += $in->{'bytes'};
        $interface_vals{$totals}->{'bytes_out'}     += $out->{'bytes'};
    }
    print "\n";

    $db->disconnect;
    return \%interface_vals;
};

sub network_csv {

    my $net = shift;

    my $interfaces = $networks{$net}->{'interfaces'};
    my $num        = $networks{$net}->{'num'};

    my ($status, $report);

    my $csv = Text::CSV->new();

    # generate the CSV summary records
    unless ( $opt_no_summaries ) {
        my $if_count  = scalar keys %$interfaces;
        my @summaries = qw/ downlinks uplinks isp_uplinks totals /;
        foreach my $summary (@summaries) {
            $status = $csv->combine( formatted_summary($net, $num, $summary, $if_count) );
            $report .= $csv->string() . "\n";
        };
    };

    # iterate over each interface, sorted by description
    foreach my $interface ( 
        sort { $interfaces->{$a}->{'description'} 
           cmp $interfaces->{$b}->{'description'} } keys %$interfaces ) {

        my @fields = formatted_interface($num, $interfaces->{$interface});
        if ( $status = $csv->combine( @fields ) ) {
            $report .= $csv->string() . "\n";
        } 
        else {
            my $err = $csv->error_input;
            print "parse() failed on argument: ", $err, "\n";
        };
    }

    return $report;
}

sub network_plain {

    my $net = shift;

    my $interfaces = $networks{$net}->{'interfaces'};
    my $num        = $networks{$net}->{'num'};

    my ($status, $report);

    # generate the CSV summary records
    unless ( $opt_no_summaries ) {
        my $if_count  = scalar keys %$interfaces;
        my @summaries = qw/ downlinks uplinks isp_uplinks totals /;
        foreach my $summary (@summaries) {
            $report .= join(" ", formatted_summary($net, $num, $summary, $if_count) . "\n");
        };
    };

    # iterate over each interface, sorted by description
    foreach my $interface ( 
        sort { $interfaces->{$a}->{'description'} 
           cmp $interfaces->{$b}->{'description'} } keys %$interfaces ) {

        $report .= join(" ", formatted_interface($num, $interfaces->{$interface}) . "\n");
    }

    return $report;
}


=head1 NAME

billing_report.pl - extract usage data from RTG databases, particularly for bandwidth billing.

=head1 VERSION

1.5.0

=head1 SYNOPSIS

  bandwidth_billing.pl [-options] [-v]

    available options:
    ------------------------------------------------
    all_ifs:    display all interfaces (no filtering)
    back:       days backwards used to determine reporting period
    desc:       port description to search for
    email:      email address to send the report to
    max:        maximum number of interfaces to report
    no95th:     suppress 95th percentile columns
    norates:    suppress rate columns
    nosum:      suppress summary rows
    net:        report only a particular network
    start/stop: start/end day in DD format
    units:      reporting units - a number to divide octets/bits by
    utiliz:     display port utilization columns

    help:     display this help page
    verbose:  verbose/debug output


=head1 USAGE

Add to cron:

 # crontab -e
 30 5 1 * * /usr/local/sbin/report_bandwidth.pl

Or better yet, add to your systems periodic scripts. On FreeBSD, this would be optimal:

  mkdir -p /usr/local/etc/periodic/monthly && chdir /usr/local/etc/periodic/monthly
  echo '#!/bin/sh' > bandwidth_report.sh
  echo '/usr/local/sbin/report_bandwidth.pl' >> bandwidth_report.sh
  chmod 755 bandwidth_report.sh

=head1 OPTIONS 

=over 4

=item B<-all_ifs>

By default, interfaces whose name contains vlan and port-channel are filtered out. Selecting this option prevents the filtering of those interfaces. 

=item B<-back>

The default reporting time period is the first day of the current month until the last complete day of data, yesterday. The exception to this rule is EOM (End of Month) days. If run within 5 days of of the end of the month (ie, the 1-5 of the next month), then the reporting interval is the previous complete month.

This setting allows specification of how many days B<-back> are used when calculating the month to report. To run a report for the previous month when the current day is greater than 5, set B<-back> to a value of todays day plus one.

 Examples: 
 Jan 25th, -back 5, reports Jan 1-24
 Feb 04th, -back 5, reports Jan 1-31
 Feb 10th, -back 5, reports Feb 1-9
 Feb 10th, -back 11, reports Jan 1-31
 Feb 10th, -back 45, reports Dec 1-31

=item B<-desc>

A port description. If provided, the report will only report data for ports that match the supplied description. 

-desc can optionally specify a filename. The contents of the file must be a list of port descriptions, one per line. When run this way, only ports matching a description listed in the file will be reported on.

=item B<-email>

The report is automatically emailed to each email address listed in the reporter.conf file. You can optionally specify an email address on the command line that overrides the config file settings.

=item B<-help>

Prints out the pod documentation.

=item B<-max>

max is a maximum number of interfaces to run against. We have a large network with many thousands of interfaces. I use this option when testing the script.

=item B<-no95th>

Suppresses the 95th percentile columns in the report.

=item B<-norates>

Suppresses the rate columns in the report. The four rate columns are the average in/out Mbit/s and max in/out Mbit/s.

=item B<-nosum>

The report automatically includes 4 summary entries for each network. These four links include summaries of uplinks, downlinks, isp_uplinks, and a grand total for the network. The uplinks, downlinks, and isp_uplinks are all detected based on keywords defined in the port descriptions. You can suppress these summary entries entirely with the -nosum option.

=item B<-net>

If you have many networks configured, you can run a report for just one of them by specifying it with the -net option.

=item B<-start/stop>

If the -back option doesn't provide the exact date range you want, you can optional specify a -start and -end day for the report. This would be useful if you were reporting on a basis other than monthly.

=item B<-units>

The default reporting units are Megabyte/bits. This can be changed in the config file or via the command line. Common values would be 1000 (kilo), 1000000 (mega), 1000000000 (gig).

=item B<-utiliz>

Utilization is the percentage of bandwidth utilized by a client. It is not reported by default. Utilization is calculated based on the actual usage and the port speed. When using the default rtgtargetmkr.pl script supplied with RTG, this number will be frequently invalid as that script does not automatically update port descriptions or speeds. I have rewritten the target maker script with a version that does update the dabase when switch/router changes are detected.

=item B<-verbose>

This billing is designed to run quietly via cron and only generate noise if errors are encountered. The -verbose option prints out status information while processing.

=back

=head1 DESCRIPTION

This script is a replacement for RTG's report.pl by Rob Beverly and Adam Rothschild.

The biggest difference between this and the old script is that the old one just spat out formatted lines of text as it progressed. Unfortunately, the predefined fixed format also truncated fields. It was entirely too difficult to add or remove fields from the old report. It also required preprocessing to import into other programs (Excel, SQL, etc). It required too much effort to make it do what we needed.

This script is entirely rewritten using the Model-View-Controller architecture.  It begins by collecting all the report data from the database(s), calculating the math as required, and then populating internal data structures with the bandwidth data. Internally, the values are always represented with the least possible degree of calculation. During output, the values are converted and output is based on the settings (columns, units, etc) selected. 

The only fully implemented export format is CSV but adding other export options is trivial. The addition of an SQL export is planned and there is a subroutine named 'network_plain' which shows a way to generate a plain text report. It can be hacked as necessary. I highly recommend using the CSV export as there are no field length limits, the headers are dynamically generated based on config file/command line settings, and the resulting files can be easily imported into other applications.

=head1 CONFIGURATION

Configuration and syntax is defined in the rtgreport.conf file. The default location is in /usr/local/etc. See the example configuration file for additional documentation.


=head1 DEPENDENCIES

Uses the following perl built-in modules: English, Getopt::Long

Also uses the following perl modules available from CPAN: 
Date::Calc, DBIx::Simple, MIME::Lite, Net::SMTP, Text::CSV, Pod::Usage, Config::Std

=head1 CHANGES

=over 8

=item v1.5.0 - Mar 01, 2008

 - moved config values into rtgreport.conf
 - added missing documentation 
 - renamed pod to net, less LT specific and more generally applicable
 - added network_plain subroutine as a code example implementing plain text
 - refactored much code info Report.pm (shared with bandwidth report)

=item v1.1.5 - Feb 07, 2008

 - bug fix, reports with end dates of < 10 needed zero padding for the day value
 - append missing descriptions list to -desc reports

=item v1.1.4 - Feb 04, 2008

 - added units to header of 95th column

=item v1.1.3 - Jan 28, 2008
 - -units option accepts mb or gb as arguments

=item v1.1.2 - Jan 25, 2008

 - include the runtime messages in the email report
 - CLI -desc can optionally be a file with interface descriptions, one per
   line.

=item v1.1.1 - Jan 24, 2008

 - only insert the CSV header line once (instead of once per net) - per Tim J
 - new CLI option: -desc, only match interfaces with that description
 - new CLI option: -nosum, suppress summary fields

=item v1.1.0 - Jan 17, 2008 

 - added net documentation
 - added dc name to each net definition
 - added CLI options: gig, help, rates, units, util
 - units now sets the units (K/M/G) for the report
 - print H:M:S in start/stop timestamps
 - report uplink/downlink/isp links separately
 - only display averages and utilization if selected on cli
 - duplicate timestamps can occur when "falling back"
    during DST. Instead of ignoring the entry, add the
    counters and ignore the timestamp.
 - calculate 95th percentile if gig option

=item v1.0.1 - Jan 10, 2008

 - made the site config options command line options
 - added filtering logic to weed out vlans, etc.
 - sort the networks in numberic order
 - commented out utilization values

=item v1.0   - Jan 07, 2008

 - initial authoring - based on RTG's report.pl

=back

=head1 TODO

Probably: Open a second database connection and dump the results into an SQL table

Done - Abstract many subroutines into a class. Doing so would make it easy to recycle the functions and write a suite of tests. The practical advantages of this have declined since I have integrated many of our RTG functions into this script.

=head1 AUTHOR

Matt Simerson <msimerson@cpan.org>

=head1 ACKNOWLEDGEMENTS

Based on report.pl by Rob Beverly and Adam Rothschild.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 Layered Technologies, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


