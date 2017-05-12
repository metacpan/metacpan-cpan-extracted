#! /usr/bin/env perl

#-------------------------------------------------------------------------------
# NAME: Client.pl
# PURPOSE: test script for the Client base object
# USAGE: Client.pl sequence-file
#
# $Id: Client.pl,v 1.7 2003/11/04 15:03:34 rkh Exp $
#-------------------------------------------------------------------------------

use warnings;
use strict;
use Prospect::Client;
use Digest::MD5;
use Bio::SeqIO;

use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.7 $ =~ /(\d+)\.(\d+)/ );


die( "USAGE: Client.pl sequence-file\n" ) if $#ARGV!=0;

my $cacheName = 'seqs';

my $client = new Prospect::Client;
my $io = new Bio::SeqIO( -file => $ARGV[0], -format => 'Fasta' );
while ( my $s = $io->next_seq() ) {
  my ($fh,$fn) = $client->_tempfile('.fa');
  my $key = Digest::MD5::md5_hex( $s->seq() );
  print "MD5 key: $key\n";
  $client->_put_cache_file( $key, $cacheName, $fn );
  print "cached fn: " . $client->_get_cache_file( $key, $cacheName ) . "\n";
}
