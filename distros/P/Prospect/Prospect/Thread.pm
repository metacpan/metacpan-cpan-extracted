=head1 NAME

Prospect::Thread - Representation of a Prospect thread.
 
S<$Id: Thread.pm,v 1.26 2003/11/04 01:01:32 cavs Exp $>

=head1 SYNOPSIS

 my $in  = new IO::File  $ARGV[0]   or die( "can't open $ARGV[0] for reading" );
 my $out = new IO::File ">$ARGV[1]" or die( "can't open $ARGV[1] for writing" );
 my $xml = '';
 while(<$in>) { $xml .= $_; }
 close($in);
  
 my $t = new Prospect::Thread( $xml );
  
 print "tseq:  " . $t->tseq() . "\n";
 print "qseq:  " . $t->qseq() . "\n";
 print "raw:   " . $t->raw_score() . "\n";
 print "svm:   " . $t->svm_score() . "\n";
 print "align: " . $t->alignment() . "\n";
 $t->write_xml( $out );
 
 exit(0);

=head1 DESCRIPTION

Prospect::Thread -- Representation of a full Prospect thread
this is really just a set of methods associated with the hash structure
returned by XML::Simple.

=cut


package Prospect::Thread;

use strict;
use Carp;
use XML::Simple;
use IO::String;
use Bio::Structure::IO;
use Bio::Structure::Entry;
use Bio::Symbol::ProteinAlphabet;
use Prospect::Exceptions;
$XML::Simple::PREFERRED_PARSER = 'XML::Parser';

use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.26 $ =~ /(\d+)\.(\d+)/ );


=head1 METHODS

=cut


#-------------------------------------------------------------------------------
# new()
#-------------------------------------------------------------------------------

=head2 new()

 Name:      new()
 Purpose:   return Thread object
 Arguments: Prospect XML string 
 Returns:   Prospect::Thread

=cut

sub new {
  my $class = shift;
  my $self = {};
  bless $self,$class;
  my $xml = shift || undef;
  $self->{'xml'} = $xml if ( defined $xml );

  # store alignment info for threaded_structure support
  $self->{'identities'} = {};
  $self->{'similarities'} = {};
  $self->{'mismatches'} = {};
  $self->{'deletions'} = {};
  $self->{'inserts'} = {};

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

sub qname { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'source'};
}


#-------------------------------------------------------------------------------
# qseq()
#-------------------------------------------------------------------------------

=head2 qseq()

 Name:      qseq()
 Purpose:   return the query sequence
 Arguments: none
 Returns:   string

=cut

sub qseq { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'targetSeq'}->{'seq'};
}


#-------------------------------------------------------------------------------
# qseq_align()
#-------------------------------------------------------------------------------

=head2 qseq_align()

 Name:      qseq_align()
 Purpose:   return the aligned query sequence
 Arguments: none
 Returns:   string

=cut

sub qseq_align { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'alignment'}->{'target'};
}


#-------------------------------------------------------------------------------
# qss()
#-------------------------------------------------------------------------------

=head2 qss()

 Name:      qss()
 Purpose:   return the secondary structure of the aligned query sequence
 Arguments: none
 Returns:   string

=cut

sub qss { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'alignment'}->{'target_ss'};
}


#-------------------------------------------------------------------------------
# qlen()
#-------------------------------------------------------------------------------

=head2 qlen()

 Name:      qlen()
 Purpose:   return the length of the query sequence
 Arguments: none
 Returns:   integer

=cut

sub qlen { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'scoreInfo'}->{'seqLen'};
}


#-------------------------------------------------------------------------------
# qstart()
#-------------------------------------------------------------------------------

=head2 qstart()

 Name:      qstart()
 Purpose:   return the start of the alignment on the query sequence
 Arguments: none
 Returns:   integer

=cut

