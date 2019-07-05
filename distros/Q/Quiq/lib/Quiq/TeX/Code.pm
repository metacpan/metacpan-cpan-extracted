package Quiq::TeX::Code;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Quiq::Option;
use Scalar::Util ();
use Quiq::Unindent;
use Quiq::Math;
use Quiq::Converter;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::TeX::Code - Generator für TeX Code

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen TeX Code-Generator. Mit
den Methoden der Klasse kann aus einem Perl-Programm heraus
TeX-Code erzeugt werden.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere TeX Code-Generator

=head4 Synopsis

    $t = $class->new;

=head4 Description

Instantiiere einen TeX Code-Generator und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    return shift->SUPER::new;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 c() - Erzeuge TeX Codezeile

=head4 Synopsis

    $code = $t->c($fmt,@args,@opts);

=head4 Arguments

=over 4

=item $fmt

Codezeile mit sprintf Formatelementen.

=item @args

Argumente, die für die Formatelemente in $fmt eingesetzt
werden. Kommt eine Arrayreferenz vor, wird diese zu einem
kommaseparierten String expandiert.

=back

=head4 Options

=over 4

=item -nl => $n (Default: 1)

Beende den Code mit $n Zeilenumbrüchen.

=item -pnl => $n (Default: 0)

Beginne den Code mit $n Zeilenumbrüchen.

=back

=head4 Returns

TeX Code (String)

=head4 Description

Erzeuge eine TeX Codezeile und liefere das Resultat zurück.

=head4 Example

B<Makro mit Option und Parameter>

    $documentClass = 'article';
    $fontSize = '12pt';
    ...
    $t->c('\documentclass[%s]{%s}',$fontSize,$documentClass);

produziert

    \documentclass[12pt]{article}\n

B<Expansion von Array-Parameter>

    my @opt;
    push @opt,'labelsep=colon';
    push @opt,'labelfont=bf';
    push @opt,'skip=1.5ex';
    $t->c('\usepackage[%s]{caption}',\@opt);

produziert

    \usepackage[labelsep=colon,labelfont=bf,skip=1.5ex]{caption}

=cut

# -----------------------------------------------------------------------------

sub c {
    my $self = shift;
    my $fmt = shift;
    # @_: @args,@opts

    # Optionen

    my $nl = 1;
    my $pnl = 0;

    Quiq::Option->extract(\@_,
        -nl => \$nl,
        -pnl => \$pnl,
    );

    # Arrayreferenz zu kommasepariertem String expandieren

    for (@_) {
        my $type = Scalar::Util::reftype($_);
        if (defined($type) && $type eq 'ARRAY') {
            $_ = join ',',@$_;
        }
    }

    # Codezeile erzeugen und zurückliefern
    return ("\n" x $pnl).sprintf($fmt,@_).("\n" x $nl);
}

# -----------------------------------------------------------------------------

=head3 ci() - Erzeuge TeX Code inline

=head4 Synopsis

    $code = $t->ci($fmt,@args,@opts);

=head4 Arguments

=over 4

=item $fmt

Codezeile mit sprintf Formatelementen.

=item @args

Argumente, die in den Formatstring eingesetzt werden. Kommt unter
den Argumenten eine Arrayreferenz vor, wird diese zu einem
kommaseparierten String expandiert.

=back

=head4 Options

=over 4

=item -nl => $n (Default: 0)

Beende den Code mit $n Zeilenumbrüchen.

=back

=head4 Returns

TeX Code (String)

=head4 Description

Erzeuge TeX Code und liefere das Resultat zurück. Die Methode
ist identisch zu Methode $t->c(), nur dass per Default kein
Newline am Ende des Code hinzugefügt wird. Das C<i> im
Methodennamen steht für "inline".

=head4 Example

B<< Vergleich von $t->ci(), sprintf(), $t->c() >>

    $t->ci('\thead[%sb]{%s}','c','Ein Text');

