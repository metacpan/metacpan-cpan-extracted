#!perl
use strict;
use warnings;

# built-in modules
use English;
use Getopt::Long;

# CPAN modules
use Date::Calc qw(Days_in_Month);
use DBIx::Simple;
use MIME::Lite;
use Net::SMTP;
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
my $email_ref    = $config{'Uplink Email'}{address};
my $smart_host   = $config{Email}{host};
my $networks_ref = $config{'Uplink Networks'}{network};
my $groups_ref   = $config{'Uplink Groups'}{group};

my %networks;
if ( $report->is_arrayref($networks_ref) ) {
    foreach ( @$networks_ref ) {
        my ($net, $db, $cust, $group) = $_ =~ /^\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*$/;
        $networks{$net} = { db=>$db, cust=>$cust, group=>$group };
    };
}
else {
    my ($net, $db, $cust, $group) = $_ =~ /^\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*,\s*(.*)\s*$/;
    $networks{$net} = { db=>$db, cust=>$cust, group=>$group };
}

my %groups;
if ( $report->is_arrayref($groups_ref) ) {
    foreach my $group ( @$groups_ref ) {
        $groups{$group} = { bandwidth => { tot_in => 0, tot_out => 0 } },
    }
}
else {
    $groups{$groups_ref} = { bandwidth => { tot_in => 0, tot_out => 0 } },
}

###########   COMMAND LINE OPTIONS   ###########
my @cli_args = @ARGV;
my %cmd_line_options = (    
    'back=i'  => \my $opt_eom_days,
    'email=s' => \my $opt_email,
    'help'    => \my $opt_help,
    'start=s' => \my $opt_start_day,
    'stop=s'  => \my $opt_end_day,
    'verbose' => \my $debug,
);  
GetOptions(%cmd_line_options);

$debug ? pod2usage({-verbose=>2}) : pod2usage({-verbose=>0}) if $opt_help;
my @emails;
if ( $report->is_arrayref($email_ref) ) { 
    foreach my $email (@$email_ref) { push @emails, $email };
} 
else { @emails = $email_ref; }

###########       DATE VARIABLES     ###########
# if today is less than the Nth day of the month, set date variables 
# to N days ago for a report of the previous month)
my $eom_days  = $opt_eom_days ? $opt_eom_days : 5; 
my $start_day = $opt_start_day ? $opt_start_day : '01';
my $end_day   = $opt_end_day;

# sets up date variables based on today date
my ($dd, $mm, $yy, $lm, $hh, $mn, $ss) = $report->get_the_date();

if ( $opt_eom_days && $dd < $opt_eom_days ) {
    ($dd, $mm, $yy, $lm, $hh, $mn, $ss) = $report->get_the_date($opt_eom_days);
    $end_day = Days_in_Month($yy,$mm) if !$end_day;
}
else {
    if ( !$end_day ) {
        $end_day = sprintf "%02i", $dd -1; # yesterday is the last day 
    };
};

my $start_date = $yy . $mm . $start_day . '000000';   # start and end date
my $end_date   = $yy . $mm . $end_day   . '235959'; 
my $range      = "dtime>$start_date AND dtime<=$end_date"; # sql format
warn "date range: $start_date to $end_date\n" if $debug;

###########   PRINT DEBUGGING INFO   ###########
my $status;
$OUTPUT_AUTOFLUSH++;           # don't buffer screen output
$status .= $report->status( "command line  : $0 " . join(" ", @cli_args ) );
$status .= $report->status( "report period : $yy/$mm/$start_day to $end_day (eom=$eom_days)");
$status .= $report->status( "recipients : " . join(' ', @emails), undef, 1 );



my $db  = DBIx::Simple->connect( $dsn, $db_user, $db_pass) 
            or die "couldn't connect to database: $!\n";

main();
exit;