sub qstart { 
  my $self = shift;
  $self->_parse_xml_file();

  # the qstart is not correctly handled in the xml file.  the value of
  # alignmentInfo->targetFrom is really the start position of the query
  # sequence, which we define as target_start.  we'll calculate the qstart
  # using the gaps inserted into the template sequence alignment (i.e. leading
  # dashes).
  if ( ! defined  $self->{'dom'}->{'alignmentInfo'}->{'qstart'} ) {
    $self->tseq_align() =~ m/^(-+)/;
    my $len = ( defined $1 ) ? length($1) : 0;
    printf STDERR "length: $len\n" if $ENV{DEBUG};
    $self->{'dom'}->{'alignmentInfo'}->{'qstart'} = $self->target_start() + $len;
  }
  return $self->{'dom'}->{'alignmentInfo'}->{'qstart'};
}


#-------------------------------------------------------------------------------
# qend()
#-------------------------------------------------------------------------------

=head2 qend()

 Name:      qend()
 Purpose:   return the end of the alignment on the query sequence
 Arguments: none
 Returns:   integer

=cut

sub qend { 
  my $self = shift;
  $self->_parse_xml_file();

  #  the qend is not defined in the xml.  we'll use the qstart, alignment length,
  # and gaps in the query alignment to calculate the position in the query
  # at the end of the alignment
  if ( ! defined  $self->{'dom'}->{'alignmentInfo'}->{'qend'} ) {
    my $align_len = $self->align_len();
    my $aligned = substr $self->qseq_align(),$self->qstart()-1,$align_len;
    print "qend(): len of aligned: " . length($aligned) . "\n" if $ENV{DEBUG};
    my @gaps = ( $aligned =~ m/-/g );
    print "qend(): number of gaps: " . scalar(@gaps) . "\n" if $ENV{DEBUG};
    $self->{'dom'}->{'alignmentInfo'}->{'qend'} = $self->qstart() - scalar(@gaps) + $align_len - 1;
  }
  return $self->{'dom'}->{'alignmentInfo'}->{'qend'};
}


#-------------------------------------------------------------------------------
# target_start()
#-------------------------------------------------------------------------------

=head2 target_start()

 Name:      target_start()
 Purpose:   return the start position of the query sequence
 Arguments: none
 Returns:   integer

=cut

sub target_start { 
  my $self = shift;
  $self->_parse_xml_file();
  return (1);
}


#-------------------------------------------------------------------------------
# target_end()
#-------------------------------------------------------------------------------

=head2 target_end()

 Name:      target_end()
 Purpose:   return the end position of the query sequence
 Arguments: none
 Returns:   integer

=cut

sub target_end { 
  my $self = shift;
  $self->_parse_xml_file();
  return ($self->{'dom'}->{'scoreInfo'}->{'seqLen'});
}


#-------------------------------------------------------------------------------
# tname()
#-------------------------------------------------------------------------------

=head2 tname()

 Name:      tname()
 Purpose:   return the name of the template sequence
 Arguments: none
 Returns:   string

=cut

sub tname { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'templateName'};
}


#-------------------------------------------------------------------------------
# pdbcode()
#-------------------------------------------------------------------------------

=head2 pdbcode()

 Name:      pdbcode()
 Purpose:   return the PDB id
 Arguments: none
 Returns:   string

=cut

sub pdbcode { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'pdbcode'};
}


#-------------------------------------------------------------------------------
# tseq()
#-------------------------------------------------------------------------------

=head2 tseq()

 Name:      tseq()
 Purpose:   return the template sequence
 Arguments: none
 Returns:   string

=cut

sub tseq { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'templateSeq'}->{'seq'};
}


#-------------------------------------------------------------------------------
# tseq_align()
#-------------------------------------------------------------------------------

=head2 tseq_align()

 Name:      tseq_align()
 Purpose:   return the aligned template sequence
 Arguments: none
 Returns:   string

=cut

sub tseq_align {
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'alignment'}->{'template'};
}


#-------------------------------------------------------------------------------
# tss()
#-------------------------------------------------------------------------------

=head2 tss()

 Name:      tss()
 Purpose:   return the secondary structure of the aligned template sequence
 Arguments: none
 Returns:   string

=cut

sub tss { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'alignment'}->{'template_ss'};
}


#-------------------------------------------------------------------------------
# tlen()
#-------------------------------------------------------------------------------

=head2 tlen()

 Name:      tlen()
 Purpose:   return the length of the template sequence
 Arguments: none
 Returns:   integer

