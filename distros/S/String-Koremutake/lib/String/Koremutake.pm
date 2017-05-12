package String::Koremutake;
use strict;
use warnings;
use Error;
our $VERSION = '0.30';

my @phonemes = map { lc } qw{BA BE BI BO BU BY DA DE DI DO DU DY FA FE FI
FO FU FY GA GE GI GO GU GY HA HE HI HO HU HY JA JE JI JO JU JY KA KE
KI KO KU KY LA LE LI LO LU LY MA ME MI MO MU MY NA NE NI NO NU NY PA
PE PI PO PU PY RA RE RI RO RU RY SA SE SI SO SU SY TA TE TI TO TU TY
VA VE VI VO VU VY BRA BRE BRI BRO BRU BRY DRA DRE DRI DRO DRU DRY FRA
FRE FRI FRO FRU FRY GRA GRE GRI GRO GRU GRY PRA PRE PRI PRO PRU PRY
STA STE STI STO STU STY TRA TRE};

my %phoneme_to_number;
my %number_to_phoneme;

my $number = 0;
foreach my $phoneme (@phonemes) {
  $phoneme_to_number{$phoneme} = $number;
  $number_to_phoneme{$number}  = $phoneme;
  $number++;
}

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  return $self;
}

sub _numbers_to_koremutake {
  my($self, $numbers) = @_;
  my $string;
  foreach my $n (@$numbers) {
    throw Error::Simple("0 <= $n <= 127") unless (0 <= $n) && ($n <= 127);
    $string .= $number_to_phoneme{$n};
  }
  return $string;
}

sub _koremutake_to_numbers {
  my($self, $string) = @_;
  my @numbers;
  my $phoneme;
  my @chars = split //, $string;
  while (@chars) {
    $phoneme .= shift @chars;
    next unless $phoneme =~ /[aeiouy]/;
    my $number = $phoneme_to_number{$phoneme};
    throw Error::Simple("Phoneme $phoneme not valid") unless defined $number;
    push @numbers, $number;
    $phoneme = "";
  }
  return \@numbers;
}

sub integer_to_koremutake {
  my($self, $integer) = @_;

  throw Error::Simple("No integer given") unless defined $integer;
  throw Error::Simple('Negative numbers not acceptable') if $integer < 0;

  my @numbers;
  
  @numbers = (0) if $integer == 0;

  while ($integer != 0) {
    push @numbers, $integer % 128;
    $integer = int($integer/128);
  }
  return $self->_numbers_to_koremutake([reverse @numbers]);
}

sub koremutake_to_integer {
  my($self, $string) = @_;
  throw Error::Simple("No koremutake string given") unless defined $string;

  my $numbers = $self->_koremutake_to_numbers($string);
  my $integer = 0;
  while (@$numbers) {
    my $n = shift @$numbers;
    $integer = ($integer * 128) + $n;
  }
  return $integer;
}

1;

__END__

=head1 NAME

String::Koremutake - Convert to/from Koremutake Memorable Random Strings

=head1 SYNOPSIS

  use String::Koremutake;
  my $k = String::Koremutake->new;

  my $s = $k->integer_to_koremutake(65535);        # botretre
  my $i = $k->koremutake_to_integer('koremutake'); # 10610353957

=head1 DESCRIPTION

The String::Koremutake module converts to and from Koremutake
Memorable Random Strings.

The term "Memorable Random String" was thought up by Sean B. Palmer as
a name for those strings like dopynl, glargen, glonknic, spoopwiddle,
and kebble etc. that don't have any conventional sense, but can be
used as random identifiers, especially in URIs to keep them
persistent. See http://infomesh.net/2001/07/MeRS/

Koremutake is a MeRS algorithm which is used by Shorl
(http://shorl.com/koremutake.php). As they explain: "It is, in plain
language, a way to express any large number as a sequence of
syllables. The general idea is that word-sounding pieces of
information are a lot easier to remember than a sequence of digits."

=head1 INTERFACE

=head2 new()

The new() method is the constructor:

=head2 integer_to_koremutake($i)

The integer_to_koremutake method converts a positive integer to a
Koremutake string:

  my $s = $k->integer_to_koremutake(65535);        # botretre

=head2 koremutake_to_integer($s)

The koremutake_to_integer method converts a Koremutake string to the
integer it represents:

  my $i = $k->koremutake_to_integer('koremutake'); # 10610353957

=head1 BUGS AND LIMITATIONS                                                     
                                                                                
No bugs have been reported.                                                     
                                                                                
Please report any bugs or feature requests to                                   
C<bug-String-Koremutake@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  

=head1 AUTHOR

Leon Brocard C<acme@astray.com>

=head1 LICENCE AND COPYRIGHT                                                    
                                                                                
Copyright (c) 2005, Leon Brocard C<acme@astray.com>. All rights reserved.
                                                                                
This module is free software; you can redistribute it and/or                    
modify it under the same terms as Perl itself.                                  
                                                                                
