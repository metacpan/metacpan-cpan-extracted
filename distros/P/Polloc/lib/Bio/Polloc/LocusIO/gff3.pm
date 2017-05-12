=head1 NAME

Bio::Polloc::LocusIO::gff3 - A LocusIO for Gff3

=head1 DESCRIPTION

A repeatitive locus.

=head1 IMPLEMENTS OR EXTENDS

=over

=item *

L<Bio::Polloc::LocusIO>

=back

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::LocusIO::gff3;
use base qw(Bio::Polloc::LocusIO);
use strict;
use Bio::Polloc::LociGroup;
use Bio::Polloc::LocusI;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

Creates a B<Bio::Polloc::LocusIO::gff3> object.

=head3 Returns

A L<Bio::Polloc::LocusIO::gff3> object.

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 gff3_line

Formats the locus as a GFF3 line and returns it.

=head3 Arguments	

=over

=item -force

Boolean (1 or 0)

=back

=head3 Returns

The GFF3-formatted line (str)
=head3 Note

This function stores the line in cache.  If it is called twice, the second
time will return the cached line unless the C<-force=>1> flag is passed.

=cut

sub gff3_line {
   my($self,@args) = @_;
   my($locus, $force) = $self->_rearrange([qw(LOCUS FORCE)], @args);
   defined $locus and UNIVERSAL::can($locus, 'isa') and $locus->isa('Bio::Polloc::LocusI')
   	or $self->throw("Undefined locus or bad type", $locus);
   return $locus->{'_gff3_line'} if defined $locus->{'_gff3_line'} and not $force;
   my @out;
   push @out, defined $locus->seq_name ? $locus->seq_name : ".";
   $out[0] =~ s/^>/{{%}}3E/;
   push @out, $locus->source; #defined $locus->rule ? $locus->rule->source : 'bme';
   push @out, $locus->family;
   push @out, $locus->from , $locus->to;
   push @out, defined $locus->score ? $locus->score : ".";
   push @out, $locus->strand, "0";
   my %atts;
   $atts{'ID'} = $locus->id if defined $locus->id;
   $atts{'Name'} = $locus->name if defined $locus->name;
   $atts{'Alias'} = $locus->aliases if defined $locus->aliases;
   $atts{'Parent'} = $locus->parents if defined $locus->parents;
   $atts{'organism_name'} = $locus->genome->name
   	if defined $locus->genome and defined $locus->genome->name;
   if(defined $locus->target){
      my $tid = $locus->target->{'id'};
      $tid =~ s/\s/{{%}}20/g;
      $atts{'Target'} = $tid . " " . $locus->target->{'from'} . " " . $locus->target->{'to'};
   }
   # TODO Gap
   $atts{'Note'} = [split /[\n\r]+/, $locus->comments] if defined $locus->comments;
   $atts{'Dbxref'} = $locus->xrefs if defined $locus->xrefs;
   $atts{'Ontology_term'} = $locus->ontology_terms_str if defined $locus->ontology_terms_str;
   my $o = "";
   for my $v (@out){
      $o.= $self->_gff3_value($v)."\t";
   }
   $a = "";
   for my $k (keys %atts){
      $a .= "$k=" . $self->_gff3_attribute($atts{$k}).";";
   }
   $a = substr($a,0,-1) if $a;
   $locus->{'_gff3_line'} = $o . $a . "\n";
   return $locus->{'_gff3_line'};
}


=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _next_locus_impl

=cut