sub main {

    my $html_report = html_header();

    # get the data from RTG and populate global %networks
    foreach my $pod ( keys %networks ) {
        warn "fetching data for pod $pod:\n" if $debug;

        my $db_name   = $networks{$pod}->{'db'};
        my $port_desc = $networks{$pod}->{'cust'};

        my @interfaces = $db->query(
                "SELECT id,description 
                FROM $db_name.interface 
                WHERE description LIKE '\%$port_desc\%'"  )->hashes;

        get_bandwith_data($pod, $db_name, \@interfaces);
    };

    # summary data for data centers
    $html_report .= html_group_start();
    foreach my $group ( keys %groups ) { $html_report .= html_group_table_row($group) };
    $html_report .= "  </table>";

    # data table for each pod
    foreach my $pod ( sort { substr($a,3) <=> substr($b,3) } keys %networks ) {
        $html_report .= html_pod_table($pod);
    };

    $html_report .= html_footer();

    # output our report to stdout or email
#    print $html_report;
    email_report( $html_report, $status );
};

sub get_bandwith_data {

    my ($pod, $db_name, $interfaces) = @_;

    foreach my $interface (@$interfaces) {

        my $iid = $interface->{'id'};

        my $row = $db->query(
            "SELECT * FROM $db_name.interface WHERE id=$iid" )->hash or die $db->error;

        my $rid      = $row->{'rid'},
        my $if_name  = $row->{'name'},
        my $if_speed = $row->{'speed'};
        my $if_desc  = $row->{'description'};

        # get the router's name/IP 
        my $router_row = $db->query(
            "SELECT rid, name FROM $db_name.router WHERE rid=$rid" )->hash or warn $db->error;
        $networks{$pod}->{'interfaces'}->{$iid}->{'r_name'} = $router_row->{'name'};

        # get the interface stats ( bytes rate_peak rate_avg rate_95th )
        my $in  = $report->get_interface_stats({ db=>$db, iid=>$iid, range=>$range, table=>$db_name.'.ifInOctets_'.$rid  });
        my $out = $report->get_interface_stats({ db=>$db, iid=>$iid, range=>$range, table=>$db_name.'.ifOutOctets_'.$rid });

        # convert numbers from from bit/bytes to Mbit/bytes and limit to 2
        # decimal places of accuracy
        my $bytes_in      = int($in->{'bytes'}/1000000 + .5);
        my $rate_in_avg   = sprintf("%2.0f", $in->{'rate_avg'} /1000000);
        my $rate_in_peak  = sprintf("%2.0f", $in->{'rate_peak'}/1000000);
        my $rate_in_95th  = sprintf("%2.0f", $in->{'rate_95th'}/1000000);

        my $bytes_out     = int($out->{'bytes'}/1000000 + .5);
        my $rate_out_avg  = sprintf("%2.0f", $out->{'rate_avg'} /1000000);
        my $rate_out_peak = sprintf("%2.0f", $out->{'rate_peak'}/1000000);
        my $rate_out_95th = sprintf("%2.0f", $out->{'rate_95th'}/1000000);

        # put interface summaries into global %networks
        $networks{$pod}->{'interfaces'}->{$iid}->{'name'} = $if_name;
        $networks{$pod}->{'interfaces'}->{$iid}->{'speed'} = $if_speed;
        $networks{$pod}->{'interfaces'}->{$iid}->{'description'} = $if_desc;
        $networks{$pod}->{'interfaces'}->{$iid}->{'bandwidth'} =
            {
                rate_in_peak => $rate_in_peak, rate_out_peak => $rate_out_peak,
                rate_in_95th => $rate_in_95th, rate_out_95th => $rate_out_95th,
                rate_in_avg  => $rate_in_avg,  rate_out_avg  => $rate_out_avg,
                bytes_in     => $bytes_in,     bytes_out     => $bytes_out,
            };

        # add interface totals to pod totals
        $networks{$pod}->{'totals'}->{'rate_in_avg'}   += $rate_in_avg;
        $networks{$pod}->{'totals'}->{'rate_out_avg'}  += $rate_out_avg;
        $networks{$pod}->{'totals'}->{'rate_in_95th'}  += $rate_in_95th;
        $networks{$pod}->{'totals'}->{'rate_out_95th'} += $rate_out_95th;
        $networks{$pod}->{'totals'}->{'rate_in_peak'}  += $rate_in_peak;
        $networks{$pod}->{'totals'}->{'rate_out_peak'} += $rate_out_peak;
        $networks{$pod}->{'totals'}->{'bytes_in'}      += $bytes_in;
        $networks{$pod}->{'totals'}->{'bytes_out'}     += $bytes_out;

        # add interface totals to data center totals
        my $group = $networks{$pod}->{'group'};
        $groups{$group}->{'bandwidth'}->{'rate_in_peak'}  += $rate_in_peak;
        $groups{$group}->{'bandwidth'}->{'rate_out_peak'} += $rate_out_peak;
        $groups{$group}->{'bandwidth'}->{'rate_in_95th'}  += $rate_in_95th;
        $groups{$group}->{'bandwidth'}->{'rate_out_95th'} += $rate_out_95th;
        $groups{$group}->{'bandwidth'}->{'rate_in_avg'}   += $rate_in_avg;
        $groups{$group}->{'bandwidth'}->{'rate_out_avg'}  += $rate_out_avg;
        $groups{$group}->{'bandwidth'}->{'bytes_in'}      += $bytes_in;
        $groups{$group}->{'bandwidth'}->{'bytes_out'}     += $bytes_out;
    }
};

sub html_group_start {
    return <<"EODCSTART"
<table>
    <thead>
        <tr>
            <th class="desc" rowspan="2" colspan="2">data center</th>
            <th colspan="2">avg Mbps</th>
            <th colspan="2">95th Mbps</th>
            <th colspan="2">peak Mbps</th>
            <th colspan="2">Total GB</th>
        </tr>
        <tr>
            <th class="rate">in</th>
            <th class="rate">out</th>
            <th class="rate">in</th>
            <th class="rate">out</th>
            <th class="rate">in</th>
            <th class="rate">out</th>
            <th class="bytes">in</th>
            <th class="bytes">out</th>
        </tr>
    </thead>
EODCSTART
;
}

sub html_group_table_row {

    my $group = shift;
    my $bandwidth = $groups{$group}->{'bandwidth'};

    unless ( $bandwidth->{'rate_out_avg'} ) {
        warn "no data for group $group\n";
        return '';
    };

    my $rate_in_avg   = sprintf("%.0f", $bandwidth->{'rate_in_avg'}    );
    my $rate_out_avg  = sprintf("%.0f", $bandwidth->{'rate_out_avg'}   );
    my $rate_in_peak  = sprintf("%.0f", $bandwidth->{'rate_in_peak'}   );
    my $rate_out_peak = sprintf("%.0f", $bandwidth->{'rate_out_peak'}  );
    my $rate_in_95th  = sprintf("%.0f", $bandwidth->{'rate_in_95th'}   );
    my $rate_out_95th = sprintf("%.0f", $bandwidth->{'rate_out_95th'}  );
    my $bytes_in      = sprintf("%.0f", $bandwidth->{'bytes_in'}/1000  );
    my $bytes_out     = sprintf("%.0f", $bandwidth->{'bytes_out'}/1000 );

    return <<"EODC"
    <tr>
        <td colspan="2">$group</td>
        <td class="rate">  $rate_in_avg  </td>
        <td class="rate">  $rate_out_avg </td>
        <td class="rate">  $rate_in_95th </td>
        <td class="rate">  $rate_out_95th</td>
        <td class="rate">  $rate_in_peak </td>
        <td class="rate">  $rate_out_peak</td>
        <td class="bytes"> $bytes_in      </td>
        <td class="bytes"> $bytes_out     </td>
    </tr>
EODC
;
}

sub html_header {

    my $title = "Uplink Report for $mm/$start_day/$yy to $mm/$end_day/$yy";

return <<"EOHTMLHEADER"
<html>
  <head>
    <title> $title </title>
    <link rel="stylesheet" type="text/css" href="/style.css"  />
    <style type="text/css">
h1 {
    text-align: center;
    font-family:arial,sans-serif;
    font-size:14pt;
}
table {
    margin-top: 10px;
    border: 2px solid #000;
    border-collapse: collapse;
    font-family:arial,sans-serif;
    font-size:80%;
}
td,th {
    border: 1px solid #C0C0C0;
    border-collapse: collapse;
    padding:5px;
}
thead tr{
    background:#66CCFF;
}
tfoot td{
    background:#99FFFF;
}
.desc {
    width: 215px;
}
.desc_60 {
    width: 130px;
}
.desc_40 {
    width: 85px;
}
.rate {
    width: 40px;
    text-align: right;
}
.bytes {
    width: 55px;
    text-align: right;
}
#footer {
    margin-top: 10px;
    text-align: center;
}
        </style>
   </head>
   <body>
     <h1> $title </h1>
EOHTMLHEADER
;
}

