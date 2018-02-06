package Prty::LaTeX::Generator;
use base qw/Prty::Hash/;

use strict;
use warnings;

our $VERSION = 1.123;

use Scalar::Util ();
use Prty::Option;
use Prty::Unindent;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::LaTeX::Generator - LaTeX-Generator

=head1 BASE CLASS

L<Prty::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen LaTeX-Generator. Mit den
Methoden der Klasse kann aus einem Perl-Programm heraus LaTeX-Code
erzeugt werden.

=head2 LaTeX Pakete

=head3 babel - Sprachspezifische Einstellungen vornehmen

    \usepackage[ngerman]{babel}

=over 2

=item *

L<https://ctan.org/pkg/babel>

=item *

L<https://www.namsu.de/Extra/pakete/Babel_V2017.html>

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere LaTeX-Generator

=head4 Synopsis

    $ltx = $class->new;

=head4 Description

Instantiiere einen LaTeX-Generator und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    return $class->SUPER::new;
}

# -----------------------------------------------------------------------------

=head2 Elementare Konstruktion

=head3 cmd() - Erzeuge LaTeX-Kommando

=head4 Synopsis

    $code = $ltx->cmd($name,@args);

=head4 Options

=over 4

=item -nl => $n (Default: 1)

Füge $n Zeilenumbrüche am Ende hinzu.

=item -o => $options

=item -o => \@options

Füge eine Optionsliste [...] hinzu.

=item -p => $parameters

=item -p => \@parameters

Füge eine Parameterliste {...} hinzu.

=item -preNl => $n (Default: 0)

Setze $n Zeilenumbrüche an den Anfang.

=back

=head4 Description

Erzeuge ein LaTeX-Kommando und liefere den resultierenden Code
zurück.

=head4 Examples

B<Kommando ohne Parameter oder Optionen>

    $ltx->cmd('LaTeX');

produziert

    \LaTeX

B<Kommando mit leerer Parameterliste>

    $ltx->cmd('LaTeX',-p=>'');

produziert

    \LaTeX{}

B<Kommando mit Parameter>

    $ltx->cmd('documentclass',
        -p => 'article',
    );

produziert

    \documentclass{article}

B<Kommando mit Parameter und Option>

    $ltx->cmd('documentclass',
        -o => '12pt',
        -p => 'article',
    );

produziert

    \documentclass[12pt]{article}

B<Kommando mit Parameter und mehreren Optionen (Variante 1)>

    $ltx->cmd('documentclass',
        -o => 'a4wide,12pt',
        -p => 'article',
    );

produziert

    \documentclass[a4wide,12pt]{article}

B<Kommando mit Parameter und mehreren Optionen (Variante 2)>

    $ltx->cmd('documentclass',
        -o => ['a4wide','12pt'],
        -p => 'article',
    );

produziert

    \documentclass[a4wide,12pt]{article}

=cut

# -----------------------------------------------------------------------------

sub cmd {
    my $self = shift;
    my $name = shift;
    # @_: @args

    my $nl = 1;
    my $preNl = 0;

    my $cmd = "\\$name";
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
                    q~LATEX-00001: Illegal reference type~,
                    RefType => $refType,
                );
            }
        }

        # Behandele Parameter und Optionen

        if ($opt eq '-p') {
            # Eine Parameter-Angabe wird immer gesetzt, ggf. leer
            $val //= '';
            $cmd .= "{$val}";
        }
        elsif ($opt eq '-preNl') {
            $preNl = $val;
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
                q~LATEX-00001: Unknown Option~,
                Option => $opt,
            );
        }
    }

    # Behandele Zeilenumbruch

    $cmd = ("\n" x $preNl).$cmd;
    $cmd .= ("\n" x $nl);

    return $cmd;
}

# -----------------------------------------------------------------------------

=head3 comment() - Erzeuge LaTeX-Kommentar

=head4 Synopsis

    $code = $ltx->comment($text,@opt);

=head4 Options

=over 4

=item -nl => $n (Default: 1)

Füge $n Zeilenumbrüche am Ende hinzu.

=item -preNl => $n (Default: 0)

Setze $n Zeilenumbrüche an den Anfang.

=back

=head4 Description

Erzeuge einen LaTex-Kommentar und liefere den resultierenden
Code zurück.

=head4 Examples

B<Kommentar erzeugen>

    $ltx->comment("Dies ist\nein Kommentar");

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
    my $preNl = 0;

    Prty::Option->extract(\@_,
        -nl => \$nl,
        -preNl => \$preNl,
    );

    # Argumente
    my $text = shift;

    # Kommentar erzeugen

    $text = Prty::Unindent->trim($text);
    $text =~ s/^/% /mg;
    $text = ("\n" x $preNl).$text;
    $text .= ("\n" x $nl);
    
    return $text;
}

# -----------------------------------------------------------------------------

=head3 protect() - Schütze LaTeX Metazeichen

=head4 Synopsis

    $code = $ltx->protect($text);

=head4 Description

Schütze LaTeX-Metazeichen in $text und liefere den resultierenden
Code zurück.

Liste/Erläuterung der LaTeX-Metazeichen:
L<https://www.namsu.de/Extra/strukturen/Sonderzeichen.html>

=head4 Examples

B<Dollarzeichen>

    $ltx->protect('Der Text $text wird geschützt.');

produziert

    Der Text \$text wird geschützt.

=cut

# -----------------------------------------------------------------------------

