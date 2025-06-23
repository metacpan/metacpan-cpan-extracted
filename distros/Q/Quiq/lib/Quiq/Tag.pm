# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Tag - Erzeuge Markup-Code gemäß XML-Regeln

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

=head3 Modul laden und Objekt instantiieren

  use Quiq::Tag;
  
  my $p = Quiq::Tag->new;

=head3 Tag ohne Content

  $code = $p->tag('person',
      firstname => 'Lieschen',
      lastname => 'Müller',
  );

liefert

  <person firstname="Lieschen" lastname="Müller" />

=head3 Tag mit Content

  $code = $p->tag('bold','sehr schön');

liefert

  <bold>sehr schön</bold>

Enthält der Content, wie hier, keine Zeilenumbrüche, werden Begin-
und End-Tag unmittelbar um den Content gesetzt. Andernfalls wird
der Content eingerückt mehrzeilig zwischen Begin- und End-Tag
gesetzt. Siehe nächstes Beispiel.

=head3 Tag mit Unterstruktur

  $code = $p->tag('person','-',
      $p->tag('firstname','Lieschen'),
      $p->tag('lastname','Müller'),
  );

erzeugt

  <person>
    <firstname>Lieschen</firstname>
    <lastname>Müller</lastname>
  </person>

Das Bindestrich-Argument (C<'-'>) bewirkt, dass die nachfolgenden
Argumente zum Content des Tag konkateniert werden. Die umständlichere
Formulierung wäre:

  $code = $p->tag('person',$p->cat(
      $p->tag('firstname','Lieschen'),
      $p->tag('lastname','Müller'),
  ));

=head1 DESCRIPTION

Ein Objekt der Klasse erzeugt Markup-Code gemäß den Regeln von XML.
Mit den beiden Methoden L<tag|"tag() - Erzeuge Tag-Code">() und L<cat|"cat() - Füge Sequenz zusammen">() kann Markup-Code
beliebiger Komplexität erzeugt werden.

=cut

# -----------------------------------------------------------------------------

package Quiq::Tag;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Unindent;
use Quiq::String;
use Quiq::Template;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Instantiierung

=head3 new() - Konstruktor

=head4 Synopsis

  $p = $class->new;

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    return $class->SUPER::new;
}

# -----------------------------------------------------------------------------

=head2 Generierung

=head3 tag() - Erzeuge Tag-Code

=head4 Synopsis

  $code = $p->tag($elem,@opts,@attrs);
  $code = $p->tag($elem,@opts,@attrs,$content);
  $code = $p->tag($elem,@opts,@attrs,'-',@content);

=head4 Arguments

=over 4

=item $elem

Name des Elements.

=item @opts

Optionen. Siehe unten.

=item @attrs

Element-Attribute und ihre Werte.

=item $content

Inhalt des Tag.

=item @contents

Sequenz von Inhalten.

=back

=head4 Options

=over 4

=item -defaults => \@keyVals (Default: undef)

Liste der Default-Attribute und ihrer Werte. Ein Attribut in
@keyVals, das nicht unter den Attributen @attrs des Aufrufs
vorkommt, wird auf den angegebenen Defaultwert gesetzt.

=item -elements => \%elements (Default: undef)

Hash, der die Default-Formatierung und Default-Attribute von
Elementen definiert. Aufbau:

  %elements = (
      $elem => [$fmt,\@keyVals],
      ...
  )

Der Hash muss nicht jedes Element definieren. Nicht-vorkommende
Elemente gemäß Default-Formatierung formatiert (siehe -fmt)
besitzen keine Default-Attribute.

=item -fmt => 'c'|'e'|'E'|'i'|'m'|'p'|'P'|'v' (Default: gemäß $elem)

Art der Content-Formatierung.

=over 4

=item 'c' (cdata):

Wie 'm', nur dass der Content in CDATA eingefasst wird
(in HTML: script):

  <TAG ...>
    // <![CDATA[
    CONTENT
    // ]]>
  </TAG>\n

=item 'e' (empty):

Element hat keinen Content (in HTML: br, hr, ...):

  <TAG ... />\n

