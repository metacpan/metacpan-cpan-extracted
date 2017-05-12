=head1 NAME

Bio::Polloc::Locus::composition - A composition feature

=head1 DESCRIPTION

This feature is intended to save the content of a group of
residues in a certain sequence.  This feature was first
created to reflect the G+C content.

=head1 AUTHOR - Luis M. Rodriguez-R

Email lmrodriguezr at gmail dot com

=cut

package Bio::Polloc::Locus::composition;
use base qw(Bio::Polloc::LocusI);
use strict;
our $VERSION = 1.0503; # [a-version] from Bio::Polloc::Polloc::Version


=head1 APPENDIX

Methods provided by the package

=cut

=head2 new

Initialization method.

=head3 Arguments

=over

=item -letters I<str>

The residues

=item -composition I<float>

The percentage of the sequence covered by the residues (letters).

=back

=cut

sub new {
   my($caller,@args) = @_;
   my $self = $caller->SUPER::new(@args);
   $self->_initialize(@args);
   return $self;
}

=head2 letters

Gets/sets the analysed residues.

=head3 Arguments

The residues (str, optional).

=head3 Returns

The residues (str or undef).

=cut

sub letters {
   my($self,$value) = @_;
   $self->{'_letters'} = $value if defined $value;
   return $self->{'_letters'};
}


=head2 composition

Gets/sets the percentage of the sequence covered by the residues (letters).

=head3 Arguments

The percentage (float, optional).

=head3 Returns

The percentage (float or undef).

=cut

sub composition {
   my($self,$value) = @_;
   $self->{'_composition'} = $value if defined $value;
   return $self->{'_composition'};
}


=head2 score

Dummy function, required by the L<Bio::Polloc::LocusI> interface.  Returns undef
because any score is associated

=cut

sub score { return }


=head1 INTERNAL METHODS

Methods intended to be used only within the scope of Bio::Polloc::*

=head2 _initialize

=cut

sub _initialize {
   my($self,@args) = @_;
   my($letters, $composition) = $self->_rearrange(
   		[qw(LETTERS COMPOSITION)], @args);
   $self->type('composition');
   $self->letters($letters);
   $self->comments("Residues=" . $self->letters) if defined $self->letters;
   $self->composition($composition);
   $self->comments("Perc=" . sprintf("%.2f",$self->composition)) if defined $self->composition;
}

1;
