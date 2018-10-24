package Prty::Concat;
use base qw/Prty::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.125;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Concat - Konkateniere Zeichenketten

=head1 BASE CLASS

L<Prty::Object>

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

=head4 Example

B<Konkatenation bei zutreffender Bedingung>

    Prty::Concat->catIf(1,sub {
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

1.125

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2018 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
