=head1 NAME

Bio::Polloc::Rule::crispr - A rule of type CRISPR

=head1 DESCRIPTION

Runs CRISPRFinder v3 to search CRISPRs

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Rule::crispr;
use base qw(Bio::Polloc::RuleI);
use strict;
use Bio::Polloc::Polloc::IO;
use Bio::Polloc::LocusI;
use Bio::SeqIO;
# For CRISPRFinder:
use Cwd;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

=over

=item 

Generic initialization method.

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 execute

=over

=item 

Runs CRISPRfinder and parses the output.

=item Arguments

=over

=item -seq I<Bio::Seq or Bio::SeqIO obj>

The sequence(s).

=back

=item Returns

An array reference populated with L<Bio::Polloc::Locus::crispr> objects

=back

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

   # Create the IO master
   my $io = Bio::Polloc::Polloc::IO->new();

   # Search for CRISPRFinder
   $self->source('CRISPRFinder');
   my $cf_script;
   if(defined $self->ruleset){
      $cf_script  = $self->_executable($self->ruleset->value("path"));
      $cf_script||= $self->_executable($self->ruleset->value("root"));
      $cf_script||= $self->_executable($self->ruleset->value("crisprfinder"));
   }else{
      $cf_script = $self->_executable;
   }
   $cf_script or $self->throw("Could not find the CRISPRFinder executable");
   
   # Write the sequence
   my($seq_fh, $seq_file) = $io->tempfile(-suffix=>'.fasta'); # required by CRISPRFinder
   close $seq_fh;
   my $seqO = Bio::SeqIO->new(-file=>">$seq_file", -format=>'Fasta');
   $seqO->write_seq($seq);

   # A tmp output directory
   my $out_dir = $io->tempdir();
   
   # Run it
   $self->debug("Sequence file: $seq_file (".(-s $seq_file).")");
   my $cwd = cwd();
   my @run = ($cf_script, $seq_file, "result");
   push @run, "2>&1";
   push @run, "|";
   chdir $out_dir or $self->throw("I can not move myself to the temporal directory: $!", $out_dir);
   $self->debug("Hello from ".cwd());
   $self->debug("Running: ".join(" ",@run));
   my $run = Bio::Polloc::Polloc::IO->new(-file=>join(" ",@run));
   my $gff_output;
   while(my $line = $run->_readline){
      chomp $line;
      if($line =~ m/^GFF results are be in (.*)/){ $gff_output = $1 }
      elsif($line =~ m/^failure: (.*)/){ $self->throw("CRISPRFinder error", $1) }
   }
   $run->close();
   unless (-e $gff_output){
      $self->warn("Unexistent CRISPRFinder GFF output, probably something went wrong");
      return [];
   }

   # Unfortunatelly, CRISPRFinder's GFF contains unsupported fields in the last column,
   # therefore I should not directly import it using Polloc::LocusIO
   $self->debug("Reading GFF at $gff_output");
   my $gff = Bio::Polloc::Polloc::IO->new(-file=>$gff_output);
   my $loci = {};
   while(my $line = $gff->_readline){
      chomp $line;
      next if $line =~ /^#/;
      next if $line =~ /^\s*$/;
      my @f = split /\t/, $line;
      next if $f[2] eq 'PossibleCRISPR' and $self->_search_value("IGNOREPROBABLE");
      my %par = map { split /=/, $_, 2 } split /;/, $f[8];
      if($f[2] =~ /^(?:Possible)?CRISPR$/){
	 my $id = $self->_next_child_id;
	 $loci->{$par{ID}} = {
	    -type=>$self->type, -rule=>$self, -seq=>$seq,
	    -from=>$f[3]+0, -to=>$f[4]+0, -strand=>'.',
	    -name=>$self->name,
	    -id=>(defined $id ? $id : ''),
	    -score=>($f[2] eq 'CRISPR' ? 100 : 50),
	    -dr=>$par{DR}, -spacers_no=>$par{Number_of_spacers},
	    -spacers=>[],
	 };
      }elsif(defined $loci->{$par{Parent}} and $f[2] eq 'CRISPRspacer'){
         push @{$loci->{$par{Parent}}->{-spacers}}, {-from=>$f[3]+0, -to=>$f[4]+0, -raw_seq=>$par{sequence}};
      }
   }
   $gff->close();

   # Clean the mess
   $self->rrmdir('result');
   
   # Back to reality
   chdir $cwd or $self->throw("I can not come back to the previous folder: $!", $cwd);
   $self->debug("Hello from ".cwd());

   # Create loci
   #   This is not directly done above because of the different CWD, which could cause problems
   #   while dynamically loading Bio::Polloc::Locus::crispr from Bio::Polloc::LocusI
   my $out = [];
   for my $locus (values %$loci){
      $self->debug("Creating locus");
      my $L = new Bio::Polloc::LocusI(%$locus);
      for my $s (@{$locus->{-spacers}}){
         $L->add_spacer(%$s);
      }
      push @$out, $L;
   }
   
   return $out;
}

=head2 stringify_value

=over

=item 

Stringifies the requested value

=back

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

=over

=item Arguments

Value (I<str> or I<hashref> or I<arrayref>).  The supported keys are:

=over

=item -ignoreprobable

Should I ignore the I<ProbableCrispr> results?

=back

=item Returns

Value (I<hashref> or C<undef>).

=back

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _parameters

=cut

sub _parameters {
   return [qw(IGNOREPROBABLE)];
}

=head2 _executable

Attempts to find the CRISPRfinder script.

=cut

sub _executable {
   my($self, $path) = @_;
   my $exe;
   my $bin;
   my $name = 'CRISPRFinder';
   my $io = "Bio::Polloc::Polloc::IO";
   $self->debug("Searching the $name binary for $^O");
   my @pre = ('');
   unshift @pre, $path if $path;
   for my $p (@pre){
      # Try first WITH version, to avoid v2
      for my $v (("-v3.1", "-v3", "-v3-LK", '')){
         for my $e (('.pl', '')){
	   for my $n (("CRISPRFinder", "CRISPRfinder", "crisprfinder")){
	      $exe = $io->exists_exe($p . $n . $v . $e);
	      return $exe if $exe;
	   }
	 }
      }
   }
}

=head2 _qualify_value

Implements the C<_qualify_value()> from the L<Bio::Polloc::RuleI> interface

=head2 Return

Value (ref-to-hash or undef)

=cut

sub _qualify_value {
   my($self,$value) = @_;
   unless (defined $value){
      $self->warn("Empty value");
      return;
   }
   if(ref($value) =~ m/hash/i){
      my @arr = %{$value};
      $value = \@arr;
   }
   my @args = ref($value) =~ /array/i ? @{$value} : split/\s+/, $value;
   my $out = {};

   return $out unless defined $args[0];
   if($args[0] !~ /^-/){
      $self->warn("Expecting parameters in the format -parameter value", @args);
      return;
   }
   unless($#args%2){
      $self->warn("Unexpected (odd) number of parameters", @args);
      return;
   }

   my %vals = @args;
   for my $k ( @{$self->_parameters} ){
      my $p = $self->_rearrange([$k], @args);
      next unless defined $p;
      if( $p !~ /^([\d\.eE+-]+|t(rue)?|f(alse)?)$/i ){
         $self->warn("Unexpected value for ".$k, $p);
	 return;
      }
      $out->{"-".lc $k} = $p=~m/^f(alse)$/i ? 0 : $p; # This is because the str 'false' evaluates as true ;-)
   }
   return $out;
}

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   $self->type('CRISPR');
}



1;