ist identisch zu

    sprintf '\thead[%sb]{%s}','c','Ein Text';

ist identisch zu

    $t->c('\thead[%sb]{%s}','c','Ein Text',-nl=>0);

und produziert

    \thead[cb]{Ein Text}

=cut

# -----------------------------------------------------------------------------

sub ci {
    my $self = shift;
    my $fmt = shift;
    # @_: @args,@opts
    return $self->c($fmt,-nl=>0,@_);
}

# -----------------------------------------------------------------------------

=head3 macro() - Erzeuge TeX Macro

=head4 Synopsis

    $code = $t->macro($name,@args);

=head4 Options

=over 4

=item -nl => $n (Default: 1)

I<Newline>, füge $n Zeilenumbrüche am Ende hinzu.

=item -o => $options

=item -o => \@options

Füge eine Option/Optionsliste [...] hinzu. Ein Array wird in eine
kommaseparierte Liste von Werten übersetzt.

=item -p => $parameters

=item -p => \@parameters

Füge einen Parameter/eine Parameterliste {...} hinzu. Ein Array
wird in eine kommaseparierte Liste von Werten übersetzt.

=item -pnl => $n (Default: 0)

I<Preceeding newline>, setze $n Zeilenumbrüche an den Anfang.

=back

=head4 Description

Erzeuge ein TeX Macro und liefere den resultierenden Code
zurück. Diese Methode zeichnet sich gegenüber den Methoden $t->c()
und $t->ci() dadurch aus, dass undefinierte/leere Optionen und
Parameter vollständig weggelassen werden.

=head4 Examples

B<Macro ohne Argumente>

    $t->macro('\LaTeX');

produziert

    \LaTeX

B<Kommando mit undefiniertem Argument>

    $t->macro('\LaTeX',-p=>undef);

produziert

    \LaTeX

B<Macro mit Leerstring-Argument >

    $t->macro('\LaTeX',-p=>'');

produziert

    \LaTeX{}

B<Macro mit leerer Optionsliste und Parameter>

    @opt = ();
    $t->macro('\documentclass',-o=>\@opt,-p=>'article');

produziert

    \documentclass{article}

B<Macro mit Opton und Parameter>

    $t->macro('\documentclass',
        -o => '12pt',
        -p => 'article',
    );

produziert

    \documentclass[12pt]{article}

B<Macro mit Parameter und mehreren Optionen (Variante 1)>

    $t->macro('\documentclass',
        -o => 'a4wide,12pt',
        -p => 'article',
    );

produziert

    \documentclass[a4wide,12pt]{article}

B<Macro mit Parameter und mehreren Optionen (Variante 2)>

    @opt = ('a4wide','12pt');
    $t->macro('\documentclass',
        -o => \@opt,
        -p => 'article',
    );

produziert

    \documentclass[a4wide,12pt]{article}

=cut

# -----------------------------------------------------------------------------

sub macro {
    my $self = shift;
    my $name = shift;
    # @_: @args

    my $nl = 1;
    my $pnl = 0;

    my $cmd = $name;
    while (@_) {
        my $opt = shift;
        my $val = shift;

        # Wandele Array in kommaseparierte Liste von Werten

        if (ref $val) {
            my $refType = Scalar::Util::reftype($val);
            if ($refType eq 'ARRAY') {
                $val = join ',',@$val;
            }
            else {
                $self->throw(
                    'TEX-00001: Unexpected reference',
                    RefType => $refType,
                );
            }
        }

        # Behandele Parameter und Optionen

        if ($opt eq '-p') {
            # Ein Parameter-Wert wird immer gesetzt, ggf. leer
            $val //= '';
            $cmd .= "{$val}";
        }
        elsif ($opt eq '-pnl') {
            $pnl = $val;
        }
        elsif ($opt eq '-o') {
            # Eine Options-Angabe entfällt, wenn leer
            if (defined $val && $val ne '') {
                $cmd .= "[$val]";
            }
        }
        elsif ($opt eq '-nl') {
            $nl = $val;
        }
        else {
            $self->throw(
                'LATEX-00001: Unknown Option',
                Option => $opt,
            );
        }
    }

    return ("\n" x $pnl).$cmd.("\n" x $nl);
}