sub _next_locus_impl {
   my ($self, @args) = @_;
   my($genomes) = $self->_rearrange([qw(GENOMES)], @args);
   my $ln;
   while($ln = $self->_readline){
      last unless $ln =~ /^\s*#/ or $ln =~ /^\s*$/;
   }
   return unless $ln;
   $self->debug("Parsing: $ln");
   my @row = split /\t/, $ln;
   my $seqid = $self->_gff3_decode($row[0]);
   my $source = $self->_gff3_decode($row[1]);
   my $family = $self->_gff3_decode($row[2]);
   my $from = $self->_gff3_decode($row[3]);
   my $to = $self->_gff3_decode($row[4]);
   my $score= $self->_gff3_decode($row[5]);
   my $strand = $self->_gff3_decode($row[6]);
   my $frame = $self->_gff3_decode($row[7]);
   my @compl = split /;/, $row[8];
   my %atts = ();
   for my $c (@compl){
      $c =~ /(.+?)=(.*)/ or next;
      my ($k,$v) = ($1, $2);
      $atts{lc $k} = $self->_gff3_decode($v);
   }
   my $id = $atts{'id'};
   my $name = $atts{'name'};
   my $genome_name = $atts{'organism_name'};
   my @comments = ();
   @comments = split /,/, $atts{'note'} if defined $atts{'note'};
   my $f = Bio::Polloc::LocusI->_qualify_type($family);
   my $type =	($f eq 'amplicon' or $f eq 'amplification') ? 'amplicon' :
   		($f eq 'composition') ? 'composition' :
		($f eq 'crispr') ? 'crispr' :
		($f eq 'pattern' or $f eq 'domain') ? 'pattern' :
		($f eq 'repeat' or $f eq 'vntr' or $f =~ /tandem.?repeat/
			or lc $source eq 'trf' or lc $source eq 'mreps') ? 'repeat' :
   		'generic';
   $type = "extend" if grep{ /Extended feature/ } @comments;
   my $locus = Bio::Polloc::LocusI->new(
   		-id=>$id, -name=>$name,
		-type=>$type,
		-from=>$from, -to=>$to, -strand=>$strand,
		-source=>$source, -family=>$family,
		-score=>$score,
		-seqname=>$seqid);
   # Parse comments
   for my $comm (@comments){
      if($comm =~ m/^(.+?)=(.+)$/){
	 my ($k, $v) = (lc $1, $2);
	 if($k and $v and $locus->can($k)){
	    $self->debug("Setting $k to $v");
	    $locus->$k($v);
	    next;
	 }
	 $genome_name = $v if not defined $genome_name and
	 	($k =~ /^organism(?:_name)?$/ or $k =~ /^genome(?:_name)?$/);
      }elsif($type eq 'extend' and $comm =~ m/Based on group [^:]+: (.*)/){
	 for my $b (split /\s/, $1){
	    $locus->basefeature($self->_locus_by_id($b)) if defined $self->_locus_by_id($b);
	 }
      }
   }
   if(defined $genomes){
      my $genome;
      # Search the genome by name:
      if(defined $genome_name){
	 for my $g (@$genomes){
	    $genome = $g if $g->name eq $genome_name;
	    last if defined $genome;
	 }
      }
      # Search the genome by sequence name (prone to errors, but it's a guess):
      unless(defined $genome){
	 for my $g (@$genomes){
	    $genome = $g if defined $g->search_sequence($seqid);
	    last if defined $genome;
	 }
      }
      $locus->genome($genome);
   }
   $locus->comments(@comments);
   return $self->_save_locus($locus);
}

=head2 _write_locus_impl

=cut

sub _write_locus_impl {
   my $self = shift;
   my $line = $self->gff3_line(@_);
   unless($self->{'_header'}){
      $self->_print("##gff-version 3\n\n");
      $self->{'_header'} = 1;
   }
   $self->_print($line);
}

=head2 _gff3_attribute

Properly escapes an attribute for GFF3 (an attribute the value of one of
the colon-separated entries in the ninth column)

=head3 Purpose

To simplify the code of L<Bio::Polloc::LocusI::gff3_line>

=head3 Arguments

The value to escape

=head3 Returns

The escaped value

=cut

sub _gff3_attribute {
   my($self,$value) = @_;
   return unless defined $value;
   if(ref($value) && ref($value) =~ m/array/i){
      my $out = "";
      for my $att (@{$value}){
	 $out.= "," . $self->_gff3_value($att);
      }
      $out = substr($out, 1) if $out;
      return $out;
   }
   return $self->_gff3_value($value);
}

=head2 _gff3_value

Properly escapes a value on the GFF3 line.  I.e., the content of one column.
Not to be used with the ninth column, because scapes the colon. the comma and
the equals signs.  Use instead the L<_gff3_attribute> function attribute by
attribute

=head3 Purpose

To simplify the code of L<gff3_line>

=head3 Arguments

The value to escape

=head3 Returns

The escaped value

=cut

sub _gff3_value {
   my ($self,$value) = @_;
   return unless defined $value;
   $value =~ s/%/%25/g;
   $value =~ s/\{\{%25\}\}/%/g;
   $value =~ s/\t/%9/g;
   $value =~ s/\n/\%D/g;
   $value =~ s/\r/\%A/g;
   $value =~ s/;/%3B/g;
   $value =~ s/=/%3D/g;
   $value =~ s/&/%26/g;
   $value =~ s/,/%2C/g;
   $value =~ s/ /%20/g;
   return $value;
}

=head2 _gff_decode

Decodes the URI-fashioned values on GFF3

=head3 Arguments

The value to decode (str)

=head3 Returns

The decoded value (str)

=cut

sub _gff3_decode {
   my($self,$value) = @_;
   return unless defined $value;
   $value =~ s/%25/%/g;
   $value =~ s/%9/\t/g;
   $value =~ s/\%D/\n/g;
   $value =~ s/\%A/\r/g;
   $value =~ s/%3B/;/g;
   $value =~ s/%3D/=/g;
   $value =~ s/%26/&/g;
   $value =~ s/%2C/,/g;
   $value =~ s/%20/ /g;
   return $value;
}

1;