=cut

sub tlen { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'scoreInfo'}->{'tempLen'};
}


#-------------------------------------------------------------------------------
# tstart()
#-------------------------------------------------------------------------------

=head2 tstart()

 Name:      tstart()
 Purpose:   return the start of the alignment on the template sequence.
            CURRENTLY, tstart and template_start are the same. Because the
            template residue numbering is not necessarily sequential (due
            to missing residues in the structure), I would need
            to parse the template xml files to correctly handle the 
            tstart value.  
 Arguments: none
 Returns:   integer

=cut

sub tstart { 
  my $self = shift;
  $self->_parse_xml_file();
  return( $self->template_start() );
}


#-------------------------------------------------------------------------------
# tend()
#-------------------------------------------------------------------------------

=head2 tend()

 Name:      tend()
 Purpose:   return the end of the alignment on the template sequence.
            CURRENTLY, tend and template_start are the same. Because the
            template residue numbering is not necessarily sequential (due
            to missing residues in the structure), I would need
            to parse the template xml files to correctly handle the 
            tend value.  
 Arguments: none
 Returns:   integer

=cut

sub tend { 
  my $self = shift;
  $self->_parse_xml_file();
  return( $self->template_end() );
}


#-------------------------------------------------------------------------------
# template_start()
#-------------------------------------------------------------------------------

=head2 template_start()

 Name:      template_start()
 Purpose:   return the start position of the template sequence
 Arguments: none
 Returns:   integer

=cut

sub template_start { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'alignmentInfo'}->{'templateFrom'};
}


#-------------------------------------------------------------------------------
# target_end()
#-------------------------------------------------------------------------------

=head2 target_end()

 Name:      target_end()
 Purpose:   return the end position of the template sequence
 Arguments: none
 Returns:   integer

=cut

sub template_end { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'alignmentInfo'}->{'templateTo'};
}


#-------------------------------------------------------------------------------
# isGlobal()
#-------------------------------------------------------------------------------

=head2 isGlobal()

 Name:      isGlobal()
 Purpose:   return whether the alignment is global (1) or local (0)
 Arguments: none
 Returns:   integer

=cut

sub is_global { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'settings'}->{'alignmentType'} eq 'global';
}


#-------------------------------------------------------------------------------
# align()
#-------------------------------------------------------------------------------

=head2 raw_align()

 Name:      align()
 Purpose:   return the raw alignment from the prospect output
 Arguments: none
 Returns:   string

=cut

sub raw_align {
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'alignment'}->{'align'};
}


#-------------------------------------------------------------------------------
# align_len()
#-------------------------------------------------------------------------------

=head2 align_len()

 Name:      align_len()
 Purpose:   return the alignment length
 Arguments: none
 Returns:   float

=cut

sub align_len { 
  my ($self) = shift;
  $self->_parse_xml_file();
  return ($self->{'dom'}->{'alignmentInfo'}->{'nalign'});
}


#-------------------------------------------------------------------------------
# identities()
#-------------------------------------------------------------------------------

=head2 identities()

 Name:      identities()
 Purpose:   return the number of identities
 Arguments: none
 Returns:   float

=cut

sub identities { 
  my ($self) = shift;
  $self->_parse_xml_file();
  return ($self->{'dom'}->{'alignmentInfo'}->{'nident'});
}


#-------------------------------------------------------------------------------
# svm_score()
#-------------------------------------------------------------------------------

=head2 svm_score()

 Name:      svm_score()
 Purpose:   get/set the svm score
 Arguments: none
 Returns:   float

=cut

sub svm_score { 
  my ($self,$score) = @_;
  $self->_parse_xml_file();

  if ( defined $score ) {   # acting as a mutator
    $self->{'dom'}->{'scoreInfo'}->{'svmScore'} = $score;
  } else {                  # acting as an accessor
    return $self->{'dom'}->{'scoreInfo'}->{'svmScore'} || 'NA';
  }
}


#-------------------------------------------------------------------------------
# raw_score()
#-------------------------------------------------------------------------------

=head2 raw_score()

 Name:      raw_score()
 Purpose:   return the raw score
 Arguments: none
 Returns:   float

