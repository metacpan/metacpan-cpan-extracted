#! /usr/bin/perl

#use lib 'lib/' ;

use Nabaztag ;


my $mac = shift ;
my $tok = shift ;

my $left = shift || 0 ;
my $right = shift || 0 ;

my $mess = shift ;

my $nab = Nabaztag->new();
$nab->mac($mac);
$nab->token($tok);
$nab->leftEarPos($left);
$nab->rightEarPos($right);

if( $mess ) {
    
    $nab->sendMessageNumber($mess);
}

$nab->syncState();
