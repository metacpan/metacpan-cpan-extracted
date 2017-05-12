#!/usr/bin/env perl
use strict;
use warnings;

my @PRINTERS = qw( printer1 printer2 etc );

use SNMP::Simple;

BEGIN {
    eval {
        require Net::Ping;
        require Template;
    };
    die "This script requires Net::Ping and Template, though
they're not listed as SNMP::Simple's dependancies.\n" if $@;
}

use Net::Ping;
use Template;

$ENV{MIBS} = 'Printer-MIB';

my @printer_data = ();
foreach my $host (@PRINTERS) {
    print STDERR "- querying $host...\n";

    my %data = ();

    unless ( Net::Ping->new->ping( $host, 1 ) ) {
        warn "Couldn't ping $host\n";
        next;
    }

    my $s = SNMP::Simple->new(
        DestHost  => $host,
        Community => 'public',
        Version   => 1,
    );
    warn "No session for $host" && next unless $s;

    $data{name}     = $s->get('sysName');
    $data{location} = $s->get('sysLocation');
    $data{status}   = [ $s->get_list('hrPrinterStatus') ]->[0];
    $data{model}    = [ $s->get_list('hrDeviceDescr') ]->[0];

    $data{messages} = $s->get_list('prtConsoleDisplayBufferText');

    $data{lights} = $s->get_named_table(
        status => 'prtConsoleOnTime',
        color  => 'prtConsoleColor',
        name   => 'prtConsoleDescription',
    );
    $data{trays} = $s->get_named_table(
        name   => 'prtInputDescription',
        media  => 'prtInputMediaName',
        status => 'prtInputStatus',
        level  => 'prtInputCurrentLevel',
        max    => 'prtInputMaxCapacity',
    );
    $data{supplies} = $s->get_named_table(
        name        => 'prtMarkerSuppliesMarkerIndex',
        type        => 'prtMarkerSuppliesType',
        description => 'prtMarkerSuppliesDescription',
        level       => 'prtMarkerSuppliesLevel',
        max         => 'prtMarkerSuppliesMaxCapacity',
        units       => 'prtMarkerSuppliesSupplyUnit',
    );

    push @printer_data, \%data;
}

my $tt = Template->new();
$tt->process( \*DATA, { printers => \@printer_data } ) or die $tt->error;

__DATA__
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <meta http-equiv="refresh" content="60; url=http://me/printers.html"/>
    <title>CCIS Printers</title>
    <style type="text/css">
        .okay {
            background: #9f9;
        }
        .warning {
            background: #ff9;
        }
        .alert {
            background: #f99;
        }
        .offline {
            color: #999;
        }
    </style>
</head>
<body>
<table cellpadding="10" cellspacing="0" border="1" align="left">
<tr style="background:#eee">
    <th>Name &amp; Info</th>
    <th>Console</th>
    <th>Status Lights</tt>
    <th>Paper</tt>
    <th>Ink</tt>
</tr>
[% FOREACH printer = printers %]
<tr>
    <td>
        <h2>[% printer.name %]</h2>
        <p>[% printer.model %],<br/>[% printer.location %]</p>
    </td>

    <td style="background:#000;color:#0F0;white-space:nowrap"><code>
    [% FOREACH msg = printer.messages %]
        [% msg %]<br/>
    [% END %]
    </code></td>

    <td>
        <h3>[% printer.status %]</h3>
        <p>
        [% FOREACH light = printer.lights %]
            [% IF light.status %]
                <span style="background:[% light.color %];
                color:black;
                font-weight:bold;">
                    [% light.name %]
                </span>
            [% ELSE %]
                <span class="offline">
                    [% light.name %]
                </span>
            [% END %]
            <br/>
        [% END %]
        </p>
    </td>

    <td>
    [% FOREACH tray = printer.trays %]
        [% IF tray.level <= 0 %]
        <span class="warning">
        [% ELSE %]
        <span class="okay">
        [% END %]
            <em>[% tray.name %]</em>:
            [% tray.media %], [% tray.status %],
            [% tray.level %]/[% tray.max %]
        </span>
        <br/>

    [% END %]
    </td>

    <td>
    [% FOREACH supply = printer.supplies %]
        <em>Supply [% supply.name %]</em>:
        [% supply.type %],
        [% supply.level %]/[% supply.max %] [% supply.units %]
        <br/>
        <small>([% supply.description %])<small>
        <br/>
    [% END %]
    </td>

</tr>
[% END %]
</table>
</body>
</html>

