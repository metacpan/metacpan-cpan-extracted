# $Id: Align.pm,v 1.14 2003/11/07 00:46:09 cavs Exp $
# @@banner@@

=head1 NAME

Prospect::Align -- Package for overlaying multiple Prospect alignments

S<$Id: Align.pm,v 1.14 2003/11/07 00:46:09 cavs Exp $>

=head1 SYNOPSIS

 use Prospect::Options;
 use Prospect::LocalClient;
 use Prospect::Align;
 use Bio::SeqIO;

 my $in = new Bio::SeqIO( -format=> 'Fasta', '-file' => $ARGV[0] );
 my $po = new Prospect::Options( seq=>1, svm=>1, global_local=>1,
                 templates=>[qw(1bgc 1alu 1rcb 1eera)] );
 my $pf = new Prospect::LocalClient( {options=>$po} );

 while ( my $s = $in->next_seq() ) {
   my @threads = $pf->thread( $s );
   my $pa = new Prospect::Align( -debug=>0,-threads => \@threads );
   print $pa->getAlignment(-format=>'html');
 }

=head1 DESCRIPTION

B<Prospect::Align> represents an alignment of one or more
Prospect structural alignments.

=cut


package Prospect::Align;
use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/ );

use strict;
use fields qw( debug threads alignment );
use Carp qw(cluck);
use IO::Scalar;
use Bio::AlignIO;
use Prospect::Init;


=head1 METHODS

=cut


#-------------------------------------------------------------------------------
# new()
#-------------------------------------------------------------------------------

=head2 new()

 Name:       new()
 Purpose:    return Prospect::Align object
 Arguments: 
            -threads => [ Prospect::Thread objects ],
 Returns:   Prospect::Align object

=cut

sub new {
  my $self = fields::new(shift);

  # parse the arguments into a parameter hash
  my %param = @_;
  @param{ map { lc $_ } keys %param } = values %param; # lowercase keys

  # -threads is a required argument, return undef
  # if not supplied
  if ( $param{'-threads'} ) {
    $self->{'threads'} = $param{'-threads'};
  } else {
    return undef;
  }

  if (not defined $ENV{MVIEW_APP}) {
    $ENV{MVIEW_APP} = $Prospect::Init::MVIEW_APP;
    if (not -x $ENV{MVIEW_APP}) {
      throw Prospect::Exception
        ( "MVIEW_APP not set",
        "MVIEW_APP isn't set and $ENV{MVIEW_APP} doesn't exist",
        "MVIEW_APP can be set in the Prospect::Init class or as an environment variable" );
    }
  }

  return $self;
}



#-------------------------------------------------------------------------------
# get_alignment()
#-------------------------------------------------------------------------------

=head2 get_alignment()

 Name:       get_alignment()
 Purpose:    return the sequence alignment of the Prospect::Thread objects
 Arguments:  
             -format => one of: 'clustalw', 'bl2seq','clustalw',
                        'emboss','fasta','mase','mega','meme','msf','nexus',
            'pfam','phylip','prodom','psi','selex','stockholm'
            (default: clustalw)
             -show_ss => output secondard structure (default: off)
       -show_seq => output target sequence (default: on)
 Returns:    scalar containing the alignment

=cut

