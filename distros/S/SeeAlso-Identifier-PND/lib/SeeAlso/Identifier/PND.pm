package SeeAlso::Identifier::PND;
use strict;
use warnings;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '0.62';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw();
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

use base qw( SeeAlso::Identifier::GND );
#use Carp;

#################### subroutine header end ####################


=head1 NAME

SeeAlso::Identifier::PND - SeeAlso handling of PND Numbers (Personennormdatei)


=head1 SYNOPSIS

  my $pnd = new SeeAlso::Identifier::PND "";

  print "invalid/empty" unless $pnd; # $pnd is defined but false !

  $pnd->value( '101115658X' );
  $pnd->value( 'PND:101115658X' );
  $pnd->value( '(DE-588)101115658X' );
  $pnd->value( '(DE-588a)101115658X' );
  $pnd->value( 'http://d-nb.info/gnd/101115658X' );
  $pnd->value; # '' or PND identifier again (101115658X)
  $pnd; # PND identifier as URI (http://d-nb.info/gnd/101115658X)

  $pnd->canonical; # http://d-nb.info/gnd/101115658X

  $pnd->pretty; # '' or PND identifier again (101115658X)

=head1 DESCRIPTION

This module handles identification numbers of the former Personennormdatei (PND)
of the German National Library (DNB). These continue to be valid identification
numbers of the successor Gemeinsame Normdatei (GND).

The constructor of SeeAlso::Identifier::PND always returns an defined identifier 
with all methods provided by L<SeeAlso::Identifier>. 
As canonical form the URN representation of PND with prefix C<http://d-nb.info/gnd> 
is used (these HTTP URIs actually resolve).
As hashed and "pretty" form of an PND number, the number itself is used (including check digit).

The authority files PND, GKD and SWD have been combined to the GND (Gemeinsame
Norm-Datei) in early 2012, the identifiers of "legacy" records however will
remain valid. They already are distinct and as such the parent module
L<SeeAlso::Identifier::GND> handles them simultaneously. As of v0.57 
SeeAlso::Identifier::GND is lacking support for 10-digit identifiers and
does not implement all possible constraints (e.g. there are conflicting
checksum algorithms but by looking at the identifier you can not always
determine the authority file it belongs to and therefore there is no
certainity about the correct checksum).

This module SeeAlso::Identifier::PND does not support the legacy GND numbers
for former entries of GKD and SWD and therefore its realm continues to be
restricted to authority records for persons and names (Tn and Tp) within
the GND.

For compatibility reasons with SeeAlso::Identifier::GND the objects of this
module are implemented as blessed hashes instead of blessed scalars as
they would be by inheritance from SeeAlso::Identifier.

=head1 METHODS

=head2 parse ( $value )

Get and/or set the value of the PND identifier. Returns an empty string or a possibly valid PND number. You can also use this method as function.

Older numbers begin with "10" to "16" and have 8 digits plus check digit (which might be "X"),
More recently (since April 2011) assigned numbers have 9 digits plus check digit(0-X) and currently begin with "10".
Probably at some time in 2016 the first 10-"digit" number starting with "11" will be assigned.

Any blanks are removed from the input. 
Informal prefixes "PND", "GND/" and the likes are permitted, also MARC organization codes "(DE-588)" and "(DE-588a)",
and the official URI prefix C< http://d-nb.info/gnd/ >.

Dashes are not removed any more when parsing, since for some former GKD numbers they are the only
distinction.

=cut

sub parse {
    local($_) = shift;
    $_ = shift if ref($_) and scalar @_;

    return "" unless defined $_;

    s/\s+//g;      # no kind of spaces makes sense in input data
    s=^(?:http://d-nb.info/gnd/|[GP]ND[:/-]*\s?|\(DE-588[a]?\))([0-9xX-]+)=$1=i;

    s/^0+//;
    tr/x/X/;

    return "" unless /^1[01]?\d{7}[\dX]$/;

    return $_;
}


=head2 value ( [$value] )

get/set using parse, not parent's method

=cut

sub value {
  my($self, $value) = @_;
  $self->{value} = $self->parse($value) if defined $value;
  return $self->{value};
}


=head2 valid

Performs checksum calculation for already parsed PND numbers.

The mod-11-checksum is constructed the same way as for the "PICA PPN" (Pica Production Number 
of the German National Library (actually the PND identifiers simply are PICA PPNs).

=cut

sub valid {
    return undef unless $_[0]->{value} and $_[0]->{value} =~ /^1[01]?\d{7}[\dX]$/;
    my @i = reverse split(//, $_[0]->{value});
    $i[0] = 10 if $i[0] =~ /X/i;

    my ($z, $w) = (0, 1);
    foreach ( @i ) {
        $z += ($_ * $w++)};
    return ($z % 11) == 0;
}


=head2 hash ( [$value] )

Sets and/or gets a form of the identifier suitable for processing.
In this class this will yield the same form as "parse", provided
it passes the "valid" test(s). 

=cut

sub hash {
  my $self = shift @_;
  if ( defined $_[0] ) {
      if ( $_[0] =~ /^1[01]?\d{7}[\dXx]$/ ) {
          $self->value($_[0])}
      else {
          return $self->{value} = undef}
    }
  return $self->valid ? $self->{value} : "";
}


=head2 indexed ( [$value] )

This is only since the parent class L<SeeAlso::Identifier::GND> as of v0.57
is not compliant to the interfaces specified by L<SeeAlso::Identifier>
with respect to "indexed" being an alias for "hash".

=cut

sub indexed {
  my $self = shift @_;
  return $self->hash;
}


=head2 canonical ( [$value] )

Yields the (for SeeAlso) canonical form of the identifier (if valid) as
an URI.

=cut

sub canonical {
  my $self = shift @_;
  if ( defined $_[0] ) {
      if ( $_[0] =~ m=^http://d-nb.info/gnd/= ) {
          $self->value($_[0])}
      else {
          return $self->{value} = undef}
    }
  return $self->valid ? ("http://d-nb.info/gnd/" . $self->{value}) : "";
}


=head2 normalized ( [$value] )

This is only since the parent class L<SeeAlso::Identifier::GND> as of v0.57
is not compliant to the interfaces specified by L<SeeAlso::Identifier>
with respect to "normalized" being an alias for "canonical".

=cut

sub normalized {
  my $self = shift @_;
  return $self->canonical;
}


=head2 cmp ( $value )

For comparisons a "numerical" order is established by left-padding 
the identifiers with sufficiently many zeroes.

=cut

sub cmp {
    my $self = shift;
    my $string1 = sprintf("%010s", $self->{value});
    my $class = ref($self);
    my $second = shift;
    my $string2 = sprintf("%010s", $class->new($second)->{value});
    return $string1 cmp $string2;
}


=head2 pretty

Try to give the most official form of the identifier.

=cut

sub pretty {
  my $self = shift @_;
  return $self->valid ? $self->{value} : "";
}


=head1 AUTHOR

Thomas Berger C<< <THB@gymel.com> >>

=head1 ACKNOWLEDGEMENTS

Jakob Voss C<< <jakob.voss@gbv.de> >> crafted SeeAlso::Identifier::GND.

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1), L<SeeAlso::Identifer::GND>.

=cut

#################### main pod documentation end ###################


1;
# The preceding line will help the module return a true value

