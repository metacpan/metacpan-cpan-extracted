#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use File::Spec;
use File::Spec::Unix;
use File::Basename;

use OPM::Repository::Source;

my $base_url = File::Spec->rel2abs(
  File::Spec->catdir( dirname( __FILE__ ), 'list' ),
);

if ( $^O =~ m{win32}i ) {
    $base_url =~ s{\\}{/}g;
}

my $xml_file = File::Spec::Unix->catfile( $base_url, 'otrs.xml' );

$base_url = 'file://' . $base_url;

my $source = OPM::Repository::Source->new(
    url => 'file://' . $xml_file,
);

my @check_list_21 = map{ $_->{url} =~ s{.*(t/list.*)$}{$1}; $_ }(
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Calendar-1.5.1.opm',
      'name' => 'Calendar',
      'version' => '1.5.1'
    },
    {
      'name' => 'FAQ',
      'version' => '1.0.12',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FAQ-1.0.12.opm'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FAQ-1.0.13.opm',
      'name' => 'FAQ',
      'version' => '1.0.13'
    },
    {
      'version' => '1.2.1',
      'name' => 'FileManager',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FileManager-1.2.1.opm'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.1.12.opm',
      'name' => 'Support',
      'version' => '0.1.12'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.1.13.opm',
      'version' => '0.1.13',
      'name' => 'Support'
    },
    {
      'version' => '0.1.2',
      'name' => 'Support',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.1.2.opm'
    },
    {
      'version' => '0.1.3',
      'name' => 'Support',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.1.3.opm'
    },
    {
      'name' => 'Support',
      'version' => '1.0.98',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.0.98.opm'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.0.99.opm',
      'version' => '1.0.99',
      'name' => 'Support'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.1.1.opm',
      'name' => 'Support',
      'version' => '1.1.1'
    },
    {
      'name' => 'Support',
      'version' => '1.1.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.1.2.opm'
    },
    {
      'name' => 'TimeAccounting',
      'version' => '1.0.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.0.1.opm'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.0.2.opm',
      'name' => 'TimeAccounting',
      'version' => '1.0.2'
    },
    {
      'name' => 'TimeAccounting',
      'version' => '1.0.3',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.0.3.opm'
    },
    {
      'version' => '1.0.4',
      'name' => 'TimeAccounting',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.0.4.opm'
    },
    {
      'name' => 'WebMail',
      'version' => '0.10.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/WebMail-0.10.1.opm'
    },
    {
      'name' => 'WebMail',
      'version' => '0.10.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/WebMail-0.10.2.opm'
    }
);

my @source_list = map{ $_->{url} =~ s{.*(t/list.*)$}{$1}; $_ }$source->list(
    framework => '2.1',
    details   => 1,
);

is_deeply \@source_list, \@check_list_21, "list of packages for OTRS 2.1";

