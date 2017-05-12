#!/usr/bin/perl
# Net::IMP::Pattern with mix of packet and streaming data

use strict;
use warnings;
use Net::IMP;
use Net::IMP::Pattern;
use Net::IMP::Debug;

use Test::More tests => 1;
$DEBUG=0; # enable for extensiv debugging

my %config = (
    rx => qr/foo/,
    rxlen => 3,
    action => 'replace',
    actdata => 'bar'
);

my @chunks = (
    [ 'oofoof', IMP_DATA_PACKET ],   # [0..6]
    [ 'oofoof', IMP_DATA_PACKET ],   # [6..12]
    [ 'oofoof', IMP_DATA_STREAM ],   # [12..18]
    [ 'oofoof', IMP_DATA_STREAM ],   # [18..24]
    [ 'oofoof', IMP_DATA_PACKET ],   # [24..30]
);

my $expect = 
    # no concat between packet data and other packets or stream
    "oobarf".          # [0..6]
    "oobarf".          # [6..12]
    # concat of stream data
    "oobarbarbarf".    # [12..24]
    # packet again  
    "oobarf";          # [24..30]

my $analyzer = Net::IMP::Pattern->new_factory(%config);
my $filter = myFilter->new( $analyzer->new_analyzer );

my $out = '';
$filter->in(0,@$_) for @chunks;

ok( $out eq $expect );


package myFilter;
use base 'Net::IMP::Filter';
sub out {
    my ($self,$dir,$data) = @_;
    $out .= $data;
}
