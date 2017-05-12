=head1 NAME

Bio::Polloc::Typing::bandingPattern::amplification - banding-pattern-based
methods for typing assessment using amplification

=head1 DESCRIPTION

Category 1 of genotyping methods in:

  Li, W., Raoult, D., & Fournier, P.-E. (2009).
  Bacterial strain typing in the genomic era.
  FEMS Microbiology Reviews, 33(5), 892-916.

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Bio::Polloc::Typing::bandingPattern>

=back

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Typing::bandingPattern::amplification;
use base qw(Bio::Polloc::Typing::bandingPattern);
use strict;
use Bio::Polloc::Polloc::IO;
use Bio::Polloc::LocusI;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

Generic initialization method

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head1 METHODS FROM Bio::Polloc::TypingI

=head2 scan

=head2 cluster

=head2 typing_value

=head2 graph_content

=head1 METHODS FROM Bio::Polloc::Typing::bandingPattern

=head2 fragments

=cut

sub fragments {
   my($self, @args) = @_;
   my ($locigroup) = $self->_rearrange([qw(LOCIGROUP)], @args);
   defined $locigroup or $self->throw('Trying to amplify fragments, but no loci group provided');
   my $primers = $self->design_primers(-locigroup=>$locigroup);
   return unless defined $primers;
   UNIVERSAL::can($primers, 'isa') and $primers->isa('Bio::Polloc::Polloc::IO')
   		or $self->throw('Wrong primers file', $primers, 'Bio::Polloc::Polloc::UnexpectedException');
   defined $primers->file or $self->throw('Impossible to locate primers temporal file', $primers, 'Bio::Polloc::Polloc::UnexpectedException');
   my $out = Bio::Polloc::LociGroup->new(-genomes=>$locigroup->genomes);
   for my $g (0 .. $#{$locigroup->genomes}){
      next unless defined $locigroup->genomes->[$g]->file;
      my $run = Bio::Polloc::Polloc::IO->new(-file=>"primersearch '".$locigroup->genomes->[$g]->file."' ".
      						"'".$primers->file."' '".$self->annealing_errors."' -auto -stdout |");
      my $amp = [];
      my $k = -1;
      while(my $ln = $run->_readline){
         chomp $ln;
	 if($ln =~ m/^Amplimer (\d+)/){
	    $amp->[$k = $1-1] = Bio::Polloc::LocusI->new(
	    		-type=>'amplicon',
			-primersio=>$primers,
			-genome=>$locigroup->genomes->[$g]);
	 }elsif($ln =~ m/^\s*Sequence: ([^\s]*)\s*/){
	    my $sid=$1;
	    $amp->[$k]->seq($locigroup->genomes->[$g]->search_sequence($sid));
	 }elsif($ln =~ m/^\s*\S+ hits forward strand at (\d+) with (\d+) mismatches/){
	    my($from,$err) = ($1+0, $2+0);
	    $amp->[$k]->from($from);
	    $amp->[$k]->errors($err);
	 }
	 elsif($ln =~ m/^\s*\S+ hits reverse strand at \[(\d+)\] with (\d+) mismatches/){ $amp->[$k]->errors($2 + $amp->[$k]->errors) }
	 elsif($ln =~ m/^\s*Amplimer length: (\d+) bp/){ $amp->[$k]->to($1 + $amp->[$k]->from - 1) }
      }
      $out->add_loci($g, @$amp);
   }
   return $out;
}

=head2 min_size

=head2 max_size

=head1 SPECIFIC METHODS

=head2 design_primers

Designs the primers to amplify all the loci in the group.

=head3 Arguments

=over

=item -locigroup I<Bio::Polloc::LociGroup>

The loci to be amplified.

=back

=head3 Returns

A <Bio::Polloc::Polloc::IO> object pointing to a file containing the primers
designed in the format required by EMBOSS primerseq:

  NAME_1  FWD-SEQ  REV-SEQ
  ...

=cut

sub design_primers {
   my($self,@args) = @_;
   my($locigroup) = $self->_rearrange([qw(LOCIGROUP)], @args);
   defined $locigroup or $self->throw('Trying to design primers, but no loci group provided');
   $locigroup->fix_strands;
   # Align flanking regions
   my $left_aln   = $locigroup->align_context(-1, $self->flanking_size, 0) or return;
   my $right_aln  = $locigroup->align_context(1, $self->flanking_size, 0) or return;
   # Consensus
   my $left_cons  = $left_aln->consensus_string($self->primer_conservation);
   my $right_cons = $right_aln->consensus_string($self->primer_conservation);
   # Conserved region
   my $len = $self->primer_size;
   $left_cons  =~ s/^.*?([^?]{$len}).*$/$1/;
   $right_cons =~ s/^.*?([^?]{$len}).*$/$1/;
   return unless length($left_cons)==$len and length($right_cons)==$len;
   # Reverse complement
   my $uprc   = Bio::Seq->new(-seq=>$left_cons )->revcom->seq;
   my $downrc = Bio::Seq->new(-seq=>$right_cons)->revcom->seq;
   # Output file
   my $io = Bio::Polloc::Polloc::IO->new(-createtemp=>1);
   $io->_print("Polloc   $uprc   $downrc\n");
   return $io;
}

=head2 primer_conservation

Gets/sets the minimum conservation of a region to design primers.  1 by default.

=cut

sub primer_conservation {
   my($self, $value) = @_;
   $self->{'_primer_conservation'} = $value+0 if defined $value;
   return 1 unless defined $self->{'_primer_conservation'};
   return $self->{'_primer_conservation'};
}

=head2 primer_size

Gets/sets the primer size.  20 by default.

=cut

sub primer_size {
   my($self, $value) = @_;
   $self->{'_primer_size'} = $value+0 if defined $value;
   return 20 unless defined $self->{'_primer_size'};
   return $self->{'_primer_size'};
}

=head2 flanking_size

Gets/sets the size of the flanking region to take into account for the
primer design.  500 by default.

=cut

sub flanking_size {
   my($self, $value) = @_;
   $self->{'_flanking_size'} = $value+0 if defined $value;
   return 500 unless defined $self->{'_flanking_size'};
   return $self->{'_flanking_size'};
}

=head2 annealing_errors

Gets/sets the maximum percentage of errors allowed for a primer to anneal.
0 by default.

=cut

sub annealing_errors {
   my($self, $value) = @_;
   $self->{'_annealing_errors'} = $value+0 if defined $value;
   return $self->{'_annealing_errors'} || 0;
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=head2 _initialize_method

=cut

sub _initialize_method {
   my($self,@args) = @_;
   my($primerConservation, $primerSize, $flankingSize, $annealingErrors) =
   	$self->_rearrange([qw(PRIMERCONSERVATION PRIMERSIZE FLANKINGSIZE ANNEALINGERRORS)], @args);
   $self->type('bandingPattern::amplification');
   $self->primer_conservation($primerConservation);
   $self->primer_size($primerSize);
   $self->flanking_size($flankingSize);
   $self->annealing_errors($annealingErrors);
}

1;