sub protect {
    my ($self,$text) = @_;

    # Vorhandene Backslashes kennzeichnen und zum Schluss ersetzen.
    # Dies ist wg. der eventuellen Ersetzung in \textbackslash{}
    # nötig, wobei dann geschweifte Klammern entstehen würden.
    $text =~ s/\\/\\\x1d/g;

    # Reservierte und Sonderzeichen wandeln
    $text =~ s/([\$_%{}#&])/\\$1/g;         # $ _ % { } # &
    $text =~ s/>/\\textgreater{}/g;         # >
    $text =~ s/</\\textless{}/g;            # <
    $text =~ s/~/\\textasciitilde{}/g;      # ~
    $text =~ s/\^/\\textasciicircum{}/g;    # <
    $text =~ s/\|/\\textbar{}/g;            # |
    $text =~ s/LaTeX/\\LaTeX{}/g;           # LaTeX
    $text =~ s/(?<!La)TeX/\\TeX{}/g;        # TeX

    # Gekennzeichnete Backslashes zum Schluss wandeln
    $text =~ s/\\\x1d/\\textbackslash{}/g; # \

    return $text;
}

# -----------------------------------------------------------------------------

=head2 LaTeX-Kommandos

=head3 renewcommand() - Redefiniere LaTeX-Kommando

=head4 Synopsis

    $code = $ltx->renewcommand($name,@args);

=head4 Options

Siehe Methode $ltx->cmd().

=head4 Description

Redefiniere LaTeX-Kommando $name und liefere den resultierenden
LaTeX-Code zurück.

=head4 Examples

    $ltx->renewcommand('cellalign',-p=>'lt');

produziert

    \renewcommand{\cellalign}{lt}

=cut

# -----------------------------------------------------------------------------

sub renewcommand {
    my $self = shift;
    my $name = shift;
    # @_: @args

    return $self->cmd('renewcommand',-p=>"\\$name",@_);
}

# -----------------------------------------------------------------------------

=head3 setlength() - Erzeuge TeX-Längenangabe

=head4 Synopsis

    $code = $ltx->setlength($name,$length,@args);

=head4 Options

Siehe Methode $ltx->cmd().

=head4 Description

Erzeuge eine TeX-Längenangabe und liefere den resultierenden
Code zurück.

=head4 Examples

B<Paragraph-Einrückung entfernen>

    $ltx->setlength('parindent','0em');

produziert

    \setlength{\parindent}{0em}

=cut

# -----------------------------------------------------------------------------

sub setlength {
    my $self = shift;
    my $name = shift;
    my $length = shift;
    # @_: @args

    return $self->cmd('setlength',-p=>"\\$name",-p=>$length,@_);
}

# -----------------------------------------------------------------------------

=head2 Höhere Konstruktionen

=head3 env() - Erzeuge LaTeX-Umgebung

=head4 Synopsis

    $code = $ltx->env($name,$body,@args);

=head4 Options

Siehe Methode $ltx->cmd(). Weitere Optionen:

=over 4

=item -indent => $n (Default: 2)

Rücke den Inhalt der Umgebung für eine bessere
Quelltext-Lesbarkeit um $n Leerzeichen ein. Achtung: In einer
Verbatim-Umgebung hat dies Auswirkungen auf die Darstellung
und sollte dort mit C<< -indent => 0 >> abgeschaltet werden.

=back

=head4 Description

Erzeuge eine LaTeX-Umgebung und liefere den resultierenden Code
zurück.

=head4 Examples

B<Document-Umgebung mit Text>

    $ltx->env('document','Dies ist ein Text.');

produziert

    \begin{document}
      Dies ist ein Text.
    \end{document}

=cut

# -----------------------------------------------------------------------------

sub env {
    my $self = shift;
    my $name = shift;
    my $body = shift;
    # @_: @args

    # Optionen, die hier sonderbehandelt werden

    my $indent = 0;
    my $nl = 1;
    my $preNl = 0;

    Prty::Option->extract(-mode=>'sloppy',\@_,
        -nl => \$nl,
        -preNl => \$preNl,
        -indent => \$indent,
    );

    # Umgebung erzeugen

    if (!defined $body) {
        $body = '';
    }
    if ($body ne '' && substr($body,-1) ne "\n") {
        $body .= "\n";
    }
    if ($indent) {
        $indent = ' ' x $indent;
        $body =~ s/^/$indent/gm;
    }
    
    my $code = $self->cmd('begin',-p=>$name,-preNl=>$preNl,@_);
    $code .= $body;
    $code .= $self->cmd('end',-p=>$name,-nl=>$nl);

    return $code;
}

# -----------------------------------------------------------------------------

=head3 section() - Erzeuge LaTeX Section

=head4 Synopsis

    $code = $ltx->section($sectionName,$title);

=head4 Arguments

=over 4

=item $sectionName

Name des LaTeX-Abschnitts. Mögliche Werte: 'part', 'chapter', 'section',
'subsection', 'susubsection', 'paragraph', 'subparagraph'.

=back

=head4 Options

=over 4

=item -label => $label

Kennzeichne Abschnitt mit Label $label.

=item -toc => $bool (Default: 1)

Nimm die Überschrift nicht ins Inhaltsverzeichnis auf.

=back

=head4 Description

Erzeuge ein LaTeX Section und liefere den resultierenden Code
zurück.

=head4 Examples

B<Ein Abschnitt der Ebene 1>

    $ltx->section('subsection','Ein Abschnitt');

produziert

    \subsection{Ein Abschnitt}

=cut

# -----------------------------------------------------------------------------

sub section {
    my $self = shift;
    my $sectionName = shift;
    my $title = shift;

    # Optionen

    my $toc = 1;
    my $label = undef;

    Prty::Option->extract(\@_,
        -label => \$label,
        -toc => \$toc,
    );

    if (!$toc) {
        $sectionName .= '*';
    }

    my $code = $self->cmd($sectionName,-p=>$title);
    if ($label) {
        $code .= $self->cmd('label',-p=>$label);
    }
    $code .= "\n";

    return $code;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.123

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