=cut

sub raw_score { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'scoreInfo'}->{'rawScore'};
}


#-------------------------------------------------------------------------------
# gap_score()
#-------------------------------------------------------------------------------

=head2 gap_score()

 Name:      gap_score()
 Purpose:   return the gap score
 Arguments: none
 Returns:   float

=cut

sub gap_score { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'scoreInfo'}->{'gapPenalty'};
}


#-------------------------------------------------------------------------------
# mutation_score()
#-------------------------------------------------------------------------------

=head2 mutation_score()

 Name:      mutation_score()
 Purpose:   return the mutation score
 Arguments: none
 Returns:   float

=cut

sub mutation_score { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'scoreInfo'}->{'mutationScore'};
}


#-------------------------------------------------------------------------------
# ssfit_score()
#-------------------------------------------------------------------------------

=head2 ssfit_score()

 Name:      ssfit_score()
 Purpose:   return the ssfit score
 Arguments: none
 Returns:   float

=cut

sub ssfit_score { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'scoreInfo'}->{'ssfit'};
}


#-------------------------------------------------------------------------------
# pair_score()
#-------------------------------------------------------------------------------

=head2 pair_score()

 Name:      pair_score()
 Purpose:   return the pairwise score
 Arguments: none
 Returns:   float

=cut

sub pair_score { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'scoreInfo'}->{'pairwiseCore'};
}


#-------------------------------------------------------------------------------
# singleton_score()
#-------------------------------------------------------------------------------

=head2 singleton_score()

 Name:      singleton_score()
 Purpose:   return the singletonwise score
 Arguments: none
 Returns:   float

=cut

sub singleton_score { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'scoreInfo'}->{'singletonScore'};
}


#-------------------------------------------------------------------------------
# rgyr()
#-------------------------------------------------------------------------------

=head2 rgyr()

 Name:      rgyr()
 Purpose:   return the radius of gyration
 Arguments: none
 Returns:   float

=cut

sub rgyr { 
  my $self = shift;
  $self->_parse_xml_file();
  return $self->{'dom'}->{'scoreInfo'}->{'radiusOfGyration'};
}


#-------------------------------------------------------------------------------
# alignment()
#-------------------------------------------------------------------------------

=head2 alignment()

 Name:      alignment()
 Purpose:   return the threading alignment as a set of line-wrapped rows.
 Arguments: query tag (optional), template tag (optional), width (optional)
 Returns:   string

=cut

sub alignment {
  my $self = shift;
  my $qtag = shift || 'query';
  my $ttag = shift || 'template';
  my $width = shift || 60;
  $self->_parse_xml_file();
  my $al = $self->{'dom'}->{'alignment'};
  my @tags = ($qtag, 'similarity', $ttag, "$ttag/ss");
  my @seqs = ($al->{target},        # query sequence
        $al->{align},          # alignment decorations
        $al->{template},        # template sequence
        $al->{template_ss});      # template SS
  my $ti = 0;                # index of target sequence

  if (not ref $al->{target_ss}) {
   unshift(@tags, "$qtag/ss");
  unshift(@seqs, $al->{target_ss});
  $ti++;
  }

  @seqs = map {chomp($_);$_;} @seqs;

  my $rv = '';
  my $taglen = 15;
  my $qi = 0;
  my $coord_init = '|%-'.($width-1).'d';
  while ( length($seqs[$ti]) ) {
  # build query coordinate line
  my $ss = substr($seqs[$ti],0,$width);
  my $coords = ' ' x $width;
  for(my ($i,$lti)=(0,undef); $i<length($ss); $i++) {
    next if (substr($ss,$i,1) eq '-');
    $qi++;
    print(STDERR "i=$i qi=$qi") if $ENV{'DEBUG'};
    if (not defined $lti) {
    my $c = sprintf("|%d",$qi);
    my $lc = length($c);
    substr($coords, $i, $lc, $c);
    $lti = $i;
    print(STDERR ": c=$c lc=$lc $coords") if $ENV{'DEBUG'};
    } elsif ( ($qi % 10 == 0) and ($i-$lti >= 9) ) {
    my $c = sprintf("%d|",$qi);
    my $lc = length($c);
    substr($coords, $i-$lc+1, $lc, $c);
    $lti = $i;
    print(STDERR ": lti=$lti c=$c lc=$lc $coords") if $ENV{'DEBUG'};
    }
    print(STDERR "\n") if $ENV{'DEBUG'}
  }
  $rv .= sprintf("%$taglen.${taglen}s $coords\n", 'query pos.');

  for(my $i=0;$i<=$#seqs;$i++) {
    $rv .= sprintf("%$taglen.${taglen}s %s\n",
           $tags[$i],substr($seqs[$i],0,$width,'')); 
  }
  $rv .= "\n" if $seqs[$ti];
  }
  return $rv;
}