=item 'E' (empty, kein Newline):

Wie 'e', nur ohne Newline am Ende (in HTML: img, input, ...):

  <TAG ... />

=item 'i' (inline):

Der Content wird belassen wie er ist. Dies ist nützlich für
Tags, die in Fließtext eingesetzt werden. Ein Newline wird
nicht angehängt.

  Text Text <TAG ...>Text Text
  Text</TAG> Text Text

(in HTML: a, b, span, ...)

=item 'm' (multiline):

Content wird auf eigene Zeile(n) zwischen Begin- und End-Tag
gesetzt und um -ind=>$n Leerzeichen eingerückt:

  <TAG ...>
    CONTENT
  </TAG>\n

Ist der Content leer, wird nur ein End-Tag gesetzt:

  <TAG ... />\n

=item 'M' (multiline, ohne Einrückung):

Wie 'm', nur ohne Einrückung (in HTML: html, ...):

  <TAG ...>
  CONTENT
  </TAG>\n

=item 'p' (protect):

Der Content wird geschützt, indem dieser einzeilig gemacht
(LF und CR werden durch &#10; und &#13; ersetzt) und unmittelbar
zwischen Begin- und End-Tag gesetzt wird
(in HTML: pre, textarea, ...):

  <TAG ...>CONTENT</TAG>\n

=item 'P' (protect, Einrückung entfernen):

Wie 'p', nur dass die Einrückung des Content entfernt wird.

=item 'v' (variable) = Default-Formatierung:

Ist der Content einzeilig, wird er unmittelbar zwischen Begin-
und End-Tag gesetzt:

  <TAG ...>CONTENT</TAG>\n

Ist der Content mehrzeilig, wird er eingerückt:

  <TAG ...>
    CONTENT
  </TAG>\n

(in HTML: title, h1-h6, ...)

=back

=item -nl => $n (Default: 1)

Anzahl Newlines am Ende.

-nl => 0 (kein Newline):

  <TAG>CONTENT</TAG>

-nl => 1 (ein Newline):

  <TAG>CONTENT</TAG>\n

-nl => 2 (zwei Newlines):

  <TAG>CONTENT</TAG>\n\n

usw.

=item -placeholders => \@keyVal (Default: undef)

Ersetze im erzeugten Code die angegebenen Platzhalter
durch ihre Werte.

=back

=head4 Description

Erzeuge den Code eines Tag und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub tag {
    my ($self,$elem) = splice @_,0,2;

    # MEMO: Dies ist eine abgespeckte Variante der Methode tag() in
    # Quiq::Html::Tag. Etwaige Ergänzungen, die hier gebraucht
    # werden, von dort übernehmen.

    # Optionen

    my $contentInd = undef;
    my $defaultA = undef;
    my $fmt = 'v';
    my $ind = 2;
    my $nl = 1;
    my $placeholderA = undef;

    # Attribute
    my @attrs;

    # Parameter verarbeiten

    while (@_) {
        if (@_ == 1) {
            # Letzter Parameter ist Content. Dieser Test muss als erstes
            # kommen, damit '-' als Content nicht unter den Tisch fällt.
            last;
        }
        elsif (defined $_[0] && $_[0] eq '-') {
            # Explizites Ende der Options- und Attributliste
            shift; # '-' konsumieren
            last;
        }

        # Optionen

        my $key = shift;
        if (substr($key,0,1) eq '-') {
            if ($key eq '-elements') {
                if (my $defA = shift->{$elem}) {
                    ($fmt,$defaultA) = @$defA;
                }
            }
            elsif ($key eq '-defaults') {
                $defaultA = shift;
            }
            elsif ($key eq '-fmt') {
                $fmt = shift;
            }
            elsif ($key eq '-nl') {
                $nl = shift;
            }
            elsif ($key eq '-placeholders') {
                $placeholderA = shift;
            }
            else {
                $self->throw(
                    'TAG-00001: Unknown option',
                    Option => $key,
                );
            }
            next;
        }

        # Attribute
        push @attrs,$key,shift;
    }

    # Defaultattribute setzen

    if ($defaultA) {
        # Hash der Defaultattribute erstellen
        my %defaults = @$defaultA;

        # Gesetzte Attribute aus der Betrachtung nehmen

        for (my $i = 0; $i < @attrs; $i += 2) {
            delete $defaults{$attrs[$i]};
        }

        # Defaultattribute setzen

        for (my $i = 0; $i < @$defaultA; $i += 2) {
            if (exists $defaults{$defaultA->[$i]}) {
                push @attrs,$defaultA->[$i],$defaultA->[$i+1];
            }
        }
    }

    # Content

    my $content = $self->cat(@_);

    if ($fmt eq 'p' || $fmt eq 'P') {
        if ($fmt eq 'P') {
            $content = Quiq::Unindent->trim($content);
        }
        $content =~ s/\x0a/&#10;/g;
        $content =~ s/\x0d/&#13;/g;
    }
    elsif ($fmt eq 'e' || $fmt eq 'E') {
        if (length $content) {
            $self->throw(
                'TAG-00003: No content expected',
                Content => $content,
            );
        }
    }
    elsif ($fmt eq 'i' || $fmt eq 'v' && $content !~ /\n/) {
        # nichts tun
    }
    elsif ($fmt eq 'v' || $fmt eq 'm' || $fmt eq 'c') {
        $content = Quiq::Unindent->trim($content);
        if ($contentInd) {
            # Bringe Einrückung des Content auf Tiefe $contendInd
            Quiq::String->reduceIndentation($contentInd,\$content);
        }
        if ($fmt eq 'c' && $content =~ tr/&<>//) {
            # Script-Code in CDATA einfassen, wenn &, < oder > enthalten sind
            $content = "// <![CDATA[\n$content\n// ]]>";
        }
        if ($ind) {
            my $space = ' ' x $ind;
            $content =~ s/^(?!$)/$space/gm; # Leerzeilen nicht einrücken
        }
        if ($content ne '') {
            $content = "\n$content\n";
        }
    }
    else {
        $self->throw(
            'TAG-00004: Unknown format (-fmt)',
            Value => $fmt,
        );
    }

    # Tag erzeugen

    my $code = "<$elem";
    while (@attrs) {
        my ($key,$val) = splice @attrs,0,2;
        if (defined $val) {
            $val =~ s/"/&quot;/g;
            $code .= qq| $key="$val"|;
        }
    }
    $code .= $content ne ''? ">$content</$elem>": ' />';

    # Platzhalter ersetzen

    if ($placeholderA) {
        my $tpl = Quiq::Template->new('text',\$code);
        $tpl->replace(@$placeholderA);
        $code = $tpl->asString;
    }

    # Newlinw
    $code .= "\n" x $nl;

    return $code;
}

# -----------------------------------------------------------------------------

=head3 cat() - Füge Sequenz zusammen

=head4 Synopsis

  $code = $p->cat(@opt,@args);

=head4 Arguments

=over 4

=item @args

Sequenz von Werten.

=back

=head4 Options

=over 4

=item -placeholders => \@keyVal

Ersetze im generierten Code die angegebenen Platzhalter durch
die angegebenen Werte.

=back

=head4 Description

Füge die Arguments @args zusammen und liefere den resultierenden
Code zurück.

=cut

# -----------------------------------------------------------------------------

sub cat {
    my $self = shift;

    # Optionen

    my $placeholderA = undef;

    while (@_) {
        if (!defined $_[0]) {
            last;
        }
        elsif ($_[0] eq '-') {
            # explizites Ende der Optionen
            shift; # '-' konsumieren
            last;
        }
        elsif ($_[0] eq '-placeholders') {
            $placeholderA = splice @_,0,2;
            next;
        }
        last;
    }

    # Argumente konkatenieren

    my $code = join '',@_;

    # Platzhalter ersetzen

    if ($placeholderA) {
        my $tpl = Quiq::Template->new('text',\$code);
        $tpl->replace(@$placeholderA);
        $code = $tpl->asStringNL;
    }

    return $code;
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