sub html_footer {

    my $date = `date`;
    return <<"EOFOOTER"
    <div id="footer"> &copy; 2007 Layered Technologies<br>
     Uplink Bandwidth Report (uplink_summary.pl)<br>
     by: Matt Simerson and Jason Morton<br>
     run on $date</div>
  </body>
</html>
EOFOOTER
;
};

sub html_pod_start {
    my $pod = shift;

    return <<"EOPODSTART"
<table>
    <thead>
        <tr>
            <th colspan="2"> $pod </th>
            <th colspan="2">avg Mbps</th>
            <th colspan="2">95th Mbps</th>
            <th colspan="2">peak Mbps</th>
            <th colspan="2">Total GB</th>
        </tr>
        <tr>
            <th class="desc_60">router/port</th>
            <th class="desc_40">description</th>
            <th class="rate">in</th>
            <th class="rate">out</th>
            <th class="rate">in</th>
            <th class="rate">out</th>
            <th class="rate">in</th>
            <th class="rate">out</th>
            <th class="bytes">in</th>
            <th class="bytes">out</th>
        </tr>
    </thead>
EOPODSTART
;
}

sub html_pod_table {

    my $pod = shift;

    my $interfaces = $networks{$pod}->{'interfaces'};

    my $output  = html_pod_start($pod);
       $output .= html_pod_footer($pod);
       $output .= '<tbody>';

    # iterate over each interface, sorted by description
    foreach my $interface ( 
        sort { $interfaces->{$a}->{'description'} 
           cmp $interfaces->{$b}->{'description'} } keys %$interfaces ) {

        my $bandwidth      = $interfaces->{$interface}->{'bandwidth'};
        my $router_name    = $interfaces->{$interface}->{'r_name'};
        my $description    = $interfaces->{$interface}->{'description'};
        my $if_pretty_name = $interfaces->{$interface}->{'name'};
           $if_pretty_name =~ s/GigabitEthernet/gbe/g;

        my $bytes_in_f     = sprintf("%.0f", $bandwidth->{'bytes_in'}/1000);
        my $bytes_out_f    = sprintf("%.0f", $bandwidth->{'bytes_out'}/1000);

        $output .= <<"EOINTERFACE"
        <tr>
            <td> $router_name $if_pretty_name</td>
            <td> $description </td>
            <td class="rate"> $bandwidth->{'rate_in_avg'}  </td>
            <td class="rate"> $bandwidth->{'rate_out_avg'} </td>
            <td class="rate"> $bandwidth->{'rate_in_95th'} </td>
            <td class="rate"> $bandwidth->{'rate_out_95th'}</td>
            <td class="rate"> $bandwidth->{'rate_in_peak'} </td>
            <td class="rate"> $bandwidth->{'rate_out_peak'}</td>
            <td class="bytes"> $bytes_in_f  </td>
            <td class="bytes"> $bytes_out_f </td>
        </tr>
EOINTERFACE
;
    }

    $output .= "  </tbody>\n  </table>\n";
    return $output;
}

