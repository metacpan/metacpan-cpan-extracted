=head1 NAME

Bio::Polloc::Locus::amplicon - An amplification product

=head1 DESCRIPTION

A locus amplifiable by PCR.  Implements L<Bio::Polloc::LocusI>.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Locus::amplicon;
use base qw(Bio::Polloc::LocusI);
use strict;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=head2 new

Creates a B<Bio::Polloc::Locus::repeat> object.

=head3 Arguments

=over

=item -primersio I<Bio::Polloc::Polloc::IO>

A L<Bio::Polloc::Polloc::IO> file containing the primers able to
amplify the locus.  The format is as expected by primersearch.

=item -errors I<int>

Mismatches in the amplification.

=back

=head3 Returns

A L<Bio::Polloc::Locus::repeat> object.

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}


=head2 error

Gets/sets the mismatches in the amplification.

=head3 Arguments

The error I<int>.

=head3 Returns

The error I<int> or C<undef>.

=cut

sub error {
   my($self,$value) = @_;
   $self->{'_error'} = $value+0 if defined $value;
   return $self->{'_error'};
}

=head2 primersio

Sets the primers based on a L<Bio::Polloc::Polloc::IO> object.

=head3 Arguments

A L<Bio::Polloc::Polloc::IO> object.

=cut

sub primersio {
   my($self, $io) = @_;
   return unless defined $io;
   my $line = $io->_readline;
   unless(defined $line){
      defined $io->file or $self->throw('Empty primers file', $io);
      my $io2 = Bio::Polloc::Polloc::IO->new(-input=>$io->file);
      $line = $io2->_readline;
      $io2->close;
   }else{
      $io->_pushback($line);
   }
   my @p = split /\s+/, $line, 3;
   $self->fwd_primer($p[1]);
   $self->rev_primer($p[2]);
}

=head2 fwd_primer

Gets/sets the FWD primer (I<str>).

=cut

sub fwd_primer {
   my($self, $value) = @_;
   $self->{'_fwd_primer'} = $value if defined $value;
   return $self->{'_fwd_primer'};
}

=head2 rev_primer

Gets/sets the REV primer (I<str>).

=cut

sub rev_primer {
   my($self, $value) = @_;
   $self->{'_rev_primer'} = $value if defined $value;
   return $self->{'_rev_primer'};
}

=head2 score

Gets the score

=head3 Returns

The score (float or undef). As the percentage of the primers
matching the target sequence.

=cut

sub score {
   my($self,$value) = @_;
   $self->warn("Trying to set value via read-only method 'score()'") if defined $value;
   return 100 - 100 * ($self->errors || 0) * (
   		$self->fwd_primer and $self->rev_primer ?
		1/length $self->fwd_primer . $self->rev_primer : 1);
}

=head2 errors

Sets/gets the errors (in number of nucleotides).

=head3 Arguments

The errors (int, optional).

=head3 Returns

The errors (int or undef).

=cut

sub errors {
   my($self, $value) = @_;
   my $k = '_errors';
   $self->{$k} = $value if defined $value;
   return $self->{$k};
}

=head2 distance

Returns the difference in length with the given locus.

=head3 Arguments

=over

=item -locus I<Bio::Polloc::LocusI object>

The locus to compare with.

=item -locusref I<Bio::Polloc::LocusI object>

The reference locus.  If set, replaces the current loaded object.

=back

=head3 Returns

Float, the difference in length.

=head3 Throws

L<Bio::Polloc::Polloc::Error> if no locus or the loci are not of the
proper type.

=cut

sub distance {
   my($self, @args) = @_;
   my($locus,$locusref,$units) = $self->_rearrange([qw(LOCUS LOCUSREF UNITS)], @args);
   $locusref = $self unless defined $locusref;
   
   # Check input
   $self->throw('You must set the target locus with a Bio::Polloc::LocusI object', $locus)
   	unless defined $locus and UNIVERSAL::can($locus, 'isa') and $locus->isa('Bio::Polloc::LocusI');
   $self->throw('Reference locus must be an object with a Bio::Polloc::LocusI object', $locusref)
   	unless defined $locusref and UNIVERSAL::can($locusref, 'isa') and $locusref->isa('Bio::Polloc::LocusI');
   
   # Calculate
   $self->throw('Unable to get the target coordinates', $locus) unless defined $locus->from and defined $locus->to;
   $self->throw('Unable to get the reference coordinates', $locusref) unless defined $locusref->from and defined $locusref->to;
   return abs($locus->length - $locusref->length);
}

=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   my($error,$primersio) = $self->_rearrange(
   		[qw(ERROR PRIMERSIO)], @args);
   $self->type('amplicon');
   $self->error($error);
   $self->comments("Error=" . $self->error) if defined $self->error;
   $self->primersio($primersio);
   $self->comments("Fwd_primer=" . $self->fwd_primer) if defined $self->fwd_primer;
   $self->comments("Rev_primer=" . $self->rev_primer) if defined $self->rev_primer;
}

1;
