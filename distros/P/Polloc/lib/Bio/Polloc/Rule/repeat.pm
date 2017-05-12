=head1 NAME

Bio::Polloc::Rule::repeat - A rule of type repeat

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Rule::repeat;
use base qw(Bio::Polloc::RuleI);
use strict;
use Bio::Polloc::Polloc::IO;
use Bio::Polloc::LocusI;
use Bio::SeqIO;
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

=head2 execute

This is where magic happens.  Translates the parameters of the object into a call to
B<mreps>, and scans the sequence for repeats.

=head2 Arguments

The sequence (C<-seq>) as a L<Bio::Seq> or a L<Bio::SeqIO> object

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
   
   $self->throw("Illegal class of sequence '".ref($seq)."'", $seq) unless $seq->isa('Bio::Seq');

   # Include safe_value parameters
   my $cmd_vars = {};
   for my $p ( qw(RES MINSIZE MAXSIZE MINPERIOD MAXPERIOD EXP ALLOWSMALL WIN) ){
      my $tv = $self->_search_value($p);
      $cmd_vars->{"-" . lc $p} = $tv if defined $tv;
   }
   my $minsim = ($self->_search_value("minsim") || 0)+0;
   my $maxsim = ($self->_search_value("maxsim") || 0)+0;
   $maxsim ||= 100;

   # Create the IO master
   my $io = Bio::Polloc::Polloc::IO->new();

   # Search for mreps
   $self->source('mreps');
   my $mreps = $self->_executable(defined $self->ruleset ? $self->ruleset->value("path") : undef)
   	or $self->throw("Could not find the mreps binary");
   
   # Write the sequence
   my($seq_fh, $seq_file) = $io->tempfile;
   close $seq_fh;
   my $seqO = Bio::SeqIO->new(-file=>">$seq_file", -format=>'Fasta');
   $seqO->write_seq($seq);
   
   # Run it
   my @run = ($mreps);
   push @run, %{$cmd_vars};
   push @run, "-fasta", $seq_file;
   push @run, "2>&1";
   push @run, "|";
   $self->debug("Running: ".join(" ",@run));
   my $run = Bio::Polloc::Polloc::IO->new(-file=>join(" ",@run));
   my $ontable = 0;
   my @feats = ();
   while(my $line = $run->_readline){
      if($line =~ m/^ -----------------------------/){
         $ontable = !$ontable;
      }elsif($ontable){
	 chomp $line;
	 #  from   ->       to  :         size    <per.>  [exp.]          err-rate       sequence
	 $line =~ m/^\s+(\d+)\s+->\s+(\d+)\s+:\s+(\d+)\s+<(\d+)>\s+\[([\d\.]+)\]\s+([\d\.]+)\s+([\w\s]+)$/
		or $self->throw("Unexpected line $.",$line,"Bio::Polloc::Polloc::ParsingException");
	 my $score = 100 - $6*100;
	 next if $score > $maxsim or $score < $minsim;
	 my $id = $self->_next_child_id;
	 my $cons = $self->_calculate_consensus($7);
	 push @feats, Bio::Polloc::LocusI->new(
	 		-type=>$self->type, -rule=>$self, -seq=>$seq,
			-from=>$1+0, -to=>$2+0, -strand=>"+",
			-name=>$self->name,
			-id=>(defined $id ? $id : ""),
			-period=>$4+0, -exponent=>$5+0,
			-error=>$6*100,
			-score=>$score,
			-consensus=>$cons,
			-repeats=>$7);
      }
   }
   $run->close();
   return wantarray ? @feats : \@feats;
}

=head2 stringify_value

Produces a readable string containing the value of the rule.

=cut

sub stringify_value {
   my ($self,@args) = @_;
   my $out = "";
   for my $k (keys %{$self->value}){
      $out.= "$k=>".(defined $self->value->{$k} ? $self->value->{$k} : "")." ";
   }
   return $out;
}

=head2 value

Implements the C<_qualify_value()> from the L<Bio::Polloc::RuleI> interface

=head3 Arguments

Value (str or ref-to-hash or ref-to-array).  The supported keys are:

=over

=item -res I<float>

Resolution (allowed error)

=item -minsize I<int>

Minimum size of the repeat

=item -maxsize I<int>

Maximum size of the repeat

=item -minperiod I<float>

Minimum period of the repeat

=item -maxperiod I<float>

Maximum period of the repeat

=item -exp I<float>

Minimum exponent (number of repeats)

=item -allowsmall I<bool (int)>

If true, allows spurious results

=item -win I<float>

Process by sliding windows of size C<2*n> overlaping by C<n>

=item -minsim I<float>

Minimum similarity percent

=item -maxsim I<float>

Maximum similarity percent

=back

=head3 Return

Value (I<hashref> or C<undef>).

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _calculate_consensus

Attempts to calculate the consensus of the repeat units.

=head3 Arguments

The repetitive sequence with repeat units separated by spaces (I<str>).

=head3 Returns

The consensus sequence (I<str>)

=cut

sub _calculate_consensus {
   my($self,$seq) = @_;
   return unless $seq;
   my $io = Bio::Polloc::Polloc::IO->new();
   my $emma = $io->exists_exe("emma");
   my $cons = $io->exists_exe("cons");
   return "no-emma" unless $emma;
   return "no-cons" unless $cons;
   my ($outseq_fh, $outseq) = $io->tempfile;
   my $i=0;
   print $outseq_fh ">".(++$i)."\n$_\n" for split /\s+/, $seq;
   close $outseq_fh;
   return "err-seq" unless -s $outseq;
   my $outaln = "$outseq.aln";
   my $emmarun = Bio::Polloc::Polloc::IO->new(-file=>"$emma '$outseq' '$outaln' '/dev/null' -auto >/dev/null |");
   while($emmarun->_readline){ print STDERR $_ }
   $emmarun->close();
   unless(-s $outaln){
      unlink $outaln if -e $outaln;
      return "err-aln";
   }
   my $consout = "";
   my $consrun = Bio::Polloc::Polloc::IO->new(-file=>"$cons '$outaln' stdout -auto |");
   while(my $ln = $consrun->_readline){
      chomp $ln;
      next if $ln =~ /^>/;
      $consout .= $ln;
   }
   unlink $outaln;
   $consrun->close();
   $io->close();
   return $consout;
}

=head2 _parameters

=cut

sub _parameters {
   return [qw(RES MINSIZE MAXSIZE MINPERIOD MAXPERIOD EXP ALLOWSMALL WIN MINSIM MAXSIM)];
}

=head2 _executable

Attempts to get the mreps executable.

=cut

sub _executable {
   my($self, $path) = @_;
   my $name = 'mreps';
   my $io = "Bio::Polloc::Polloc::IO";
   $self->debug("Searching the $name binary for $^O");
   # Note the darwin support.  This is because darwin is unable to execute
   # the linux binary (despite its origin)
   my $bin =	$^O =~ /(macos|darwin)/i ? "mreps.macosx.bin" :
   		$^O =~ /mswin/i ? "mreps.exe" :
		"mreps.linux.bin";
   my @where = ('');
   unshift @where, $path if $path;
   for my $p (@where){
   	for my $n (($bin, $name, "$name.bin")){
		my $exe = $io->exists_exe($p . $n);
		return $exe if $exe;
	}
   }
}

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   $self->type('repeat');
}

1;
