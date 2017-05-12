=head1 NAME

Bio::Polloc::Rule::profile - A rule of type profile

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Rule::profile;
use base qw(Bio::Polloc::RuleI);
use strict;
use Bio::Polloc::Polloc::IO;
use Bio::Polloc::LocusI;
use Bio::SeqIO;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

Generic initialization function

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 execute

Runs the search using HMMer

=head3 Arguments

The sequence (-seq) as a Bio::Seq object or a Bio::SeqIO object

=head3 Returns

An array reference populated with L<Bio::Polloc::Locus::repeat> objects

=cut

sub execute {
   my($self,@args) = @_;
   my($seq) = $self->_rearrange([qw(SEQ)], @args);
   
   $self->throw("You must provide a sequence to evaluate the rule", $seq) unless $seq;
   
   # For Bio::SeqIO objects
   if($seq->isa('Bio::SeqIO')){
      my @feats = ();
      while(my $s = $seq->next_seq){
         push(@feats, @{$self->execute(-seq=>$s)})
      }
      return wantarray ? @feats : \@feats;
   }
   
   $self->throw("Illegal class of sequence '".ref($seq)."'", $seq)
   		unless $seq->isa('Bio::Seq');

   # Create the IO master
   my $io = Bio::Polloc::Polloc::IO->new();

   # Search for hmmersearch
   $self->source('hmmer');
   my $hmmer;
   my $path;
   my $bin = "hmmsearch";
   $path = $self->ruleset->value("path") if defined $self->ruleset;
   $self->debug("Searching the $bin binary for $^O");
   if($path){
      $hmmer = $io->exists_exe($path . $bin) unless $hmmer;
   }
   $hmmer = $io->exists_exe($hmmer) unless $hmmer;
   $hmmer or $self->throw("Could not find the i$bin binary", $path);
   
   # Write the sequence
   my($seq_fh, $seq_file) = $io->tempfile;
   close $seq_fh;
   my $seqO = Bio::SeqIO->new(-file=>">$seq_file", -format=>'Fasta');
   $seqO->write_seq($seq);
   
   # Run it
   my @run = ($hmmer);
   my %cmd_args = (	'evalue'=>'-E', 'score'=>'-T',
   			'ince'=>'--incE', 'inct'=>'--incT',
			'incdome'=>'--incdomE', 'incdomt'=>'--incdomT',
			'f1'=>'--F1', 'f2'=>'--F2', 'f3'=>'--F3',
			'domz'=>'--domZ', 'seed'=>'--seed', 'tformat'=>'--tformat',
			'cpu'=>'--cpu');
   for my $k (keys %cmd_args){
      my $v = $self->_search_value($k);
      push @run, $cmd_args{$k}, $v if defined $v;
   }
   my %cmd_flags = (	'acc'=>'--acc',
   			'cut_ga'=>'--cut_ga', 'cut_nc'=>'--cut_nc', 'cut_tc'=>'--cut_tc',
			'max'=>'--max', 'noheuristics'=>'--max', 'nobias'=>'--nobias',
			'nonull2'=>'--nonull2');
   for my $k (keys %cmd_flags){
      my $v = 0+$self->_search_value($k);
      push @run, $cmd_flags{$k} if $v;
   }
   push @run, $self->_search_value('hmm'), $seq_file, "|";
   $self->debug("Running: ".join(" ",@run));
   my $run = Bio::Polloc::Polloc::IO->new(-file=>join(" ",@run));
   my @feats = ();
   while(my $line = $run->_readline){
      # TODO PARSE IT
      if($line =~ m/^ -----------------------------/){
         $ontable = !$ontable;
      }elsif($ontable){
	 chomp $line;
	 #  from   ->       to  :         size    <per.>  [exp.]          err-rate       sequence
	 $line =~ m/^\s+(\d+)\s+->\s+(\d+)\s+:\s+(\d+)\s+<(\d+)>\s+\[([\d\.]+)\]\s+([\d\.]+)\s+([\w\s]+)$/
		or $self->throw("Unexpected line $.",$line,"Bio::Polloc::Polloc::ParsingException");
	 my $id = $self->_next_child_id;
	 push @feats, Bio::Polloc::LocusI->new(
	 		-type=>$self->type, -rule=>$self, -seq=>$seq,
			-from=>$1+0, -to=>$2+0, -strand=>"+",
			-name=>$self->name,
			-id=>(defined $id ? $id : ""),
			-period=>$4+0, -exponent=>$5+0,
			-error=>$6*100 );
      }
   }
   return wantarray ? @feats : \@feats;
}

=head2 stringify_value

Produces a readable string of the rule's value

=cut

sub stringify_value {
   my ($self,@args) = @_;
   my $out = "";
   for my $k (keys %{$self->value}){
      $out.= "$k=>".(defined $self->value->{$k} ? $self->value->{$k} : "")." ";
   }
   return $out;
}


=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _qualify_value

Implements the _qualify_value from the L<Bio::Polloc::RuleI> interface

=head3 Arguments

Value (str or ref-to-hash or ref-to-array).  Mandatory arguments are:

=over

=item -hmm I<str>

Path to the file containing the HMM.

=back

See the documentation of HMMER for detailed description of the arguments mapped
by the followin supported keys:

=over

=item evalue

=item score

=item ince

=item inct

=item incdome

=item incdomt

=item f1

=item f2

=item f3

=item domz

=item seed

=item tformat

=item cpu

=item acc

=item cut_ga

=item cut_nc

=item cut_tc

=item max

=item noheuristics

=item nobias

=item nonull2

=back

=head3 Return

Value (ref-to-hash or undef)

=cut

sub _qualify_value {
   my($self,$value) = @_;
   return unless defined $value;
   if(ref($value) =~ m/hash/i){
      my @arr = %{$value};
      $value = \@arr;
   }
   $value = join(" ", @{$value}) if ref($value) =~ m/array/i;

   $self->debug("Going to parse the value '$value'");
   
   if( $value !~ /^(\s*-\w+\s+[\d\.]+\s*)*$/i){
      $self->warn("Unexpected parameters for the repeat", $value);
      return;
   }
   
   my @args = split /\s+/, $value;
   unless($#args % 2){
      $self->warn("Unexpected (odd) number of parameters", @args);
      return;
   }
   
   my %params = @args;
   return \%params;
}

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   $self->type('pattern');
}

1;
