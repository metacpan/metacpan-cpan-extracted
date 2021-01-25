
package Pod::SectionToAdd;

use strict;
use warnings;

sub new {
  my __PACKAGE__ $this = shift;
  my (%args)           = @_;
  my $base             = $args{BASE};
  my $head             = $args{SECTION};
  my $index = ( defined $args{SECTION_INDEX} ) ? $args{SECTION_INDEX} : undef;
  my $alias = ( defined $args{ALIAS} )         ? $args{ALIAS}         : undef;
  my $iniinfo = {
    _index     => $index,
    _base_file => $base,
    _head      => $head,
    _alias     => $alias
  };
  bless $iniinfo, $this;
}

sub getSectionIndex {
  my __PACKAGE__ $this = shift;
  return $this->{_index} if ( defined $this->{_index} );
  return;
}

sub getBaseFile {
  my __PACKAGE__ $this = shift;
  my $base_package;
  $base_package = $this->{_base_file} if ( defined $this->{_base_file} );
  return unless ( defined $base_package );
  return $base_package;
}

sub getSectionName {
  my __PACKAGE__ $this = shift;
  return $this->{_head} if ( defined $this->{_head} );
  return;
}

sub getAlias {
  my __PACKAGE__ $this = shift;
  return $this->{_alias} if ( defined $this->{_alias} );
  return;
}

sub setAlias {
  my __PACKAGE__ $this = shift;
  my $alias = shift;
  $this->{_alias} = $alias;
  return;
}

1;

__END__

=head1 Class

B<Pod::SectionToAdd> - describes a perl POD section. Used internally only, by Pod::Modifier.

=head2 Public Functions

=head2 C<new ( BASE => SCALAR|ARRAYREF
    SECTION  => SCALAR 
    SECTION_INDEX => SCALAR
    OPTIONAL => SCALAR (optional) )>

Creates a new object for an existing section in POD of BASE.

=head3 Arguments

=over 4

=item C<BASE =E<gt>> I<base>

SCALAR The full path to perl module containing section of the POD. Or,
ARRAYREF list of full paths of perl modules containing required section.

=item C<SECTION =E<gt>> I<section>

SCALAR Name of the head (1) section.

=item C<SECTION_INDEX =E<gt>> I<index>

SCALAR Attribute to set position of insertion for this section.

=back

=head3 Return Value

Reference to class instance


=head3 Preconditions

The base files specified must exist and be readable, specified section must exist as head(1) section.

=head2 getSectionIndex()

Returns the SECTION_INDEX attribute of current PodSection object (returns undef unless defined).

=head2 getBaseFile()

Returns the BASE attribute for PodSection object.

=head2 getSectionName()

Returns the SECTION attribute of current PodSection object (returns undef unless defined).

=cut
