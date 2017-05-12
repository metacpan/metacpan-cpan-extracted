#!/usr/bin/perl

use strict;
use Bio::Polloc::RuleIO 1.0501;
use Bio::Polloc::LocusIO;
use Bio::Polloc::Genome;
use Bio::SeqIO;
use List::Util qw(min max);

use Pod::Usage;

# ------------------------------------------------- METHODS
# Output methods
sub csv_header();
sub csv_line($$);
# Advance methods
sub _advance_proto($$); # file, msg
sub advance_detection($$$$); # loci, genomes, Ngenomes, rule
sub advance_group($$$); # locus1, locus2, Nloci
sub advance_extension($$); # group, Ngroups

# ------------------------------------------------- FILES
my $cnf = shift @ARGV;
our $out = shift @ARGV;
my $buildgroups = shift @ARGV;
$buildgroups = '' if $buildgroups =~ /off/i;
my $extendgroups = shift @ARGV;
$extendgroups = '' if $extendgroups =~ /off/i;
my $summarizegroups = shift @ARGV;
$summarizegroups = '' if $summarizegroups =~ /off/i;
my @names = split ":", shift @ARGV;
my @inseqs = @ARGV;
my $csv = "$out.csv";
my $groupcsv = "$out.group.csv";

pod2usage(1)	unless $cnf
		and $out
		and defined $buildgroups
		and defined $extendgroups
		and defined $summarizegroups
		and $#inseqs>-1;

Bio::Polloc::Polloc::Root->DEBUGLOG(-file=>">$out.log");
Bio::Polloc::Polloc::Root->VERBOSITY(4);

open CSV, ">", $csv or die "I can not create the CSV file '$csv': $!\n";

print CSV &csv_header();


# ------------------------------------------------- READ INPUT
# Configuration
my $ruleIO = Bio::Polloc::RuleIO->new(-format=>'Config', -file=>$cnf);
my $genomes = [];
# Sequences
for my $G (0 .. $#inseqs){
   push @$genomes, Bio::Polloc::Genome->new(-file=>$inseqs[$G], -name=>$names[$G], -id=>$G) }
$ruleIO->genomes($genomes);

# ------------------------------------------------- DETECT VNTRs
my $all_loci = $ruleIO->execute(-advance=>\&advance_detection);
my $gff3_io = Bio::Polloc::LocusIO->new(-file=>">$out.gff");
$gff3_io->write_locus($_) for @{$all_loci->loci};
my $struct = $all_loci->structured_loci; # <- expensive function, call it only once.
for my $gk (0 .. $#$struct){
   for my $locus (@{$struct->[$gk]}){
      print CSV &csv_line($locus, $ruleIO->genomes->[$gk]->name);
   }
}

