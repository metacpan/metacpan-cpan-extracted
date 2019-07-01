package Quiq::Concat;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Concat - Konkateniere Zeichenketten

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Klassenmethoden

=head3 catIf() - Konkateniere bei erfüllter Bedingung

=head4 Synopsis

    $str = $class->catIf($bool,sub {$expr,...});

=head4 Arguments

=over 4

=item $bool

Bedingung

=item sub {$expr,...}

Ausdrücke, deren Resultat konkateniert wird.

=back

=head4 Returns

String

=head4 Description

Ist Bedingung $bool falsch, liefere einen Leerstring. Andernfalls
konkateniere die Werte der Ausdrücke $expr, ... und liefere das
Resultat zurück. Evaluiert ein Ausdruck $expr zu C<undef>, wird
der Wert durch einen Leerstring ersetzt.

Die Methode ist logisch äquivalent zu

    $str = !$bool? '': join '',$expr // '', ...;

Sie vermeidet jedoch, dass $expr // '', ... berechnet werden muss,
wenn $bool falsch ist.

=head4 Example

B<Konkatenation bei zutreffender Bedingung>

    Quiq::Concat->catIf(1,sub {
        'Dies',
        'ist',
        'ein',
        undef,
        'Test',
    });
    # 'DiesisteinTest'

=cut

# -----------------------------------------------------------------------------

sub catIf {
    my ($class,$bool,$sub) = @_;
    return !$bool? '': join '',map {$_ // ''} $sub->();
}
    

# -----------------------------------------------------------------------------

=head1 VERSION

1.148

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