my @check_list_all = map{ $_->{url} =~ s{.*(t/list.*)$}{$1}; $_ }(
    {
      'name' => 'Calendar',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Calendar-1.5.1.opm',
      'version' => '1.5.1'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Calendar-1.7.1.opm',
      'version' => '1.7.1',
      'name' => 'Calendar'
    },
    {
      'name' => 'Calendar',
      'version' => '1.9.4',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Calendar-1.9.4.opm'
    },
    {
      'name' => 'Calendar',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Calendar-1.9.5.opm',
      'version' => '1.9.5'
    },
    {
      'version' => '1.0.12',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FAQ-1.0.12.opm',
      'name' => 'FAQ'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FAQ-1.0.13.opm',
      'version' => '1.0.13',
      'name' => 'FAQ'
    },
    {
      'name' => 'FAQ',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FAQ-1.2.1.opm',
      'version' => '1.2.1'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FAQ-1.2.2.opm',
      'version' => '1.2.2',
      'name' => 'FAQ'
    },
    {
      'version' => '2.2.91',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FAQ-2.2.91.opm',
      'name' => 'FAQ'
    },
    {
      'version' => '2.3.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FAQ-2.3.1.opm',
      'name' => 'FAQ'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FileManager-1.1.7.opm',
      'version' => '1.1.7',
      'name' => 'FileManager'
    },
    {
      'name' => 'FileManager',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FileManager-1.2.1.opm',
      'version' => '1.2.1'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FileManager-1.3.1.opm',
      'version' => '1.3.1',
      'name' => 'FileManager'
    },
    {
      'name' => 'FileManager',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FileManager-1.4.1.opm',
      'version' => '1.4.1'
    },
    {
      'version' => '1.4.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FileManager-1.4.2.opm',
      'name' => 'FileManager'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/FileManager-1.4.3.opm',
      'version' => '1.4.3',
      'name' => 'FileManager'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/MasterSlave-1.0.1.opm',
      'version' => '1.0.1',
      'name' => 'MasterSlave'
    },
    {
      'name' => 'OTRSCodePolicy',
      'version' => '1.0.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/OTRSCodePolicy-1.0.1.opm'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/OTRSCodePolicy-1.0.1.opm',
      'version' => '1.0.1',
      'name' => 'OTRSCodePolicy'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/OTRSCodePolicy-1.0.1.opm',
      'version' => '1.0.1',
      'name' => 'OTRSCodePolicy'
    },
    {
      'name' => 'OTRSMasterSlave',
      'version' => '1.3.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/OTRSMasterSlave-1.3.1.opm'
    },
    {
      'name' => 'Support',
      'version' => '0.0.3',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.0.3.opm'
    },
    {
      'version' => '0.1.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.1.1.opm',
      'name' => 'Support'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.1.12.opm',
      'version' => '0.1.12',
      'name' => 'Support'
    },
    {
      'name' => 'Support',
      'version' => '0.1.12',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.1.12.opm'
    },
    {
      'version' => '0.1.13',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.1.13.opm',
      'name' => 'Support'
    },
    {
      'version' => '0.1.13',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.1.13.opm',
      'name' => 'Support'
    },
    {
      'name' => 'Support',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.1.2.opm',
      'version' => '0.1.2'
    },
    {
      'name' => 'Support',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.1.2.opm',
      'version' => '0.1.2'
    },
    {
      'name' => 'Support',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.1.3.opm',
      'version' => '0.1.3'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-0.1.3.opm',
      'version' => '0.1.3',
      'name' => 'Support'
    },
    {
      'name' => 'Support',
      'version' => '1.0.98',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.0.98.opm'
    },
    {
      'name' => 'Support',
      'version' => '1.0.98',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.0.98.opm'
    },
    {
      'name' => 'Support',
      'version' => '1.0.98',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.0.98.opm'
    },
    {
      'version' => '1.0.98',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.0.98.opm',
      'name' => 'Support'
    },
    {
      'name' => 'Support',
      'version' => '1.0.99',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.0.99.opm'
    },
    {
      'version' => '1.0.99',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.0.99.opm',
      'name' => 'Support'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.0.99.opm',
      'version' => '1.0.99',
      'name' => 'Support'
    },
    {
      'name' => 'Support',
      'version' => '1.0.99',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.0.99.opm'
    },
    {
      'version' => '1.1.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.1.1.opm',
      'name' => 'Support'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.1.1.opm',
      'version' => '1.1.1',
      'name' => 'Support'
    },
    {
      'name' => 'Support',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.1.1.opm',
      'version' => '1.1.1'
    },
    {
      'name' => 'Support',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.1.1.opm',
      'version' => '1.1.1'
    },
    {
      'version' => '1.1.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.1.2.opm',
      'name' => 'Support'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.1.2.opm',
      'version' => '1.1.2',
      'name' => 'Support'
    },
    {
      'name' => 'Support',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.1.2.opm',
      'version' => '1.1.2'
    },
    {
      'name' => 'Support',
      'version' => '1.1.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.1.2.opm'
    },
    {
      'name' => 'Support',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.3.4.opm',
      'version' => '1.3.4'
    },
    {
      'version' => '1.3.5',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.3.5.opm',
      'name' => 'Support'
    },
    {
      'version' => '1.4.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.4.1.opm',
      'name' => 'Support'
    },
    {
      'name' => 'Support',
      'version' => '1.5.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Support-1.5.1.opm'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Survey-1.2.1.opm',
      'version' => '1.2.1',
      'name' => 'Survey'
    },
    {
      'name' => 'Survey',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Survey-1.2.2.opm',
      'version' => '1.2.2'
    },
    {
      'name' => 'Survey',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Survey-1.2.5.opm',
      'version' => '1.2.5'
    },
    {
      'name' => 'Survey',
      'version' => '1.2.91',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Survey-1.2.91.opm'
    },
    {
      'name' => 'Survey',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Survey-1.2.92.opm',
      'version' => '1.2.92'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Survey-1.2.93.opm',
      'version' => '1.2.93',
      'name' => 'Survey'
    },
    {
      'name' => 'Survey',
      'version' => '1.2.94',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Survey-1.2.94.opm'
    },
    {
      'name' => 'Survey',
      'version' => '2.0.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Survey-2.0.1.opm'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/Survey-2.0.2.opm',
      'version' => '2.0.2',
      'name' => 'Survey'
    },
    {
      'name' => 'SystemMonitoring',
      'version' => '1.0.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-1.0.1.opm'
    },
    {
      'name' => 'SystemMonitoring',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-1.0.2.opm',
      'version' => '1.0.2'
    },
    {
      'name' => 'SystemMonitoring',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-1.1.1.opm',
      'version' => '1.1.1'
    },
    {
      'name' => 'SystemMonitoring',
      'version' => '2.0.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.0.1.opm'
    },
    {
      'version' => '2.0.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.0.2.opm',
      'name' => 'SystemMonitoring'
    },
    {
      'name' => 'SystemMonitoring',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.0.3.opm',
      'version' => '2.0.3'
    },
    {
      'name' => 'SystemMonitoring',
      'version' => '2.0.4',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.0.4.opm'
    },
    {
      'name' => 'SystemMonitoring',
      'version' => '2.1.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.1.1.opm'
    },
    {
      'name' => 'SystemMonitoring',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.1.2.opm',
      'version' => '2.1.2'
    },
    {
      'name' => 'SystemMonitoring',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.2.1.opm',
      'version' => '2.2.1'
    },
    {
      'version' => '2.2.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.2.2.opm',
      'name' => 'SystemMonitoring'
    },
    {
      'name' => 'SystemMonitoring',
      'version' => '2.2.91',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.2.91.opm'
    },
    {
      'name' => 'SystemMonitoring',
      'version' => '2.2.92',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.2.92.opm'
    },
    {
      'version' => '2.3.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.3.1.opm',
      'name' => 'SystemMonitoring'
    },
    {
      'version' => '2.4.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.4.1.opm',
      'name' => 'SystemMonitoring'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.4.2.opm',
      'version' => '2.4.2',
      'name' => 'SystemMonitoring'
    },
    {
      'name' => 'SystemMonitoring',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.4.3.opm',
      'version' => '2.4.3'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.5.1.opm',
      'version' => '2.5.1',
      'name' => 'SystemMonitoring'
    },
    {
      'version' => '2.5.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/SystemMonitoring-2.5.2.opm',
      'name' => 'SystemMonitoring'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-0.9.10.opm',
      'version' => '0.9.10',
      'name' => 'TimeAccounting'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.0.1.opm',
      'version' => '1.0.1',
      'name' => 'TimeAccounting'
    },
    {
      'version' => '1.0.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.0.1.opm',
      'name' => 'TimeAccounting'
    },
    {
      'version' => '1.0.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.0.2.opm',
      'name' => 'TimeAccounting'
    },
    {
      'version' => '1.0.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.0.2.opm',
      'name' => 'TimeAccounting'
    },
    {
      'version' => '1.0.3',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.0.3.opm',
      'name' => 'TimeAccounting'
    },
    {
      'name' => 'TimeAccounting',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.0.3.opm',
      'version' => '1.0.3'
    },
    {
      'version' => '1.0.4',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.0.4.opm',
      'name' => 'TimeAccounting'
    },
    {
      'name' => 'TimeAccounting',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.0.4.opm',
      'version' => '1.0.4'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.2.2.opm',
      'version' => '1.2.2',
      'name' => 'TimeAccounting'
    },
    {
      'name' => 'TimeAccounting',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.2.3.opm',
      'version' => '1.2.3'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.2.4.opm',
      'version' => '1.2.4',
      'name' => 'TimeAccounting'
    },
    {
      'name' => 'TimeAccounting',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.2.5.opm',
      'version' => '1.2.5'
    },
    {
      'name' => 'TimeAccounting',
      'version' => '1.3.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.3.1.opm'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.3.2.opm',
      'version' => '1.3.2',
      'name' => 'TimeAccounting'
    },
    {
      'version' => '1.3.3',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.3.3.opm',
      'name' => 'TimeAccounting'
    },
    {
      'name' => 'TimeAccounting',
      'version' => '1.3.91',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.3.91.opm'
    },
    {
      'name' => 'TimeAccounting',
      'version' => '1.3.92',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.3.92.opm'
    },
    {
      'name' => 'TimeAccounting',
      'version' => '1.4.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.4.1.opm'
    },
    {
      'name' => 'TimeAccounting',
      'version' => '1.4.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/TimeAccounting-1.4.2.opm'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/WebMail-0.10.1.opm',
      'version' => '0.10.1',
      'name' => 'WebMail'
    },
    {
      'name' => 'WebMail',
      'version' => '0.10.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/WebMail-0.10.2.opm'
    },
    {
      'name' => 'WebMail',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/WebMail-0.11.1.opm',
      'version' => '0.11.1'
    },
    {
      'name' => 'WebMail',
      'version' => '0.11.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/WebMail-0.11.2.opm'
    },
    {
      'version' => '0.11.3',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/WebMail-0.11.3.opm',
      'name' => 'WebMail'
    },
    {
      'name' => 'WebMail',
      'version' => '0.11.4',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/WebMail-0.11.4.opm'
    },
    {
      'name' => 'WebMail',
      'version' => '0.12.1',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/WebMail-0.12.1.opm'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/WebMail-0.12.2.opm',
      'version' => '0.12.2',
      'name' => 'WebMail'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/WebMail-0.9.10.opm',
      'version' => '0.9.10',
      'name' => 'WebMail'
    },
    {
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/WebMail-0.9.91.opm',
      'version' => '0.9.91',
      'name' => 'WebMail'
    },
    {
      'name' => 'iPhoneHandle',
      'version' => '0.0.2',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/iPhoneHandle-0.0.2.opm'
    },
    {
      'name' => 'iPhoneHandle',
      'url' => 'file:///home/otrsvm/OPM-Repository/.build/t/list/iPhoneHandle-0.0.2.opm',
      'version' => '0.0.2'
    }
);

my @source_list_all = map{ $_->{url} =~ s{.*(t/list.*)$}{$1}; $_ }$source->list(
    details => 1,
);
is_deeply \@source_list_all, \@check_list_all, "list of all packages";

done_testing();
