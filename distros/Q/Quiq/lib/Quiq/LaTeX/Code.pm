package Quiq::LaTeX::Code;
use base qw/Quiq::TeX::Code/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Quiq::Option;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::LaTeX::Code - Generator für LaTeX Code

=head1 BASE CLASS

L<Quiq::TeX::Code>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen LaTeX
Code-Generator. Mit den Methoden der Klasse kann aus einem
Perl-Programm heraus LaTeX-Code erzeugt werden. Die Klasse stützt
sich ab auf ihre Basisklasse Quiq::TeX::Code. Weitere Methoden
siehe dort.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere LaTeX Code-Generator

=head4 Synopsis

    $l = $class->new;

=head4 Description

Instantiiere einen LaTeX Code-Generator und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    return shift->SUPER::new;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 protect() - Schütze LaTeX Metazeichen

=head4 Synopsis

    $code = $l->protect($text);

=head4 Description

Schütze LaTeX-Metazeichen in $text und liefere den resultierenden
Code zurück.

Liste/Erläuterung der LaTeX-Metazeichen:
L<https://www.namsu.de/Extra/strukturen/Sonderzeichen.html>

=head4 Examples

B<Dollarzeichen>

    $l->protect('Der Text $text wird geschützt.');

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
    $text =~ s/\^/\\textasciicircum{}/g;    # ^
    $text =~ s/\|/\\textbar{}/g;            # |
    $text =~ s/LaTeX/\\LaTeX{}/g;           # LaTeX
    $text =~ s/(?<!La)TeX/\\TeX{}/g;        # TeX

    # Gekennzeichnete Backslashes zum Schluss wandeln
    $text =~ s/\\\x1d/\\textbackslash{}/g; # \

    return $text;
}

# -----------------------------------------------------------------------------

=head3 env() - Erzeuge LaTeX-Umgebung

=head4 Synopsis

    $code = $l->env($name,$body,@args);

=head4 Options

Siehe Methode $t->macro(). Weitere Optionen:

=over 4

=item -indent => $n (Default: 2)

Rücke den Inhalt der Umgebung für eine bessere
Quelltext-Lesbarkeit um $n Leerzeichen ein. Achtung: In einer
Verbatim-Umgebung hat dies Auswirkungen auf die Darstellung und
sollte in dem Fall mit C<< -indent => 0 >> abgeschaltet werden.

=back

=head4 Description

Erzeuge eine LaTeX-Umgebung und liefere den resultierenden Code
zurück. Body $body und @args können in beliebiger Reihenfolge
auftreten.

=head4 Examples

B<Document-Umgebung mit Text>

    $l->env('document','Dies ist ein Text.');

produziert

    \begin{document}
      Dies ist ein Text.
    \end{document}

=cut

# -----------------------------------------------------------------------------

sub env {
    my $self = shift;
    my $name = shift;
    # @_: $body,@args

    # Optionen, die hier sonderbehandelt werden

    my $indent = 0;
    my $nl = 1;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -nl => \$nl,
        -indent => \$indent,
    );

    # Body ermitteln. Wir fügen alle Argumente ohne Option
    # zu dem Body zusammen.

    my $body;
    for (my $i = 0; $i < @_; $i++) {
        if (defined($_[$i]) && $_[$i] =~ /^-(o|p|pnl)$/) {
            # Optionen, die wir weiterleiten, übergehen
            $i++;
            next;
        }
        $body .= splice @_,$i--,1;
    }

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
    
    my $code = $self->macro('\begin',-p=>$name,@_);
    $code .= $body;
    $code .= $self->macro('\end',-p=>$name,-nl=>$nl);

    return $code;
}

# -----------------------------------------------------------------------------

=head3 section() - Erzeuge LaTeX Section

=head4 Synopsis

    $code = $l->section($sectionName,$title);

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

=item -notToc => $bool (Default: 0)

Nimm die Überschrift nicht ins Inhaltsverzeichnis auf.

=back

=head4 Description

Erzeuge ein LaTeX Section und liefere den resultierenden Code
zurück.

=head4 Examples

B<Ein Abschnitt der Ebene 1>

    $l->section('subsection','Ein Abschnitt');

produziert

    \subsection{Ein Abschnitt}

=cut

# -----------------------------------------------------------------------------

sub section {
    my $self = shift;
    my $sectionName = shift;
    my $title = shift;

    # Optionen

    my $notToc = 0;
    my $label = undef;

    Quiq::Option->extract(\@_,
        -label => \$label,
        -notToc => \$notToc,
    );

    if ($notToc) {
        $sectionName .= '*';
    }

    my $code = $self->c('\%s{%s}',$sectionName,$title);
    if ($label) {
        $code .= $self->c('\label{%s}',$label);
    }
    $code .= "\n";

    return $code;
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