# ------------------------------------------------- GROUP LOCI
if($buildgroups){
  &_advance_proto("$out.grouping", "grouping");
  print CSV "# Extended features\n" if $extendgroups;
  my $grule = shift @{$ruleIO->grouprules}; # The .bme file only defines 1 GroupRules entity
  open GCSV, ">", $groupcsv or die "I can not create the group CSV file '$groupcsv': $!\n";
  print GCSV "ID";
  print GCSV "\t", $_->name for @{$ruleIO->genomes};
  print GCSV "\tUpstream consensus\tDownstream consensus\tLocus size (Avg/SD) <2>" if $summarizegroups;
  print GCSV "\n";
  open GLIST, ">", "$out.groups" or die "I can not open '$out.group': $!\n";
  $grule->locigroup($all_loci);
  my $groups = $grule->build_groups(-advance=>\&advance_group);
  die "Unable to build groups" unless defined $groups;
  die "Empty groups" unless $#$groups >= 0;
  
  &_advance_proto("$out.extending","extending") if $extendgroups;
  my $procGroups = 0;
  GROUP: for my $group (@$groups){
     print GCSV "Group-".$group->name;
# ------------------------------------------------- EXTEND GROUPS
     if($extendgroups){
	my $ext = $grule->extend($group);
	$gff3_io->write_locus($_) for @{$ext->loci};
	print CSV &csv_line($_, $_->genome->name) for @{$ext->loci};
	$group->add_loci(@{$ext->loci});
	&advance_extension($procGroups+1, $#$groups+1);
     }
# ------------------------------------------------- REPORT GROUPS
     GENOME: for my $genome (@{$ruleIO->genomes}){
	print GCSV "\t";
        MEMBER: for my $member (@{$group->loci}){
	   print GCSV $member->id." " if $genome->name eq $member->genome->name;
	}
     }
     print GLIST $_->id, " " for @{$group->loci};
     print GLIST "\n";
# ------------------------------------------------- SUMMARIZE GROUPS
     if($summarizegroups){
        # Within the table
	$grule->{'_groupextension'} ||= {};
	my $context_size = $grule->{'_groupextension'}->{'-upstream'} || 500;
	my $cons_perc = $grule->{'_groupextension'}->{'-consensusperc'} || 0.8;
	my ($len, $sd) = $group->avg_length;
	$group->fix_strands(-size=>$context_size);
	my $left_aln = $group->align_context(-1, $context_size, 0);
	my $right_aln = $group->align_context(1, $context_size, 0);
	my $within_aln = $group->align_context(0, 0, 0);
	my $left_cons = defined $left_aln ? $left_aln->consensus_string($cons_perc) : '';
	my $right_cons = defined $right_aln ? $right_aln->consensus_string($cons_perc) : '';
	print GCSV "\t$left_cons\t$right_cons\t$len\t$sd";
	# Extra data
	my $sumfile = "$out.Group-".$group->name.".extra";
	open SUM, ">", $sumfile or die "I can not open '$sumfile': $!\n";
	print SUM "ID: Group-".$group->name."\nLoci (".($#{$group->loci}+1)."):";
	print SUM " ", $_->id."(".$_->strand.")" for @{$group->loci};
	print SUM "\nLoci length average: $len\nLoci length standard deviation: $sd\n";
	print SUM "\nUpstream alignment:\n";
	my $alnO = Bio::AlignIO->new(-fh => \*SUM, -format=>'clustalw');
	$alnO->write_aln($left_aln) if defined $left_aln;
	print SUM "\nDownstream alignment:\n";
	$alnO->write_aln($right_aln) if defined $right_aln;
	print SUM "\nLocus alignment:\n";
	$alnO->write_aln($within_aln) if defined $within_aln;
	print SUM "\nDistance matrix:\n\t";
	print SUM $_->id, "\t" for @{$group->loci};
	print SUM "\n";
	for my $i (0 .. $#{$group->loci}){
	   print SUM $group->loci->[$i]->id;
	   for my $j (0 .. $i){
	      print SUM "\t", $group->loci->[$i]->distance(-locus=>$group->loci->[$j]);
	   }
	   print SUM "\n";
	}
	close SUM;
     }
     $procGroups++;
     print GCSV "\n";
  }
  close GCSV;
  close GLIST;
}

&_advance_proto("$csv.done","done");


# ------------------------------------------------- SUB-ROUTINES
sub advance_detection($$$$){
   my($loci, $gF, $gN, $rk) = @_;
   our $out;
   &_advance_proto("$out.nfeats", $loci);
   &_advance_proto("$out.nseqs", "$gF/$gN");
}

sub advance_group($$$){
   my($i,$j,$n) = @_;
   our $out;
   &_advance_proto("$out.ngroups", $i+1);
}

sub advance_extension($$){
   my($i, $n) = @_;
   our $out;
   &_advance_proto("$out.next", "$i/$n");
}

sub _advance_proto($$) {
   my($file, $msg) = @_;
   open ADV, ">", $file or die "I can not open the '$file' file: $!\n";
   print ADV $msg;
   close ADV;
}

sub csv_header() {
   return "ID\tGenome\tSeq\tFrom\tTo\tUnit length\tCopy number\tMismatch percent\tScore\t".
		"Left 500bp\tRight 500bp (rc)\tRepeats\tConsensus/Notes\n";
}
sub csv_line($$) {
   my $f = shift;
   my $n = shift;
   $n||= '';
   my $left = $f->seq->subseq(max(1, $f->from-500), $f->from);
   my $right = Bio::Seq->new(-seq=>$f->seq->subseq($f->to, min($f->seq->length, $f->to+500)));
   $right = $right->revcom->seq;
   my $seq;
   $seq = $f->repeats if $f->can('repeats');
   $seq = $f->seq->subseq($f->from, $f->to) unless defined $seq;
   if(defined $seq and $f->strand eq '-'){
      my $seqI = Bio::Seq->new(-seq=>$seq);
      $seq = $seqI->revcom->seq;
   }
   my $notes = '';
   if($f->can('consensus')){
      $notes = $f->consensus;
   }else{
      $notes = $f->comments if $f->type eq 'extend';
      $notes =~ s/\s*Extended feature\s*/ /i; # <- not really clean, but works ;)
   }
   $notes =~ s/[\n\r]+/ /g;
   return sprintf(
   		"\%s\t\%s\t\%s\t\%d\t\%d\t%.2f\t%.2f\t%.0f%%\t%.2f\t\%s\t\%s\t\%s\t\%s\n",
   		(defined $f->id ? $f->id : ''), $n, $f->seq->display_id,
		$f->from, $f->to, ($f->can('period') ? $f->period : 0),
		($f->can('exponent') ? $f->exponent : 0),
		($f->can('error') ? $f->error : 0), $f->score,
   		$left, $right, $seq, $notes);
}

close CSV;

__END__

=pod

=head1 AUTHOR

Luis M. Rodriguez-R < lmrodriguezr at gmail dot com >

=head1 DESCRIPTION

This script is the core of the VNTRs analysis tool
(L<http://bioinfo-prod.mpl.ird.fr/xantho/utils/#vntrs>).  It requires the C<vntrs.bme>
file, at the C<examples> folder.  Run it with no arguments to check the required parameters.

=head1 LICENSE

This script is distributed under the terms of
I<The Artistic License>.  See LICENSE.txt for details.

=head1 SYNOPSIS

C<perl polloc_vntrs.pl> B<arguments>

The arguments must be in the following order:

=over

=item Configuration

The configuration file (a .bme or .cfg file).

=item Output

Output base, a path to the prefix of the files to be created.

=item Build groups

Any non-empty string to create groups of loci, or empty string
to avoid grouping.  If empty (C<''>), extension and summary are
ignored.

=item Extend groups

Any non-empty string to extend the groups, or empty string to
avoid extension.

=item Summarize groups

Any non-empty string to produce additional summaries per group,
or empty string to avoid summaries.

=item Names

The identifiers (names) of the input genomes in a single string
separated by colons (C<:>).  Alternatively, use an empty string
(C<''>) to use names based on the filename.

=item Inseqs

All the following arguments will be treated as input files.  Each
file is assumed to contain a genome (that can contain one or more
sequence) in [multi-]fasta format.

=back

Run C<perl polloc_vntrs.pl> without arguments to see the help
message.

=head1 SEE ALSO

=over

=item *

L<Bio::Polloc::RuleIO>

=item *

L<Bio::Polloc::Genome>

=item *

L<Bio::Polloc::LocusI>

=item *

L<Bio::Polloc::LocusIO>

=item *

L<Bio::Polloc::LociGroup>

=back

=cut