# -----------------------------------------------------------------------------

=head3 comment() - Erzeuge TeX-Kommentar

=head4 Synopsis

    $code = $l->comment($text,@opt);

=head4 Options

=over 4

=item -nl => $n (Default: 1)

Füge $n Zeilenumbrüche am Ende hinzu.

=item -pnl => $n (Default: 0)

Setze $n Zeilenumbrüche an den Anfang.

=back

=head4 Description

Erzeuge einen TeX-Kommentar und liefere den resultierenden Code
zurück.

=head4 Examples

B<Kommentar erzeugen>

    $l->comment("Dies ist\nein Kommentar");

produziert

    % Dies ist
    % ein Kommentar

=cut

# -----------------------------------------------------------------------------

sub comment {
    my $self = shift;
    # @_: $text,@opt

    # Optionen

    my $nl = 1;
    my $pnl = 0;

    Quiq::Option->extract(\@_,
        -nl => \$nl,
        -pnl => \$pnl,
    );

    # Argumente
    my $text = shift;

    # Kommentar erzeugen

    $text = Quiq::Unindent->trim($text);
    $text =~ s/^/% /mg;
    $text = ("\n" x $pnl).$text;
    $text .= ("\n" x $nl);
    
    return $text;
}

# -----------------------------------------------------------------------------

=head3 modifyLength() - Wende Berechnung auf Länge an

=head4 Synopsis

    $newLength = $l->modifyLength($length,$expr);

=head4 Arguments

=over 4

=item $length

Eine einfache TeX-Länge. Beispiel: '1ex'.

=item $expr

Ein arithmetischer Ausdruck, der auf den Zahlenwert der Länge
angewendet wird. Beispiel: '*2' (multipliziere Länge mit 2).

=back

=head4 Returns

TeX-Länge (String)

=head4 Description

Wende den arithmetischen Ausdruck $expr auf TeX-Länge $length an
und liefere das Resultat zurück. Leerstring oder C<undef> werden
unverändert geliefert.

=head4 Example

    $l->modifyLength('1.5ex','*1.5');
    # 2.25ex

=cut

# -----------------------------------------------------------------------------

sub modifyLength {
    my ($self,$length,$expr) = @_;

    if (defined($length) && $length ne '') {
        my ($len,$unit) = $length =~ /^([\d.]+)([a-z]+)$/;
        my $expr = "$len$expr";
        $len = eval $expr;
        if ($@) {
            $self->throw(
                'TEX-00001: Illegal expression',
                Expression => $expr,
            );
        }
        $length = "$len$unit";
    }

    return $length;
}

# -----------------------------------------------------------------------------

=head3 toLength() - Wandele Länge in TeX-Länge

=head4 Synopsis

    $length = $this->toLength($val);

=head4 Arguments

=over 4

=item $val

Länge, die in die TeX-Länge umgerechnet wird.

=back

=head4 Returns

TeX-Länge (String)

=head4 Examples

Keine Angabe:

    $class->toLength(undef);
    # undef

Angabe in Pixeln ohne Einheit:

    $class->toLength(100);
    # '75pt'

Angabe in Pixeln mit Einheit:

    $class->toLength('100px');
    # '75pt'

Alle anderen Werte bleiben unverändert:

    $class->toLength($val);
    # $val

=cut

# -----------------------------------------------------------------------------

sub toLength {
    my ($this,$val) = @_;

    if (defined $val) {
        $val =~ s/px$//; # Einheit Pixel entfernen wir
        if (Quiq::Math->isNumber($val)) {
            # Keine Einheit: Pixel -> Punkt
            $val = Quiq::Converter->pxToPt($val).'pt';
        }
    }

    return $val;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.149

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