sub get_alignment {
  my $self = shift;

  my $retval = '';

  # parse the arguments into a parameter hash
  my %param = @_;
  @param{ map { lc $_ } keys %param } = values %param; # lowercase keys

  # the show_ss and show_seq flags are only valid for html and clustalw output 
  # (Bio::AlignIO.pm has some issues when I try them)
  if ( $param{'-show_ss'} && ( $param{'-format'} !~ m/clustalw|html/i ) ) {
    print STDERR "Prospect::Align.pm WARNING: get_alignment() show_ss flag is only valid for " .
                 "-format => clustalw | html - ignoring\n";
    $param{ '-show_ss' } = 0;
  }
  if ( !$param{'-show_seq'} && ( $param{'-format'} !~ m/clustalw|html/i ) ) {
    print STDERR "Prospect::Align.pm WARNING: get_alignment() show_seq flag is only valid for " .
                 "-format => clustalw | html - ignoring\n";
    $param{ '-show_seq' } = 1;
  }

  #
  # get the clustalw alignment if we have not already done so.
  #
  if ( ! defined $self->{'alignment'} ) {
    $self->_align( %param );
  }

  #
  # default is clustalw  because the alignment is internally stored
  # in clustalw format.  utilize Bio::SimpleAln object for other
  # format tyoes
  if ( ! defined $param{'-format'} || $param{'-format'} eq 'clustalw' ) {
    $retval = $self->{'alignment'};
  } elsif ( $param{'-format'} =~ m/html/i ) {
    my @args;
  #push(@args,'-css on');          # sigh... won't work to embed in another html
  push(@args,'-html head');
  push(@args,'-ruler on  -width 60');
  push(@args,'-coloring consensus -threshold 80 -consensus on -con_coloring any');
  $retval = `echo \"$self->{'alignment'}\" | $Prospect::Init::MVIEW_APP -in clustalw -alncolor '#FFFFFF' @args`;
  } elsif ( $param{'-format'} =~ 
  m/bl2seq|clustalw|emboss|fasta|mase|mega|meme|msf|nexus|pfam|phylip|prodom|psi|selex|stockholm/i ) {
    my $in_fh = new IO::Scalar;
    my $out_fh = new IO::Scalar;
    $in_fh->open(\$self->{'alignment'});
    $out_fh->open(\$retval);
    my $in  = Bio::AlignIO->new(-fh => $in_fh , '-format' => 'clustalw');
    my $out = Bio::AlignIO->new(-fh => $out_fh, '-format' => $param{'-format'} );

    while ( my $aln = $in->next_aln() ) {
      $out->write_aln($aln);
    }
    $in_fh->close();
    $out_fh->close();
  } else {
    die( "Prospect::Align.pm ERROR: get_alignment() format ($param{'-format'}) " .
       "not recognized" );
  }
  # [rkh] strip the surrounding table tags
  $retval =~ s%</PRE>\n<TABLE BORDER=0.+<TR><TD>\n<PRE>%\n%;
  $retval =~ s%\n</TD></TR></TABLE>\n%%;
  $retval =~ s%^%<!-- BEGIN Prospect::Align output -->\n%;
  $retval =~ s%$%\n<!-- END Prospect::Align output -->\n%;
  $retval =~ s/^  consensus\/[198].+\n//gm;

  return( $retval );
}

#-------------------------------------------------------------------------------
# get_threads()
#-------------------------------------------------------------------------------

=head2 get_threads()

 Name:       get_threads()
 Purpose:    return the Prospect::Thread object list associated with this object
 Arguments:  none
 Returns:    list of Prospect::Thread objects

=cut

sub get_threads {
  my $self = shift;
  return( @{$self->{'threads'}});
}


#-------------------------------------------------------------------------------
# DEPRECATED METHODS - generally replaced by other methods, will be removed in 
#                      subsequent releases.
#-------------------------------------------------------------------------------

sub getAlignment {
  my $self = shift;
  cluck("getAlignment is deprecated on Oct-22-2003: use get_alignment instead\n");
  return( $self->get_alignment(@_));
}