sub html_pod_footer {

    my $pod    = shift;
    my $totals = $networks{$pod}->{'totals'};

    my $bytes_in_f  = sprintf("%.0f", $totals->{'bytes_in'}/1000);
    my $bytes_out_f = sprintf("%.0f", $totals->{'bytes_out'}/1000);

return <<"EOPODFOOTER"
  <tfoot>
    <tr>
        <td></td>
        <td>total</td>
        <td class="rate">  $totals->{'rate_in_avg'}  </td>
        <td class="rate">  $totals->{'rate_out_avg'} </td>
        <td class="rate">  $totals->{'rate_in_95th'} </td>
        <td class="rate">  $totals->{'rate_out_95th'}</td>
        <td class="rate">  $totals->{'rate_in_peak'} </td>
        <td class="rate">  $totals->{'rate_out_peak'}</td>
        <td class="bytes"> $bytes_in_f  </td>
        <td class="bytes"> $bytes_out_f </td>
    </tr>
  </tfoot>
EOPODFOOTER
;

}

sub email_report {

    my $html_report = shift;
    my $status = shift;

    my $msg = MIME::Lite->new (
        From    => 'RTG Reporter <no_reply@' . `hostname` . '>',
        To      => shift @emails,
        CC      => join(', ', @emails),
        Subject => "Bandwidth Uplink Report for $mm/$start_day to $mm/$end_day",
        Type    => 'multipart/mixed',
    ) or die "Error creating multipart container: $!\n";
    
    $msg->attach(
        Type    => 'text/html',
        Data    => $html_report,
    );

    $msg->attach(
        Type     => 'TEXT',
        Data     => "\n\n$status\n\n",
    );
    
    $msg->send('smtp', $smart_host );
}