#-------------------------------------------------------------------------------
# write_xml()
#-------------------------------------------------------------------------------

=head2 write_xml()

 Name:      write_xml()
 Purpose:   output the xml to a file
 Arguments: IO::File object
 Returns:   none

=cut

sub write_xml {
  my $self = shift;
  my $out = shift;

  $self->_parse_xml_file();

  print $out $self->{'parser'}->XMLout( $self->{'dom'}, 'rootname' => 'threading' );
}


#-------------------------------------------------------------------------------
# output_rasmol_script()
#-------------------------------------------------------------------------------

=head2 output_rasmol_script()

 Name:      output_rasmol_script
 Purpose:   return a rasmol script for displaying a threaded structure
 Arguments: Bio::Structure::IO::Entry object
 Returns:   rasmol script

=cut

sub output_rasmol_script {
  my $self = shift;
  my $struc = shift;

  # transform the pdb structure using the threaded alignment
  $self->thread_structure( $struc );

  my $retval;
  my $stringio = IO::String->new($retval);

  $stringio->print("echo 'Generated by:'\n",
           'echo \'  $Id: Thread.pm,v 1.26 2003/11/04 01:01:32 cavs Exp $\'', "\n", # '
           "echo\n"
          );

  ## generate the alignment and echo it in the RasMol window
  my $alignment = $self->alignment();
  chomp($alignment);
  $alignment =~ s/^.*$/echo '$&'/gm;
  $stringio->print("echo 'Alignment:'\n",
           $alignment, "\n");

  ## color the identities, similarities, mismatches
  ## simultaneously selects/colors and echos the legend
  $stringio->print("load pdb inline\n",    # must load before selecting
           "echo \n",
           "echo 'Legend:'\n",
           "echo '  set names in quotes may be used with select'\n");
  my @select_me;
  if ( @select_me = $self->get_identities() ) {
    my @deco = ('cartoons','color blue');
    $stringio->print( $self->_format_select( @select_me ),
            "define identities selected\n",
            map { "$_\n" } 'wireframe off',@deco );
    $stringio->printf("echo '  %d \"identities\" decorated {%s}'\n",
            $#select_me+1, join(',',@deco));
  }

  if ( @select_me = $self->get_similarities() ) {
    my @deco = ('cartoons','color cyan');
    $stringio->print( $self->_format_select( @select_me ),
            "define similarities selected\n",
            map { "$_\n" } 'wireframe off',@deco );
    $stringio->printf("echo '  %d \"similarities\" decorated {%s}'\n",
            $#select_me+1, join(',',@deco));
  }

  if ( @select_me = $self->get_mismatches() ) {
    my @deco = ('cartoons','color red');
    $stringio->print( $self->_format_select( @select_me ),
            "define mismatches selected\n",
            map { "$_\n" } 'wireframe off',@deco );
    $stringio->printf("echo '  %d \"mismatches\" decorated {%s}'\n",
            $#select_me+1, join(',',@deco));
  }

  if ( @select_me = $self->get_deletions() ) {
    my @deco = ('trace','color grey');
    $stringio->print( $self->_format_select( @select_me ),
            "define deletions selected\n",
            map { "$_\n" } 'wireframe off',@deco );
    $stringio->printf( "echo '  %d query \"deletions\" (template insertions) decorated {%s}'\n",
            $#select_me+1, join(',',@deco) );
  }

  if ( @select_me = $self->get_inserts() ) {
    my @deco = ('strands','color green');
    $stringio->print( $self->_format_select( @select_me ),
            "define insertions selected\n",
            "select selected and *.CA\n",
            map { "$_\n" } 'wireframe off',@deco );
    $stringio->printf( "echo '  %d query \"insertions\" (template deletions) decorated {%s}'\n",
             $#select_me+1, join(',',@deco) );

  # label the inserts
  #wrong: $stringio->printf("echo '  %d inserts at QUERY positions {%s}'\n", 
  #wrong:          $#select_me+1, join(',',@select_me));
  foreach my $ires_i (@select_me) {
    my (@I) = $self->get_inserted_residues($ires_i);
    my $I = join('',@I);
    $I =~ s/\d//g;            # remove residue numbers
    if (length($I) > 20) {
    $I = substr($I,0,10) . ' ... ' . substr($I,-10,10);
    }
    $stringio->printf("select %d and *.CA\nlabel '>%d AA<'\n", $ires_i, $#I+1);
    #okay: $stringio->printf("echo '    %3d AA insert: %s'\n", $#I+1, $I);
  }

  $stringio->print("set fontstroke 1\n",
           "set fontsize 14\n");
  }

  $stringio->print("select CYS\n",
           "color yellow\n",
           "select CYS and identities\n",
           "spacefill\n",
           "echo '  all CYS are yellow; conserved CYS are spacefilled'\n",
           "exit\n");

  my $out = Bio::Structure::IO->new('-fh' => $stringio,
                  '-format' => 'pdb');
  $out->write_structure( $struc );

  return( $retval );
}


#-------------------------------------------------------------------------------
# thread_structure()
#-------------------------------------------------------------------------------

=head2 thread_structure()

 Name:      thread_structure
 Purpose:   modify a Bio::Structure::IO::Entry object to reflect a prospect
            threading alignment
 Arguments: Prospect::Thread object, Bio::Structure::IO::Entry object
 Returns:   nada

=cut

sub thread_structure {
  my $self = shift;
  my $templateStructure = shift;

  my $res;
  my $resname;
  my $resseq;

  my @template_align = split '', $self->tseq_align();
  my @target_align = split '', $self->qseq_align();
  my @alignment = split '', $self->raw_align();

  # better error-handling
  if ( $#template_align != $#target_align ) {
    die("rut-row george (template length != target length)\n");
  }

  my $res_i= 0;
  my $start = $self->tstart();
  my $end = $self->tend();
  foreach my $model ( $templateStructure->get_models( $templateStructure ) ) {
    foreach my $chain ( $templateStructure->get_chains( $model ) ) {
      my @residues = $templateStructure->get_residues( $chain );
      foreach $res ( @residues ) {
        ($resname,$resseq) = split '-', $res->id();
        last if ( $resseq == $start );
        $res_i++;
      }

    for (my $i=0; $i<=$#template_align; $i++) {
        $res = $residues[$res_i];
        ($resname,$resseq) = split '-', $res->id();

        print STDERR "target: $target_align[$i]\n"     if $ENV{'DEBUG'};
        print STDERR "template: $template_align[$i]\n" if $ENV{'DEBUG'};

        if      ( $template_align[$i] eq '-' ) {
      # template insert
          $self->_add_insert( $resseq, "$target_align[$i]$i" );
          print STDERR "found insert\n" if $ENV{'DEBUG'};
          next;
        }
    elsif ( $target_align[$i] eq '-' ) {
      # template deletion
          $self->_add_deletion( $resseq );
          print STDERR "found deletion\n" if $ENV{'DEBUG'};
          $res_i++;
          next;
        }
    elsif ( $target_align[$i] eq $template_align[$i] ) {
      # identity
          if ( $alignment[$i] ne '|' ) {
            throw Prospect::RuntimeError( 
              "thought it was a mismatch but align char is: [$alignment[$i]]\n" );
          }
          $self->_add_identity( $resseq );
          $res_i++;

        } elsif ( $target_align[$i] ne $template_align[$i] ) {
      # mismatch
          if ( $alignment[$i] ne '.' ) {
            $self->_add_similarity( $resseq );
          } else {
            $self->_add_mismatch( $resseq );
          }
          $res->id( $self->_a_to_aaa_code( $target_align[$i] ) . "-$resseq" );
          $res_i++;

        } else {
      # shouldn't happen
          print "ERROR - shouldn't have gotten here\n";
        }

        if (  $self->_a_to_aaa_code( $template_align[$i] ) ne $resname ) {
          throw Prospect::RuntimeError( "ERROR - template (" . 
            $self->_a_to_aaa_code( $template_align[$i] ) . 
            ") not equal to structure ($resname), resseq: $resseq\n" );
        }

        last if ( $resseq == $end );
      }
    }
  }

  return();
}


#-------------------------------------------------------------------------------
# get_mismatches()
#-------------------------------------------------------------------------------

=head2 get_mismatches()

 Name:      get_mismatches
 Purpose:   return array of mismatches
 Argument:  nada
 Returns:   array of residue ids

=cut

sub get_mismatches {
  my $self = shift;

  return( sort { $a <=> $b } keys %{$self->{'mismatches'}} );
}


#-------------------------------------------------------------------------------
# get_similarities()
#-------------------------------------------------------------------------------

=head2 get_similarities()

 Name:      get_similarities
 Purpose:   return array of similarities
 Argument:  nada
 Returns:   array of residue ids

=cut

sub get_similarities {
  my $self = shift;

  return( sort { $a <=> $b } keys %{$self->{'similarities'}} );
}


#-------------------------------------------------------------------------------
# get_deletions()
#-------------------------------------------------------------------------------

=head2 get_deletions()

 Name:      get_deletions
 Purpose:   return array of deletions
 Argument:  nada
 Returns:   array of residue ids

=cut

sub get_deletions {
  my $self = shift;

  return( sort { $a <=> $b } keys %{$self->{'deletions'}} );
}


#-------------------------------------------------------------------------------
# get_inserts()
#-------------------------------------------------------------------------------

=head2 get_inserts()

 Name:      get_inserts
 Purpose:   return array of inserts
 Argument:  nada
 Returns:   array of residue ids

=cut

sub get_inserts {
  my $self = shift;
  return( sort { $a <=> $b } keys %{$self->{'inserts'}} );
}


#-------------------------------------------------------------------------------
# get_inserted_residues()
#-------------------------------------------------------------------------------

=head2 get_inserts()

 Name:      get_inserted_residues
 Purpose:   return identities of inserted residues
 Argument:  position of insert
 Returns:   array of residue ids

=cut

sub get_inserted_residues {
  my $self = shift;
  my $res_i = shift;
  if (exists $self->{inserted}[$res_i])
  { return @{ $self->{inserted}[$res_i] } }
  return ();
}


#-------------------------------------------------------------------------------
# get_identities()
#-------------------------------------------------------------------------------

=head2 get_identities()

 Name:      get_identities
 Purpose:   return array of identities
 Argument:  nada
 Returns:   array of residue ids

=cut

sub get_identities {
  my $self = shift;

  return( sort { $a <=> $b } keys %{$self->{'identities'}} );
}



#-------------------------------------------------------------------------------
# INTERNAL METHODS - not intended for use outside this module
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# _add_similarity()
#-------------------------------------------------------------------------------

=head2 _add_similarity()

 Name:      _add_similarity
 Purpose:   add residue id to list of similarities
 Arguments: residue id
 Returns:   nada

=cut

sub _add_similarity {
  my $self = shift;
  my $resseq = shift;

  print STDERR "push $resseq onto similarity stack\n" if $ENV{'DEBUG'};

  $self->{'similarities'}->{$resseq}++;
}


#-------------------------------------------------------------------------------
# _add_mismatch()
#-------------------------------------------------------------------------------

=head2 _add_mismatch()

 Name:      _add_mismatch
 Purpose:   add residue id to list of mismatches
 Arguments: residue id
 Returns:   nada

=cut

sub _add_mismatch {
  my $self = shift;
  my $resseq = shift;

  print STDERR "push $resseq onto mismatch stack\n" if $ENV{'DEBUG'};

  $self->{'mismatches'}->{$resseq}++;
}


#-------------------------------------------------------------------------------
# _add_deletion()
#-------------------------------------------------------------------------------

=head2 _add_deletion()

 Name:      _add_deletion
 Purpose:   add residue id to list of deletions
 Arguments: residue id
 Returns:   nada

=cut

sub _add_deletion {
  my $self = shift;
  my $resseq = shift;

  print STDERR "push $resseq onto deletion stack\n" if $ENV{'DEBUG'};

  $self->{'deletions'}->{$resseq}++;
}


#-------------------------------------------------------------------------------
# _add_insert()
#-------------------------------------------------------------------------------

=head2 _add_insert($$;@)

 Name:      _add_insert
 Purpose:   add residue id to list of inserts
 Arguments: template residue id at which insert occurs
      optional: inserted query residues
 Returns:   nada

=cut

sub _add_insert {
  my $self = shift;
  my $resseq = shift;

  print STDERR "push $resseq onto insert stack\n" if $ENV{'DEBUG'};

  $self->{'inserts'}->{$resseq}++;

  # remaining args in @_ are the query residues which were inserted
  push(@{$self->{'inserted'}[$resseq]},@_) if (@_);
}


#-------------------------------------------------------------------------------
# _add_identity()
#-------------------------------------------------------------------------------

=head2 _add_identity()

 Name:      _add_identity
 Purpose:   add residue id to list of identities
 Arguments: residue id
 Returns:   nada

=cut

sub _add_identity {
  my $self = shift;
  my $resseq = shift;

  print STDERR "push $resseq onto identity stack\n" if $ENV{'DEBUG'};

  $self->{'identities'}->{$resseq}++;
}


#-------------------------------------------------------------------------------
# _a_to_aaa_code()
#-------------------------------------------------------------------------------

=head2 _a_to_aaa_code()

 Name:      _a_to_aaa_code
 Purpose:   convert a single amino acid code (e.g. W) to its three letter
            amino acid code (e.g. TRP)
 Arguments: single amino acid code
 Returns:   triple amino acid code

=cut

sub _a_to_aaa_code {
  my $self = shift;
  my $a = shift;

  if ( ! defined $self->{'a2aaa'} ) {
    my $alpha = new Bio::Symbol::ProteinAlphabet();
    foreach my $symbol ( $alpha->symbols ) {
      $self->{'a2aaa'}->{ $symbol->token() } = uc( $symbol->name() );
    }
  }
  return( $self->{'a2aaa'}->{$a} );
}


#-------------------------------------------------------------------------------
# _format_select()
#-------------------------------------------------------------------------------

=head2 _format_select()

 Name:      _format_select
 Purpose:   handle the rasmol buffer limit
 Arguments: array of ids to select
 Returns:   rasmol select statement

=cut

sub _format_select {
  my $self = shift;
  my @ids = @_;
  my $bin = 25;
  my $cnt = 0;
  my $retval = '';
    for( my $i=0; $i<=$#ids; $i+=$bin ) {
        my $end = ( $i + $bin < $#ids ) ? $i+$bin-1 : $#ids;
        $retval .= "define TEMP$cnt " . ( join ',', @ids[$i .. $end] ) . "\n";
    $cnt++;
    }
  $retval .= "select " . join(' or ',map { 'TEMP'.$_ } (0..$cnt-1) ) . "\n";
  return( $retval );
}


#-------------------------------------------------------------------------------
# _parse_xml_file()
#-------------------------------------------------------------------------------

=head2 _parse_xml_file()

 Name:      _parse_xml_file()
 Purpose:   parse the input XML file.  
 Arguments: [self]
 Returns:   self

=cut

sub _parse_xml_file {
  my $self = shift;

  # only parse once.  have every accessor method call
  # _parse_xml_file rather than having this method called from the
  # constructor (i.e. only do the xml parse if you need 
  # something from the xml).
  return if defined $self->{'dom'};

  $self->{'parser'} = new XML::Simple;
  my $dom = $self->{'parser'}->XMLin( $self->{'xml'} );
  $self->{'dom'} = $dom;

  # don't store both the dom and xml
  undef $self->{'xml'};

  return $self;
}


1;