sub getThreads {
  my $self = shift;
  cluck("getThreads is deprecated on Oct-22-2003: use get_threads instead\n");
  return( $self->get_threads );
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
# _align()
#-------------------------------------------------------------------------------

=head2 _align() 

 Name:       _align()
 Purpose:    private method that does the alignment work - called by new().
             Builds a clustalw alignment internally.  use get_alignment() to
             retrieve the alignment in other formats.
 Arguments:  
             -show_ss => 0 | 1 output secondard structure (default: off)
       -show_seq => 0 | 1  output target sequence (default: on)
 Returns:    nothing

=cut

sub _align {
  my $self = shift;

  #
  # parse the arguments into a parameter hash
  #
  my %param = @_;
  @param{ map { lc $_ } keys %param } = values %param; # lowercase keys

  my @threads = @{$self->{'threads'}};

  #
  # define defaults
  #
  $param{ '-show_ss' }  = 0 if ! defined $param{ '-show_ss' };
  $param{ '-show_seq' } = 1 if ! defined $param{ '-show_seq' };

  # alignment algorithm:
  #   1. the ungapped query sequence is the universal coordinate system
  #   2. gaps inserted into the query sequence as a result of
  #      an alignment to a template, must be reflected in the
  #      alignments of the templates

  my %query_gap;    # store the number of gaps inserted by a given alignment and residue number
  my %max_gap;      # store the largest gap in all the alignments prior to each residue
  my @template;
  my @ss;

  # store an ungapped alignment
  my @ungapped_query = grep ! /-/, split '', $threads[0]->qseq_align();

  # iterate through each alignment and count the gaps inserted prior
  # to each residue and which template alignment inserted that gap.
  my $res_num = 0;
  for (my $i=0;$i<=$#threads;$i++) {

    # store target sequence
    $template[$i] = [ split '', $threads[$i]->tseq_align() ];

    # store the secondary structure information (this is based on the
    # gapped template sequence)
    $ss[$i] = [ split '', $threads[$i]->tss() ];

    $res_num = 0;
    my @query = split //,$threads[$i]->qseq_align();
    for( my $j=0; $j<=$#query; $j++ ) {
      if ( $query[$j] eq '-' ) {  # found gap
        $query_gap{$res_num}{$i}++;
      } else {                    # if no gap, then increment the residue number
        $res_num++;
      }
    }
  }

  # sanity check on query_res_count using the ungapped query aligment

  # build consensus query sequence by applying the maximium number of gaps
  # prior to each residue
  my $consensus_str = '';
  for (my $res_num=0; $res_num<=$#ungapped_query; $res_num++) {
    if ( defined $query_gap{$res_num} ) {
      foreach my $t ( sort { 
        $query_gap{$res_num}{$b} <=> $query_gap{$res_num}{$a} } 
        keys %{$query_gap{$res_num}} ) {
          $max_gap{$res_num} = $query_gap{$res_num}{$t};
          $consensus_str .= ( '-'x$max_gap{$res_num} );
        last;
      }
    }
    $consensus_str .= $ungapped_query[$res_num];
  }

  # Iterate through each template alignment.  Fix the template alignments by 
  # inserting the difference between the maximium number of gap inserts for the
  # corresponding query residue and the gap inserts for this template alignment.
  for (my $i=0;$i<=$#threads;$i++) {
    my $res_num = 0;
    my $gaps_inserted=0;
    my @query = split //,$threads[$i]->qseq_align();
    for( my $j=0; $j<=$#query; $j++ ) {
      if ( $query[$j] ne '-' ) {
        my $gap_length = ( defined $query_gap{$res_num}{$i} ) ? $max_gap{$res_num} - $query_gap{$res_num}{$i} : $max_gap{$res_num};
        if ( defined $gap_length && $gap_length > 0 ) {
          # account for the fact that we have already added some gaps into template and ss
          my $ins_pos = $j+$gaps_inserted;   
          print STDERR "insert $gap_length at the $res_num th residue into the $i sequence at the $ins_pos th position\n" if $ENV{'DEBUG'};
          print STDERR "template:  " . join('',@{$template[$i]}),"\n" if $ENV{'DEBUG'};
          for ( my $k=0; $k<$gap_length; $k++ ) {
            splice(@{$ss[$i]},       $ins_pos, 0, '-' );  
            splice(@{$template[$i]}, $ins_pos, 0, '-' );
            $gaps_inserted++;
          }
          print STDERR "template:  " . join('',@{$template[$i]}),"\n" if $ENV{'DEBUG'};
        }
        $res_num++;
      }
    }
  }

  my @consensus = split //,$consensus_str;
  print STDERR "consensus: " . join('',@consensus) . "\n"  if $ENV{'DEBUG'};

  # sanity check
  for(my $i=0;$i<=$#template;$i++) {
    if ( scalar(@{$template[$i]} != $#consensus+1 )) {
      warn("Prospect::Align.pm ERROR: template length(" . 
        scalar(@{$template[$i]}) .") != query length (" .  ($#consensus+1) . ")\n");
    }
  }

  # build clustalw alignment
  my $offset = 60;
  my $align = "CLUSTAL W(1.81) multiple sequence alignment\n\n\n";
  for (my $start=0; $start<=$#consensus; $start+=($offset)) {
    my $end = ( $start + $offset - 1 ) < $#consensus ? $start + $offset - 1: $#consensus;
    $align .= sprintf("%-22s %s\n","QUERY",join('',@consensus[$start..$end]));
    for (my $i=0; $i<=$#template; $i++) {
      $align .= sprintf("%-22s %s\n",$threads[$i]->tname(),join('',@{$template[$i]}[$start..$end])) 
        if $param{'-show_seq'};
      $align .= sprintf("%-22s %s\n",'#ss-' . $threads[$i]->tname(),join('',@{$ss[$i]}[$start..$end])) 
        if $param{'-show_ss'};
    }
    $align .= "\n";
  }

  $self->{'alignment'} = $align;

  return;
}


1;


=head1 SEE ALSO

@@banner@@

=cut
