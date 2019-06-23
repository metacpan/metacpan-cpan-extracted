package Quiq::Html::Pygments;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::CommandLine;
use Quiq::Shell;
use Quiq::Ipc;
use Quiq::Unindent;
use Quiq::Css;
use Quiq::Html::Table::Simple;
use Quiq::Html::Page;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Pygments - Syntax Highlighting in HTML

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

Modul laden:

    use Quiq::Html::Pygments;

Liefere die CSS-Regeln für Pygments-Style 'emacs', eingeschränkt
auf einen Container 'highlight', der den gehighlighteten Code
aufnimmt:

    ($rules,$bgColor) = Quiq::Html::Pygments->css('emacs','highlight');
    # .highlight .hll { background-color: #ffffcc }
    # ...
    # #f8f8f8

Erzeuge Syntax-Highlighting für Perl-Code $code. Der gelieferte
HTML-Code $html muss in einen Container 'highlight' (s.o.)
eingebettet werden, damit die oben erzeugten CSS-Regeln greifen:

    $html = Quiq::Html::Pygments->html('perl',$code);

Liefere die Namen aller Pygments-Styles:

    @styles = Quiq::Html::Pygments->styles;

Liefere eine HTML-Seite mit einem Darstellungsbeispiel
für jeden Pygments-Style. Gehighlightet wird der Code $code
der Programmiersprache $lang:

    $html = Quiq::Html::Pygments->stylesPage($h,$lang,$code);

=head1 DESCRIPTION

Diese Klasse stellt eine Schnittstelle zum Pygments Syntax
Highlighting Paket dar, speziell zum Syntax Highlighting in HTML.
Die Methoden der Klassen liefern die CSS-Regeln und den HTML-Code,
um gehighlighteten Quelltext in HTML-Seiten integrieren zu können.

=head1 METHODS

=head2 Klassenmethoden

=head3 css() - CSS-Information für Highlighting in HTML

=head4 Synopsis

    ($rules,$bgColor) | $rules = $class->css;
    ($rules,$bgColor) | $rules = $class->css($style);
    ($rules,$bgColor) | $rules = $class->css($style,$selector);

=head4 Arguments

=over 4

=item $style (Default: 'default')

Name des Pygments-Style, für den die CSS-Information geliefert wird.

Mögliche Werte: abap, algol, algol_nu, arduino, autumn, borland,
bw, colorful, default, emacs, friendly, fruity, igor, lovelace,
manni, monokai, murphy, native, paraiso-dark, paraiso-light,
pastie, perldoc, rainbow_dash, rrt, tango, trac, vim, vs, xcode.

Die definitiv gültige Liste der Stylenamen liefert die Methode
styles().

=item $selector (Default: I<kein zusätzlicher Selektor>)

Zusätzlicher CSS-Selektor, der den CSS-Regeln vorangestellt
wird. Der Selektor schränkt den Gültigkeitsbereich der CSS-Regeln
auf ein Parent-Element ein. Ist kein Selektor angegeben, gelten
die CSS-Regeln global.

=back

=head4 Returns

CSS-Regeln und Hintergrundfarbe (String, String). Im Skalarkontext
werden nur die CSS-Regeln geliefert.

=head4 Description

Liefere die CSS-Regeln für die Vordergrund-Darstellung von
Syntax-Elementen und die zugehörige Hintergrundfarbe für
Pygments-Style $style.

=head4 Example

