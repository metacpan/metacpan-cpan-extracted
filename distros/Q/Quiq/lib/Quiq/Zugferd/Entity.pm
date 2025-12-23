# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Zugferd::Entity - Basisklasse der Entitätsklassen

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Diese Klasse enthält Methoden, die von allen Entitätsklassen
genutzt werden.

=cut

# -----------------------------------------------------------------------------

package Quiq::Zugferd::Entity;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.233';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Objektmethoden

=head3 transferDate() - Übertrage Datum ins ZUGFeRD XML

=head4 Synopsis

  @arr = $class->transferDate($key,$btCode);

=head4 Description

Übertrage den (Datums-)Wert des Attributs $key unter dem Business Term
$btCode ins ZUGFeRD XML. Beispiel:

  @arr = $rch->transferDate('faelligkeitsdatum','BT-9');

liefert

  ('BT-9','20250707','BT-9-0',102)

wenn das Rechnungsattribut faelligkeitsdatum den Wert '20250707' hat.

=cut

# -----------------------------------------------------------------------------

sub transferDate {
    my ($self,$key,$btCode) = @_;

    my $date = $self->$key;
    my $dateCode = $date? 102: undef;

    return ($btCode,$date,"$btCode-0",$dateCode);
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.233

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
