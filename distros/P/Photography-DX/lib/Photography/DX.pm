package Photography::DX;

use 5.022;
use Carp qw( croak );
use Moo 2.0;
use experimental 'signatures';
use experimental 'refaliasing';
use namespace::clean;

# ABSTRACT: Encode/decode DX film codes
our $VERSION = '0.02'; # VERSION


my %log;
my %speed;

my %length = (
  undef => '000',
  12    => '100',
  20    => '010',
  24    => '110',
  36    => '001',
  48    => '101',
  60    => '011',
  72    => '111',
);

my %tolerance = qw(
  0.5  00
  1    10
  2    01
  3    11
);

while(<DATA>)
{
  if(/^\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+$/)
  {
    $log{$1} = $2;
    $speed{$1} = $3;
  }
  elsif(/^\s+([0-9]+)\s+-\s+([0-9]+)\s+$/)
  {
    $speed{$1} = $2;
  }
}

sub BUILDARGS
{
  my $class = shift;
  if(@_ % 2 == 0)
  {
    my %args = @_;
    
    if(defined $args{contacts_row_1})
    {
      state $speed = { reverse %speed };
      for \my %speed ($speed)
      {
        $args{speed} = $speed{$args{contacts_row_1}} || die "illegal value for contacts_row_1";
      }
    }
    
    if(defined $args{contacts_row_2})
    {
      if($args{contacts_row_2} =~ /^1([01]{3})([01]{2})$/)
      {
        state $length    = { reverse %length };
        state $tolerance = { reverse %tolerance };
        for \my %length ($length) 
        {
          for \my %tolerance ($tolerance)
          {
            $args{length}    = $length{$1};
            $args{tolerance} = $tolerance{$2};
          }
        }
      }
      else
      {
        die "illegal value for contacts_row_2";
      }
    }
    
    return \%args;
  }
  else
  {
    die "nope!";
  }
}


has speed => (
  is      => 'ro',
  lazy    => 1,
  default => sub { 100 },
  isa     => sub {
    die "speed must be a legal ISO arithmetic film speed value between 25 and 5000 or 1-8 (indicating custom film speed values)"
      unless defined $_[0] && (defined $log{$_[0]} || $_[0] =~ /^[1-8]$/);
  },
);


has length => (
  is      => 'ro',
  lazy    => 1,
  default => sub { undef },
  isa     => sub {
    die "length must be one of undef, 12, 20, 24, 36, 48, 60 or 72"
      unless (!defined $_[0]) || ($_[0] =~ /^(12|20|24|36|48|60|72)$/);
  },
);


has tolerance => (
  is      => 'ro',
  lazy    => 1,
  default => sub { 2 },
  isa     => sub {
    die "tolerance must be one of 0.5, 1, 2, 3"
      unless (defined $_[0]) && ($_[0] =~ /^(0.5|1|2|3)$/);
  },
);


sub contacts ($self)
{
  return ($self->contacts_row_1, $self->contacts_row_2);
}


sub contacts_row_1 ($self)
{
  return $speed{$self->speed};
}


sub contacts_row_2 ($self)
{
  return '1' . $length{$self->length} . $tolerance{$self->tolerance};
}


sub is_custom_speed ($self)
{
  my $speed = $self->speed;
  return $speed == 1
  ||     $speed == 2
  ||     $speed == 3
  ||     $speed == 4
  ||     $speed == 5
  ||     $speed == 6
  ||     $speed == 7
  ||     $speed == 8;
}


sub logarithmic_speed ($self)
{
  my $din = $log{$self->speed};
  croak "Unable to determine ISO logarithmic scale speed for custom " . $self->speed
    unless defined $din;
  return $din; # no loger a performance penalty in 5.20!
}


1;

=pod

=encoding utf-8

=head1 NAME

Photography::DX - Encode/decode DX film codes

=head1 VERSION

version 0.02

=head1 SYNOPSIS

 use Photography::DX;
 
 my $film = Photography::DX->new(
   speed     => 100,
   length    => 36,
   tolerance => 2,
 );
 
 # print out the layout of contacts
 # on the roll of film as a series
 # of 1s and 0s:
 print $film->contacts_row_1, "\n";
 print $film->contacts_row_2, "\n";

=head1 DESCRIPTION

This class represents a roll of 35mm film, and allows you to compute the
DX encoding contacts used by film cameras that automatically detect film
speed, the number of exposures and the exposure tolerance of the film
(most cameras actually use only the film speed for the DX encoding).

=head1 CONSTRUCTOR

 my $film = Photography::DX->new;

In addition the attributes documented below you may pass into
the constructor:

=over 4

=item contacts_row_1

The first row of contacts on the roll of film.  The speed
will be computed from this value.

=item contacts_row_2

The second row of contacts on the roll of film.  The length
and tolerance will be computed from this value.

=back

=head1 ATTRIBUTES

=head2 speed

The film speed.  Must be a legal ISO arithmetic value between 25 and 5000.  Defaults to ISO 100.

Special values 1-8 denote "custom" values.

=head2 length

The length of the film in 32x24mm exposures.  Must be one of undef (denotes "other"),
12, 20, 24, 36, 48, 60, 72.

=head2 tolerance

The exposure latitude of the film.  Must be one of:

=over 4

=item 0.5 for ±0.5 stop

=item 1 for ±1 stop

=item 2 for +2 to -1 stops

=item 3 for +3 to -1 stops

=back

=head1 METHODS

=head2 contacts

 my($row1, $row2) = $film->contacts;

Returns both rows of contacts.

=head2 contacts_row_1

Returns the contact layout as a string of 1s and 0s for the first row
of electrical contacts.  1 represents a metal contact, 0 represents the
lack of metal.

=head2 contacts_row_2

Returns the contact layout as a string of 1s and 0s for the second row
of electrical contacts.  1 represents a metal contact, 0 represents the
lack of metal.

=head2 is_custom_speed

Returns true if the film speed is a custom film speed.

=head2 logarithmic_speed

Returns the ISO logarithmic scale speed of the film (also known as DIN).

=head1 CAVEATS

In digital photography, DX also refers to Nikon's crop sensor format DSLRs.

DX encoding was introduced in 1980, well after the development of 35mm film
and so many types of film do not include DX codes.

This module uses features in and requires Perl 5.22.

=head1 SEE ALSO

=over 4

=item L<Photography::EV>

=item L<http://en.wikipedia.org/wiki/DX_encoding>

=back

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
# ISO  DIN  code
  25   15   100010
  32   16   100001
  40   17   100011
  50   18   110010
  64   19   110001
  80   20   110011
  100  21   101010
  125  22   101001
  160  23   101011
  200  24   111010
  250  25   111001
  320  26   111011
  400  27   100110
  500  28   100101
  640  29   100111
  800  30   110110
  1000 31   110101
  1250 32   110111
  1600 33   101110
  2000 34   101101
  2500 35   101111
  3200 36   111110
  4000 37   111101
  5000 38   111111

# custom    code
  1    -    100000
  2    -    110000
  3    -    101000
  4    -    111000
  5    -    100100
  6    -    110100
  7    -    101100
  8    -    111100

# crop    film                barcode contacts
Kodak     400 Tmax            010804  100110:100111
Fujicolor Provia 100F         005574  101010:100100
Fujicolor Press 800           105614  110110:100111
Kodak     Professional 100UC  015264  101010:100110
