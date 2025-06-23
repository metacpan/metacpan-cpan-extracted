# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Range - Liste von Integern

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

  use Quiq::Range;
  
  # Instantiierung
  my $rng = Quiq::Range->new($spec);
  
  # Übersetzung in ein Array von Integern
  my @arr = Quiq::Range->numbers;

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine Liste von Integern. Diese wird
vom Nutzer spezifiziert als eine Aufzählung von Angaben der Art

  N     einzelner Integer
  N-M   Bereich von Integern

die durch Komma getrennt aufgezählt werden können. Beispiele:

  Spezfikation          Array von Integern
  --------------------- ----------------------------------
  7                     7
  1-4                   1 2 3 4
  1,2,3,4               1 2 3 4
  3,5,7-10,16,81-85,101 3 5 7 8 9 10 16 81 82 83 84 85 101

=head1 ATTRIBUTES

=over 4

=item spec => $spec

Die Spezifikation, die dem Konstruktur übergeben wurde.

=item numberA => \@numbers

Die Übersetzung der Spezifikation in ein Array von Integern.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Range;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $rng = $class->new($spec);

=head4 Arguments

=over 4

=item $spec

Spezifikation der Integer-Liste in oben beschiebener Syntax.

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt gemäß Spezifikation $spec und liefere eine
Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $spec = shift // '';

    my @arr;
    for (split /,/,$spec) {
        my ($min,$max) = split /-/;
        push @arr,$max? ($min..$max): $_;
    }

    # Objekt instantiieren

    return $class->SUPER::new(
        spec => $spec,
        integerA => \@arr,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 numbers() - Nummern des Bereichs

=head4 Synopsis

  @numbers | $numberA = $rng->numbers;
  @numbers | $numberA = $class->numbers($spec);

=head4 Returns

Liste von Nummern (Array of Numbers). Im Skalarkontext eine Referenz
auf die Liste.

=head4 Description

Liefere die Liste der Integers. Die Methode kann als Klassen- oder
Objektmethode gerufen werden.

=cut

# -----------------------------------------------------------------------------

sub numbers {
    my $self = ref $_[0]? shift: shift->new(shift);
    my $arr = $self->{'integerA'};
    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.228

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2025 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