=head1 NAME

uplink_summary.pl - generate and email a pretty HTML formatted report of your ISP uplinks

=head1 VERSION

Version 1.01

=head1 SYNOPSIS

  uplink_summary.pl [-options] [-v]

    available options:
    ------------------------------------------------
    back:       days backwards used to determine reporting period    
    email:      email address to send the report to    
    start/stop: start/end day in DD format    
    help:     display this help page
    verbose:  verbose/debug output


=head1 USAGE

Add to cron:

 # crontab -e
  30 5 1 * * /usr/local/sbin/uplink_summary.pl
  
Or better yet, add to your systems periodic scripts. On FreeBSD, this would be optimal:  

  mkdir -p /usr/local/etc/periodic/weekly && chdir /usr/local/etc/periodic/weekly  
  echo '#!/bin/sh' > uplink_summary.sh  
  echo '/usr/local/sbin/uplink_summary.pl' >> uplink_summary.sh  
  chmod 755 uplink_summary.sh

=head1 OPTIONS 

=over 4

=item B<-back>

The default reporting time period is the first day of the current month until the last complete day of data, yesterday. The exception to this rule is EOM (End of Month) days. If run within 5 days of of the end of the month (ie, the 1-5 of the next month), then the reporting interval is the previous complete month.

This setting allows specification of how many days B<-back> are used when calculating the month to report. To run a report for the previous month when the current day is greater than 5, set B<-back> to a value of todays day plus one.

 Examples: 
  Jan 25th, -back 5, reports Jan 1-24
  Feb 04th, -back 5, reports Jan 1-31
  Feb 10th, -back 5, reports Feb 1-9
  Feb 10th, -back 11, reports Jan 1-31
  Feb 10th, -back 45, reports Dec 1-31

=item B<-email>

The report is automatically emailed to each email address listed in the reporter.conf file. You can optionally specify an email address on the command line that overrides the config file settings.

=item B<-help>

Prints out the pod documentation.

=item B<-start/stop>

If the -back option doesn't provide the exact date range you want, you can optional specify a -start and -end day for the report. This would be useful if you were reporting on a basis other than monthly.

=item B<-verbose>

This billing is designed to run quietly via cron and only generate noise if errors are encountered. The -verbose option prints out status information while processing.

=back


=head1 DESCRIPTION

Generates an uplink report that shows how much traffic each ISP uplink port is utilizing. We run this report weekly and it gives our operations team and executives a high level overview of our network traffic. It also gives us handy reference points to compare and validate the usage our ISPs bill us for. An example is included.


=head1 CONFIGURATION

Configuration and syntax is defined in the rtgreport.conf file. The default location is in /usr/local/etc. See the example configuration file for additional documentation.


=head1 DEPENDENCIES

Uses the following perl built-in modules: English, Getopt::Long

Also uses the following CPAN perl modules: 
Date::Calc, DBIx::Simple, MIME::Lite, Net::SMTP, Config::Std

=head1 CHANGES

=over 4

=item v1.01 - Mar 01, 2008

 - added pod documentation
 - moved config settings into rtgreport.conf
 - renamed dcs to groups (more generally applicable)
 - renamed pods to networks (see above)

=item v1.00 - Dec 14, 2007 - initial authoring

=back


=head1 AUTHOR

Matt Simerson <msimerson@cpan.org> and Jason Morton <jasonm@layeredtech.com>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 Layered Technologies, Inc. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
 
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

