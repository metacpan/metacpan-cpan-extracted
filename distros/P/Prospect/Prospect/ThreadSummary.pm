=head1 NAME

Prospect::ThreadSummary - Distilled version of a Prospect::Thread
 
S<$Id: ThreadSummary.pm,v 1.14 2003/11/04 01:01:33 cavs Exp $>

=head1 SYNOPSIS

 my $in  = new IO::File  $ARGV[0]   or die( "can't open $ARGV[0] for reading" );
 my $xml = '';
 while(<$in>) { $xml .= $_; }
 close($in);
  
 my $t = new Prospect::Thread( $xml );
 my $s = new Prospect::ThreadSummary( $t );
  
 print "qname: "     . $s->qname() . "\n";
 print "tname: "     . $s->tname() . "\n";
 print "raw_score: " . $s->raw_score() . "\n";

=head1 DESCRIPTION

Prospect::ThreadSummary -- Distilled version of a Prospect::Thread.  Only
contains score and position information, no sequences or alignments.

=head1 TODO

Integrate exception handling

=cut

package Prospect::ThreadSummary;

use strict;
use Carp;
use Data::Dumper;
use Prospect::Exceptions;

use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/ );


=head1 METHODS

=cut


#-------------------------------------------------------------------------------
# new()
#-------------------------------------------------------------------------------

=head2 new()

 Name:      new()
 Purpose:   return ThreadSummary object
 Arguments: Prospect::Thread
 Returns:   Prospect::ThreadSummary

=cut

sub new {
  my $class = shift;
  my $thread = shift;
  my $self = {};
  bless $self,$class;

  if ( ! defined $thread or ref $thread ne 'Prospect::Thread' ) {
    throw Prospect::BadUsage( { 
      'error'  => 'incorrect argument to new()',
      'detail' => 'Prospect::ThreadSummary::new() requires a Prospect::Thread object as an argument'
    } );
  }

  $self->_init( $thread );

  return( $self );
}


#-------------------------------------------------------------------------------
# qname()
#-------------------------------------------------------------------------------

=head2 qname()

 Name:      qname()
 Purpose:   return the name of the query sequence
 Arguments: none
 Returns:   string

=cut

sub qname { my $self = shift; return $self->{'qname'} }


#-------------------------------------------------------------------------------
# qstart()
#-------------------------------------------------------------------------------

=head2 qstart()

 Name:      qstart()
 Purpose:   return the start of the alignment on the query sequence
 Arguments: none
 Returns:   integer

=cut

sub qstart { my $self = shift; return $self->{'qstart'} }


#-------------------------------------------------------------------------------
# qend()
#-------------------------------------------------------------------------------

=head2 qend()

 Name:      qend()
 Purpose:   return the end of the alignment on the query sequence
 Arguments: none
 Returns:   integer

=cut

sub qend { my $self = shift; return $self->{'qend'} }


#-------------------------------------------------------------------------------
# target_start()
#-------------------------------------------------------------------------------

=head2 target_start()

 Name:      target_start()
 Purpose:   return the start position of the query sequence
 Arguments: none
 Returns:   integer

=cut

sub target_start { my $self = shift; return $self->{'target_start'} }


#-------------------------------------------------------------------------------
# target_end()
#-------------------------------------------------------------------------------

=head2 target_end()

 Name:      target_end()
 Purpose:   return the end position of the query sequence
 Arguments: none
 Returns:   integer

=cut

sub target_end { my $self = shift; return $self->{'target_end'} }


#-------------------------------------------------------------------------------
# tname()
#-------------------------------------------------------------------------------

=head2 tname()

 Name:      tname()
 Purpose:   return the name of the template sequence
 Arguments: none
 Returns:   string

=cut

sub tname { my $self = shift; return $self->{'tname'} }


#-------------------------------------------------------------------------------
# tstart()
#-------------------------------------------------------------------------------

=head2 tstart()

 Name:      tstart()
 Purpose:   return the start of the alignment on the template sequence
 Arguments: none
 Returns:   integer

=cut

sub tstart { my $self = shift; return $self->{'tstart'} }


#-------------------------------------------------------------------------------
# tend()
#-------------------------------------------------------------------------------

=head2 tend()

 Name:      tend()
 Purpose:   return the end of the alignment on the template sequence
 Arguments: none
 Returns:   integer

=cut

sub tend { my $self = shift; return $self->{'tend'} }


#-------------------------------------------------------------------------------
# template_start()
#-------------------------------------------------------------------------------

=head2 template_start()

 Name:      template_start()
 Purpose:   return the start of the alignment on the template sequence.
 Arguments: none
 Returns:   integer

=cut

sub template_start { my $self = shift; return $self->{'template_start'} }


#-------------------------------------------------------------------------------
# template_end()
#-------------------------------------------------------------------------------

=head2 template_end()

 Name:      template_end()
 Purpose:   return the end of the alignment on the template sequence.
 Arguments: none
 Returns:   integer

=cut

sub template_end { my $self = shift; return $self->{'template_end'} }


