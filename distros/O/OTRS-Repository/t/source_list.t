#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use File::Spec;
use File::Basename;

use OTRS::Repository::Source;

my $xml_file = File::Spec->catfile( dirname( __FILE__ ), 'data', 'otrs.xml' );
my $xml      = do { local (@ARGV, $/) = $xml_file; <> };
my $base_url = 'http://ftp.otrs.org/pub/otrs/packages/';

my $source = OTRS::Repository::Source->new(
    url     => $base_url . 'otrs.xml',
    content => $xml,
);

my @check_list_21 = qw(Calendar FAQ FileManager Support TimeAccounting WebMail);
is_deeply [ $source->list( otrs => '2.1' ) ], \@check_list_21, "list of packages for OTRS 2.1";

my @check_list_all = qw(
    Calendar FAQ FileManager MasterSlave OTRSCodePolicy OTRSMasterSlave
    Support Survey SystemMonitoring TimeAccounting WebMail iPhoneHandle
);
is_deeply [ $source->list ], \@check_list_all, "list of all packages";

done_testing();
