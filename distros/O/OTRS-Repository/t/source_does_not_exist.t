#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use File::Spec;
use File::Basename;

use OTRS::Repository::Source;

$OTRS::Repository::Source::ALLOWED_SCHEME = 'file';

my $base_url = 'file:///pub/otrs/packages/';

my $source = OTRS::Repository::Source->new(
    url     => $base_url . 'otrs.xml',
);

my $master_slave = $source->find( name => 'OTRSMasterSlave', otrs => '3.3' );
is $master_slave, undef, 'MasterSlave for OTRS 3.3';

is $source->error, 'File Not Found', 'error message';

done_testing();