#-------------------------------------------------------------------------------
# align_len()
#-------------------------------------------------------------------------------

=head2 align_len()

 Name:      align_len()
 Purpose:   length of the alignment
 Arguments: none
 Returns:   integer

=cut

sub align_len { my $self = shift; return $self->{'align_len'} }


#-------------------------------------------------------------------------------
# identities()
#-------------------------------------------------------------------------------

=head2 identities()

 Name:      identities()
 Purpose:   number of identities
 Arguments: none
 Returns:   integer

=cut

sub identities { my $self = shift; return $self->{'identities'} }


#-------------------------------------------------------------------------------
# svm_score()
#-------------------------------------------------------------------------------

=head2 svm_score()

 Name:      svm_score()
 Purpose:   return the svm score
 Arguments: none
 Returns:   float

=cut

sub svm_score { my $self = shift; return $self->{'svm_score'} }


#-------------------------------------------------------------------------------
# raw_score()
#-------------------------------------------------------------------------------

=head2 raw_score()

 Name:      raw_score()
 Purpose:   return the raw score
 Arguments: none
 Returns:   float

=cut

sub raw_score { my $self = shift; return $self->{'raw_score'} }


#-------------------------------------------------------------------------------
# gap_score()
#-------------------------------------------------------------------------------

=head2 gap_score()

 Name:      gap_score()
 Purpose:   return the gap score
 Arguments: none
 Returns:   float

=cut

sub gap_score { my $self = shift; return $self->{'gap_score'} }


#-------------------------------------------------------------------------------
# mutation_score()
#-------------------------------------------------------------------------------

=head2 mutation_score()

 Name:      mutation_score()
 Purpose:   return the mutation score
 Arguments: none
 Returns:   float

=cut

sub mutation_score { my $self = shift; return $self->{'mutation_score'} }


#-------------------------------------------------------------------------------
# ssfit_score()
#-------------------------------------------------------------------------------

=head2 ssfit_score()

 Name:      ssfit_score()
 Purpose:   return the ssfit score
 Arguments: none
 Returns:   float

=cut

sub ssfit_score { my $self = shift; return $self->{'ssfit_score'} }


#-------------------------------------------------------------------------------
# pair_score()
#-------------------------------------------------------------------------------

=head2 pair_score()

 Name:      pair_score()
 Purpose:   return the pairwise score
 Arguments: none
 Returns:   float

=cut

sub pair_score { my $self = shift; return $self->{'pair_score'} }


#-------------------------------------------------------------------------------
# singleton_score()
#-------------------------------------------------------------------------------

=head2 singleton_score()

 Name:      singleton_score()
 Purpose:   return the singletonwise score
 Arguments: none
 Returns:   float

=cut

sub singleton_score { my $self = shift; return $self->{'singleton_score'} }


#-------------------------------------------------------------------------------
# rgyr()
#-------------------------------------------------------------------------------

=head2 rgyr()

 Name:      rgyr()
 Purpose:   return the radius of gyration
 Arguments: none
 Returns:   float

=cut

sub rgyr { my $self = shift; return $self->{'rgyr'} }


#-------------------------------------------------------------------------------
# INTERNAL METHODS: not intended for use outside this module
#-------------------------------------------------------------------------------
                                                                                                                                    
=pod
                                                                                                                                    
=head1 INTERNAL METHODS & ROUTINES
                                                                                                                                    
The following functions are documented for developers' benefit.  THESE
SHOULD NOT BE CALLED OUTSIDE OF THIS MODULE.  YOU'VE BEEN WARNED.
                                                                                                                                    
=cut


#-------------------------------------------------------------------------------
# _init()
#-------------------------------------------------------------------------------

=head2 _init()

 Name:      _init()
 Purpose:   build ThreadSummary object from Thread object
 Arguments: none
 Returns:   none

=cut

sub _init { 
  my $self   = shift; 
  my $thread = shift; 

  $self->{'qname'}           = $thread->qname();
  $self->{'qstart'}          = $thread->qstart();
  $self->{'qend'}            = $thread->qend();
  $self->{'target_start'}    = $thread->target_start();
  $self->{'target_end'}      = $thread->target_end();
  $self->{'tname'}           = $thread->tname();
  $self->{'tstart'}          = $thread->tstart();
  $self->{'tend'}            = $thread->tend();
  $self->{'template_start'}  = $thread->template_start();
  $self->{'template_end'}    = $thread->template_end();
  $self->{'align_len'}       = $thread->align_len();
  $self->{'identities'}      = $thread->identities();
  $self->{'svm_score'}       = $thread->svm_score();
  $self->{'raw_score'}       = $thread->raw_score();
  $self->{'gap_score'}       = $thread->gap_score();
  $self->{'mutation_score'}  = $thread->mutation_score();
  $self->{'ssfit_score'}     = $thread->ssfit_score();
  $self->{'pair_score'}      = $thread->pair_score();
  $self->{'singleton_score'} = $thread->singleton_score();
  $self->{'rgyr'}            = $thread->rgyr();

  return;
}


1;
