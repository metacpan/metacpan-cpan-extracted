=head1 NAME

Bio::Polloc::Rule::pattern - A rule determined by a pattern

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Bio::Polloc::RuleI>

=back

=cut

package Bio::Polloc::Rule::pattern;
use base qw(Bio::Polloc::RuleI);
use strict;
use Bio::SeqIO;
use Bio::Polloc::LocusI;
use Bio::Polloc::Polloc::IO;
use List::Util qw(min max);
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 PUBLIC METHODS

Methods provided by the package

=cut

=head2 new

The basic initialization method

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 execute

Executes the search and returns the loci.

=head3 Arguments

The sequence (C<-seq>) as a L<Bio::Seq> or a L<Bio::SeqIO> object.

=head3 Returns

An array reference populated with L<Bio::Polloc::Locus::pattern> objects.

=cut

sub execute {
   my($self,@args) = @_;
   my($seq) = $self->_rearrange([qw(SEQ)], @args);
   
   $self->throw("You must provide a sequence to evaluate the rule", $seq) unless $seq;
   $self->throw("You must provide an object as sequence", $seq)
   		unless UNIVERSAL::can($seq,'isa');
   
   # For Bio::SeqIO objects
   if($seq->isa('Bio::SeqIO')){
      my @feats = ();
      while(my $s = $seq->next_seq){
         push(@feats, @{$self->execute(-seq=>$s)})
      }
      return wantarray ? @feats : \@feats;
   }

   $self->throw("Illegal class of sequence '".ref($seq)."'", $seq) unless $seq->isa('Bio::Seq');

   my $io = Bio::Polloc::Polloc::IO->new();
   my @cmd = ();
   
   # fuzznuc
   $self->source('fuzznuc');
   my $fuzznuc = $self->_executable(defined $self->ruleset ? $self->ruleset->value('path') : undef)
   	or $self->throw("Could not find the fuzznuc binary");
   push @cmd, $fuzznuc;

   # Input sequence
   my($seq_fh, $seq_file) = $io->tempfile;
   close $seq_fh;
   my $seqO = Bio::SeqIO->new(-file=>">$seq_file", -format=>'Fasta');
   $seqO->write_seq($seq);
   push @cmd, "-sequence", $seq_file;

   # Pattern
   my $pattern = $self->_search_value('pattern');
   $pattern or $self->throw("You must set the pattern using the -pattern key on value()");
   push @cmd, "-pattern", $pattern;

   # Output file
   push @cmd, "-complement", "-auto", "-stdout", "-rformat2", "gff", "2>&1", "|";

   # Run it;
   $self->debug("Running: ".join(" ", @cmd));
   my $run = Bio::Polloc::Polloc::IO->new(-file=>join(" ", @cmd));
   my @loci = ();
   while(my $ln = $run->_readline){
      chomp $ln;
      next if $ln =~ /^#/;
      next if $ln =~ /^\s*$/;
      next if $ln =~ /^Error: Unable to read feature tags data.*/; # not really important
      my @l = split /\t/, $ln;
      my $id = $self->_next_child_id;
      push @loci, Bio::Polloc::LocusI->new(
      			-type=>$self->type,
			-rule=>$self, -seq=>$seq,
			-from=>min($l[3], $l[4]), -to=>max($l[3], $l[4]), # Because of Gff2
			-strand=>$l[6],
			-name=>$self->name,
			-id=>(defined $id ? $id : ""),
			-pattern=>$pattern,
			-score=>$l[5]+0);
   }
   $run->close();
   return \@loci;
}

=head2 stringify_value

Produces a string with the value of the rule.

=cut

sub stringify_value { return "pattern=>" . (shift->_search_value('pattern')) }

=head2 value

=head3 Arguments

A I<str>, I<hashref> or I<arrayref>.  The supported keys are:

=over

=item -pattern I<str>

The pattern to be identified.  For example: C<TAT[TA]AC>.

=back

=head3 Return

Value (hashref or undef).

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _parameters

=cut

sub _parameters { return [qw(PATTERN)] }

=head2 _executable

Gets the executable of fuzznuc.

=cut

sub _executable {
   my($self, $path) = @_;
   my $name = "fuzznuc";
   my $exe;
   my $io = "Bio::Polloc::Polloc::IO";
   $self->debug("Searching for the $name binary for $^O");
   if($path){
      $exe = $io->exists_exe($io->catfile($path, $name)) unless $exe;
   }
   $exe = $io->exists_exe($name) unless $exe;
   return $exe;
}

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   $self->type('pattern');
}

1;