Gib die CSS-Regeln für den Pyments-Style 'emacs' aus:

    print scalar Quiq::Html::Pygments->css('emacs');
    __END__
    .hll { background-color: #ffffcc }
    .c { color: #008800; font-style: italic } /* Comment */
    .err { border: 1px solid #FF0000 } /* Error */
    .k { color: #AA22FF; font-weight: bold } /* Keyword */
    .o { color: #666666 } /* Operator */

Gib die CSS-Regeln für den Pyments-Style 'emacs' und
Parent-Elemente der Klasse 'highlight' aus:

    print scalar Quiq::Html::Pygments->css('emacs','.syntax');
    __END__
    .syntax .hll { background-color: #ffffcc }
    .syntax .c { color: #008800; font-style: italic } /* Comment */
    .syntax .err { border: 1px solid #FF0000 } /* Error */
    .syntax .k { color: #AA22FF; font-weight: bold } /* Keyword */
    .syntax .o { color: #666666 } /* Operator */

=cut

# -----------------------------------------------------------------------------

sub css {
    my $class = shift;
    my $style = shift // 'default';
    my $selector = shift // 'D-U-M-M-Y';

    my $c = Quiq::CommandLine->new('pygmentize');
    $c->addOption(
        -f => 'html',
        -S => $style,
        -a => $selector,
    );

    my $rules = Quiq::Shell->exec($c->command,-capture=>'stdout');

    # Bestimme Hintergrundfarbe, diese muss existieren, da die
    # Forderungrundfarben darauf abgestimmt sind.

    $rules =~ s/^$selector\s*\{.*background:\s*(\S+);.*\n//m;
    my $bgColor = $1;
    if (!$bgColor) {
        $class->throw(
            'PYG-00001: Can\'t determine main background-color',
            Style => $style,
            CssRules => $rules,
        );
    }

    if ($selector eq 'D-U-M-M-Y') {
        # Entferne Dummy-Selektor aus den CSS-Regeln
        $rules =~ s/^$selector\s+//mg;
    }

    return wantarray? ($rules,$bgColor): $rules;
}

# -----------------------------------------------------------------------------

=head3 html() - Quellcode in HTML highlighten

=head4 Synopsis

    $html = $class->html($lang,$code);

=head4 Arguments

=over 4

=item $lang

Die Sprache des Quelltexts $code. In Pygments-Terminiologie
handelt es sich um den Namen eines "Lexers". Die Liste aller
Lexer liefert das Kommando:

    $ pygmentize -L lexers

=item $code

Der Quelltext, der gehighlightet wird.

=back

=head4 Returns

HTML-Code mit gehighlightetem Quelltext (String)

=head4 Description

Liefere den HTML-Code mit dem Syntax-Highlighting für Quelltext $code
der Sprache $lang.

=cut

# -----------------------------------------------------------------------------

sub html {
    my ($class,$lang,$code) = @_;

    # Quelltext highlighten

    my $c = Quiq::CommandLine->new('pygmentize');
    $c->addOption(
        -f => 'html',
        -l => $lang, # = lexer
    );
    my $html = Quiq::Ipc->filter($c->command,$code);

    # Nicht benötigte "Umrahmung" des gehighlighteten Code entfernen

    $html =~ s|^<div.*?><pre>(<span></span>)?||;
    $html =~ s|</pre></div>\s*$||;

    return $html;
}

# -----------------------------------------------------------------------------

=head3 styles() - Liste der Pygments-Styles

=head4 Synopsis

    @styles | $styleA = $class->styles;

=head4 Returns

Liste von Pygments Stylenamen (Array of Strings).

=head4 Description

Ermittele die Liste der Namen aller Pygments-Styles und liefere diese
zurück. Im Skalarkontext liefere ein Referenz auf die Liste.

Interaktiv lässt sich die (kommentierte) Liste aller Styles
ermitteln mit:

    $ pygmentize -L styles

=cut

# -----------------------------------------------------------------------------

sub styles {
    my $class = shift;

    # Styles ermitteln

    my $c = Quiq::CommandLine->new('pygmentize');
    $c->addOption(
        -L => 'styles',
    );
    my $text = Quiq::Shell->exec($c->command,-capture=>'stdout');
    my @styles = sort $text =~ /^\* (\S+?):/mg;

    return wantarray? @styles: \@styles;
}

# -----------------------------------------------------------------------------

=head3 stylesPage() - HTML-Seite mit allen Styles

=head4 Synopsis

    $html = $class->stylesPage($h,$lang,$code);

=head4 Arguments

=over 4

=item $h

HTML-Generator.

=item $lang

Die Sprache des Quelltexts $code (siehe auch Methode html()).

=item $code

Beispiel-Quelltext der Sprache $lang.

=back

=head4 Returns

HTML-Seite (String)

=head4 Description

Erzeuge für Codebeispiel $code der Sprache (des "Lexers") $lang
eine HTML-Seite mit allen Pygments-Styles und liefere diese
zurück.

Diese Seite bietet Hilfestellung für die Entscheidung, welcher
Style am besten passt.

=head4 Example

Generiere eine Seite mit allen Styles und schreibe sie auf Datei $file:

    my $h = Quiq::Html::Tag->new;
    my $html = Quiq::Html::Pygments->stylesPage($h,'perl',q~
        PERL-CODE
    ~));
    Quiq::Path->write($file,$html);

=cut

# -----------------------------------------------------------------------------

sub stylesPage {
    my ($class,$h,$lang,$code) = @_;

    $code = Quiq::Unindent->trimNl($code);

    my $css = Quiq::Css->new('flat');

    my ($rules,$html);
    $rules .= $css->rule('td pre',
        margin => 0,
    );
    for my $style ($class->styles) {
        my ($styleRules,$bgColor) = $class->css($style,".$style");
        $rules .= $css->rule(".$style",
            backgroundColor => $bgColor,
            border => '1px solid #e0e0e0',
            marginLeft => '1em',
            padding => '4px',
        );
        $rules .= $styleRules;

        $html .= $h->tag('h3',$style);
        $html .= Quiq::Html::Table::Simple->html($h,
            class => $style,
            rows => [[[$h->tag('pre',$class->html($lang,$code))]]],
        );
    }

    return Quiq::Html::Page->html($h,
        title => 'Pygments Styles',
        styleSheet => $rules,
        body => $html,
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.147

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
