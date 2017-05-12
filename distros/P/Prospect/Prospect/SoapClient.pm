=head1 NAME

 Prospect::SoapClient -- execute Prospect remotely
 $Id: SoapClient.pm,v 1.11 2003/11/04 01:01:32 cavs Exp $

=head1 SYNOPSIS

 my $in = new Bio::SeqIO( -format=> 'Fasta', '-file' => $ARGV[0] );
 my $po = new Prospect::Options( seq=>1, svm=>1, global_local=>1,
   templates=>['1alu', '1bgc','1eera']);
 my $pf = new Prospect::SoapClient( {options=>$po,host=>'sanitas'} );

 while ( my $s = $in->next_seq() ) {
   my @threads = $pf->thread( $s );
 }

=head1 DESCRIPTION

B<Prospect::SoapClient> is runs Prospect remotely using SOAP as the
protocol.  Communicate to a Prospect::SoapServer process running
on a remote machine.

=head1 ROUTINES & METHODS

=cut

package Prospect::SoapClient;

use base Prospect::Client;

use warnings;
use strict;
use Data::Dumper;
use Prospect::Exceptions;
use Prospect::ThreadSummary;
use Prospect::Thread;
use Prospect::File;
use Prospect::Init;
use SOAP::Lite;
use Digest::MD5;

use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/ );


#-------------------------------------------------------------------------------
# new()
#-------------------------------------------------------------------------------

=head2 new()

 Name:      new()
 Purpose:   constructor
 Arguments: hash reference with following key/value pairs
   options => Prospect::Options object (required)
   host    => hostname of SOAP server (optional)
   port    => port of SOAP server (optional)
 Returns:   Prospect::SoapClient

=cut

sub new() {
  my $self = shift->SUPER::new(@_);

  my $host = $self->{'host'} || $Prospect::Init::SOAP_SERVER_HOST;
  my $port = $self->{'port'} || $Prospect::Init::SOAP_SERVER_PORT;
  $self->{'xmlCacheName'}  = 'xmlCache';   # name of xml file cache

  # get SOAP client
  $self->{'SoapLite'} = SOAP::Lite
    -> uri('http://cavs/Prospect/SoapServer')
    -> proxy("http://$host:$port", options => {compress_threshold =>0});

  # test the client
  my $retval = $self->{'SoapLite'}->ping();

  if ($retval->fault) {
    throw Prospect::RuntimeError(
      "Unable to connect to Prospect SOAP Server at $host:$port. " .
      "Caught fault (code: " . $retval->faultcode . ", msg: " .
      $retval->faultstring 
    );
  }

  return $self;
}


#-------------------------------------------------------------------------------
# thread()
#-------------------------------------------------------------------------------

=head2 thread()

 Name:      thread()
 Purpose:   return a list of Thread objects
 Arguments: Bio::Seq object
 Returns:   list of Prospect::Thread objects

=cut

sub thread($$) {
  my ($self,$s) = @_;

  throw Prospect::BadUsage( "Prospect::SoapClient::thread() missing Bio::Seq argument" ) if
    ( ! defined $s || ref $s ne 'Bio::Seq' );

  # call xml() to get the Prospect xml results.
  $self->xml( $s );

  # get cached xml file
  my $fn = $self->_get_cache_file( Digest::MD5::md5_hex( $s->seq() ), $self->{'xmlCacheName'} );
  if ( ! defined $fn or ! -e $fn ) {
    throw Prospect::RuntimeError(
      "Unable to retrieve xml output file for " . $s->display_id()
    );
  }

  my $pf = new Prospect::File;
  $pf->open( "<$fn" ) || throw Prospect::RuntimeError("$fn: $!\n");

  my @threads;
  while( my $t = $pf->next_thread() ) {
    push @threads,$t;
  }
  return( @threads );
}


#-------------------------------------------------------------------------------
# thread_summary()
#-------------------------------------------------------------------------------

=head2 thread_summary()

 Name:      thread_summary()
 Purpose:   return a list of ThreadSummary objects
 Arguments: Bio::Seq object
 Returns:   list of rospect2::ThreadSummary objects

=cut

sub thread_summary($$) {
  my ($self,$s) = @_;
  my @summary;

  my $retval = $self->{'SoapLite'}->thread_summary( $self->_parseOptions($s) );
  if ($retval->fault) {
    throw Prospect::RuntimeError(
      "Caught fault (code: " . $retval->faultcode . ", msg: " .
      $retval->faultstring 
    );
  }
  return( @{$retval->result} );
}


#-------------------------------------------------------------------------------
# xml()
#-------------------------------------------------------------------------------

=head2 xml()

 Name:      xml()
 Purpose:   return xml string 
 Arguments: Bio::Seq object
 Returns:   string

=cut

sub xml($$) {
  my ($self,$s) = @_;

  throw Prospect::BadUsage( "Prospect::SoapClient::xml() missing Bio::Seq argument" ) if
    ( ! defined $s || ref $s ne 'Bio::Seq' );

  # check the cache if we've already run prospect on this sequence
  # check the cache for a cached file cooresponding to this sequence.
  # if available then return it rather than running prospect
  my $cached = $self->_get_cache_file( Digest::MD5::md5_hex( $s->seq() ), $self->{'xmlCacheName'} );
  if ( defined $cached and -e $cached ) {
    warn("retrieved cache threading info $cached\n") if $ENV{DEBUG};
    return `cat $cached`;
  }

  my $retval = $self->{'SoapLite'}->xml( $self->_parseOptions($s) );
  if ($retval->fault) {
    throw Prospect::RuntimeError(
      "Caught fault (code: " . $retval->faultcode . ", msg: " .
      $retval->faultstring 
    );
  }

  # cache the prospect output 
  my ($fh,$fn) = $self->_tempfile('xml');
  print $fh $retval->result;
  $self->_put_cache_file( Digest::MD5::md5_hex( $s->seq() ), $self->{'xmlCacheName'}, $fn );

  return( $retval->result );
}


#-------------------------------------------------------------------------------
# INTERNAL METHODS: not intended for use outside this module
#-------------------------------------------------------------------------------

=pod
                                                                            
=head1 INTERNAL METHODS & ROUTINES
                                                                            
The following functions are documented for developers' benefit.  THESE
SHOULD NOT BE CALLED OUTSIDE OF THIS MODULE.  YOU'VE BEEN WARNED.
                                                                            
=cut

#-------------------------------------------------------------------------------
# _parseOptions()
#-------------------------------------------------------------------------------

=head2 _parseOprions()

 Name:      _parseOprions()
 Purpose:   parse Prospect::Oprions into an array for the SOAP server
 Arguments: Bio::Seq object
 Returns:   string

=cut

sub _parseOptions {
  my ($self,$seq) = @_;

  my $t;
  if ( defined $self->{'options'}->{'templates'} ) {
    $t = join ' ',@{$self->{'options'}->{'templates'}};
  }
  my @retval = (
    $seq->display_id(),
    $seq->seq(),
    "",
    "",
    $t,
    $self->{'options'}->{'global_local'},
    $self->{'options'}->{'zscore'},
  );
  return( @retval );
}


=pod
                                                                            
=head1 SEE ALSO

B<Prospect::Options>, B<Prospect::File>,
B<Prospect::Client>, B<Prospect::LocalClient>,
B<Prospect::Thread>, B<Prospect::ThreadSummary>

http://www.bioinformaticssolutions.com/

=cut


1;
