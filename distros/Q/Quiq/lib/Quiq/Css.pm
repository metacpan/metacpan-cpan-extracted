# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Css - Generiere CSS Code

=head1 BASE CLASS

L<Quiq::Hash>

=head1 ATTRIBUTES

=over 4

=item format => 'normal', 'flat' (Default: 'normal')

Format des generierten CSS-Code.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Css;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Path;
use Quiq::String;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere CSS-Generator

=head4 Synopsis

  $css = $class->new;
  $css = $class->new($format);

=head4 Arguments

=over 4

=item $format (Default: 'normal')

Format des generierten CSS-Code. Zulässige Werte:

=over 4

=item 'normal'

=back

Der CSS-Code wird mehrzeilig generiert:

  .comment {
      color: #408080;
      font-style: italic;
  }

=over 4

=item 'flat'

=back

Der CSS-Code wird einzeilig generiert:

  .comment { color: #408080; font-style: italic; }

=back

=head4 Returns

Referenz auf CSS-Generator-Objekt.

=head4 Description

Instantiiere ein CSS-Generator-Objekt und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$format) = @_;

    my $self = $class->SUPER::new(
        format => $format // 'normal',
    );

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 properties() - Zeichenkette aus CSS Properties

=head4 Synopsis

  $properties = $this->properties(@properties);
  $properties = $this->properties(\@properties);

=head4 Description

Generiere aus den Property/Wert-Paaren @properties eine
Zeichenkette aus CSS Properties. Ist die Liste der
Property/Wert-Paare leer oder haben alle Schlüssel keinen Wert
(C<undef> oder Leerstring) liefere C<undef> (keinen Leerstring,
damit von der Methode tag() kein style-Attribut mit Leerstring
erzeugt wird!).

Diese Methode ist nützlich, wenn der Wert eines HTML
style-Attributs erzeugt werden soll. Wenn als Wert des Attributs
C<style> eines Quiq::Html::Tag eine Array-Referenz angegeben
wird, wird diese Methode gerufen.

=head4 Example

Erzeuge Properties für HTML style-Attribut:

  $properties = Quiq::Css->properties(
      fontStyle => 'italic',
      marginLeft => '0.5cm',
      marginRight => '0.5cm',
  );

liefert

  font-style: italic; margin-left: 0.5cm; margin-right: 0.5cm;

=cut

# -----------------------------------------------------------------------------

sub properties {
    my $this = shift;
    my $propertyA = ref $_[0]? shift: \@_;

    my $self = ref $this? $this: $this->new('flat');
    my $sep = $self->{'format'} eq 'flat'? ' ': "\n";

    my $code;
    for (my $i = 0; $i < @$propertyA; $i += 2) {
        my $key = $propertyA->[$i];
        my $val = $propertyA->[$i+1];

        $key =~ s/([a-z])([A-Z])/$1-\L$2/g;

        if (defined $val && $val ne '') {
            if ($code) {
                $code .= $sep;
            }
            $code .= "$key: $val;";
        }
    }

    return $code;
}

# -----------------------------------------------------------------------------

=head3 rule() - Generiere CSS Style Rule

=head4 Synopsis

  $rule = $this->rule($selector,\@properties);
  $rule = $this->rule($selector,@properties);

=head4 Description

Generiere eine CSS Style Rule, bestehend aus Selector $selector
und den Property/Value-Paaren @properties und liefere diese als
Zeichenkette zurück. Ist die Liste der Properties leer oder haben
alle Schlüssel keinen Wert (C<undef> oder Leerstring) liefere
einen Leerstring ('').

=head4 Example

Erzeuge eine einfache Style Rule:

  $rule = Quiq::Css->rule('p.abstract',
      fontStyle => 'italic',
      marginLeft => '0.5cm',
      marginRight => '0.5cm',
  );

liefert

  p.abstract {
      font-style: italic;
      margin-left: 0.5cm;
      margin-right: 0.5cm;
  }

=cut

# -----------------------------------------------------------------------------

sub rule {
    my $this = shift;
    my $selector = shift;
    my $propertyA = ref $_[0]? shift: \@_;

    my $self = ref $this? $this: $this->new;
    
    my $rule = $self->properties($propertyA) // '';
    if ($rule) {
        if ($self->{'format'} eq 'flat') {
            $rule = "$selector { $rule }\n";
        }
        else {
            $rule =~ s/^/    /mg;
            $rule = "$selector {\n$rule\n}\n";
        }
    }

    return $rule;
}

# -----------------------------------------------------------------------------

=head3 rules() - Generiere mehrere CSS Style Rules

=head4 Synopsis

  $rules = $css->rules($selector=>\@properties,...);

=head4 Arguments

=over 4

=item $selector

CSS-Selector. Z.B. 'p.abstract'.

=item \@properties

Liste von Property/Wert-Paaren. Z.B. [color=>'red',fontStyle=>'italic'].

=back

=head4 Returns

CSS-Regeln (String)

=head4 Description

Wie $css->rule(), nur für mehrere CSS-Regeln auf einmal.

=cut

# -----------------------------------------------------------------------------

sub rules {
    my $self = shift;
    # @_: $selector=>\@properties,...

    my $rules = '';
    while (@_) {
        $rules .= $self->rule(shift,shift);
    }

    return $rules;
}

# -----------------------------------------------------------------------------

=head3 restrictedRules() - Generiere lokale CSS Style Rules

=head4 Synopsis

  $rules = $css->restrictedRules($localSelector,
      $selector => \@properties,
      ...
  );

=head4 Arguments

=over 4

=item $localSelector

Selector, der allen folgenden Selektoren vorangestellt wird.
Z.B. '#table01'.

=item $selector

Sub-Selector, der dem $localSelector mit einem Leerzeichen
getrennt, nachgestellt wird. Wenn Leerstring (''), wird der
Sub-Selector fortgelassen, die @properties also direkt dem
$localSelector zugeordnet. Beginnt $selector mit einem
Kaufmanns-Und (&), werden $localSelector und $selector ohne
trennendes Leerzeichen konkateniert (gleiche Logik wie bei Sass).

=item \@properties

Liste von Property/Wert-Paaren. Z.B. [color=>'red',fontStyle=>'italic'].

=back

=head4 Returns

CSS-Regeln (String)

=head4 Description

Wie $css->rules(), nur mit zusätzlicher Einschränkung auf einen
lokalen Selektor.

=cut

# -----------------------------------------------------------------------------

sub restrictedRules {
    my $self = shift;
    my $localSelector = shift;
    # @_: $selector=>\@properties,...

    my $rules = '';
    while (@_) {
        my $selector = shift;
        if (substr($selector,0,1) eq '&') {
            substr($selector,0,1) = '';
            $selector = $localSelector.$selector;
        }
        elsif ($selector eq '') {
            $selector = $localSelector;
        }
        else {
            $selector = "$localSelector $selector";
        }
        $rules .= $self->rule($selector,shift);
    }

    return $rules;
}

# -----------------------------------------------------------------------------

=head3 rulesFromObject() - Generiere CSS Style Rules aus Objekt-Attributen

=head4 Synopsis

  $rules = $css->rulesFromObject($obj,
      $key => [$selector,@properties],
      ...
  );

=head4 Arguments

=over 4

=item $obj

Das Objekt, aus dessen Objektattributen $key, ... die
CSS-Regeln generiert werden.

=item $key => [$selector,@properties], ...

Liste der Objekt-Attribute $key, ..., ihre entsprechenden
Selektoren und Default-Properties.

=back

=head4 Returns

CSS-Regeln (String)

=head4 Description

Die Methode erzeugt CSS-Regeln auf Basis von Objekt-Attributen.
Jedes Attribut entspricht einem CSS-Selektor und definiert dessen
Properties. Es können Default-Properties hinterlegt werden, die
der Aufrufer ergänzen ('+' als erstes Element der Property-Liste)
oder ersetzen oder löschen kann (siehe Example).

=head4 Example

B<< Beispiel aus Quiq::Html::Verbatim >>

Im Konstruktor werden die Objekt-Attribute vereinbart. Diese
können bei der Instantiierung des Objektes gesetzt werden.

  my $self = $class->SUPER::new(
      cssTableProperties => undef,
      cssLnProperties => undef,
      cssMarginProperties => undef,
      cssTextProperties => undef,
      ...
  );

In der Methode, die die CSS-Regeln erzeugt, werden die zugehörigen
Selektoren und Default-Properties vereinbart.

  $rules .= $css->rulesFromObject($self,
      cssTableProperties => [".xxx-table"],
      cssLnProperties => [".xxx-ln",color=>'#808080'],
      cssMarginProperties => [".xxx-margin",width=>'0.6em'],
      cssTextProperties => [".xxx-text"],
  );

Beim Konstruktor-Aufruf können die Default-Properties ergänzt ('+'
als erstes Element in der Property-Liste) oder ersetzt (keine
Angabe) oder gelöscht werden (leere Liste).

  my $obj = Quiq::Hash->new(
      cssTableProperties => [backgroundColor=>'#f0f0f0'],  # ersetzen
      cssLnProperties => ['>',color=>'black'],             # ersetzen
      cssMarginProperties => ['+',backgroundColor=>'red'], # ergänzen
      cssTextProperties => [],                             # löschen
  );

Resultierende CSS-Regeln:

  .xxx-table { background-color: #f0f0f0; }
  .xxx-ln { color: black; }
  .xxx-margin { width: 0.6em; background-color: red; }

=cut

# -----------------------------------------------------------------------------

sub rulesFromObject {
    my $self = shift;
    my $obj = shift;
    # @_: $key => [$selector,@properties], ...

    my $rules = '';
    for (my $i = 0; $i < @_; $i += 2) {
        my $key = $_[$i];
        my ($selector,@defaults) = @{$_[$i+1]};
        my $propA = $obj->get($key);

        my (@prop,$op);
        if ($propA) {
            @prop = @$propA;
            if (@prop % 2 == 1) {
                $op = shift @prop;
            }
        }
        if (!$propA || defined($op) && $op eq '+') {
            unshift @prop,@defaults;
        }
        $rules .= $self->rule($selector,@prop);
    }

    return $rules;
}

# -----------------------------------------------------------------------------

=head2 Klassenmethoden

=head3 makeFlat() - Mache CSS-Regeln einzeilig

=head4 Synopsis

  $rules = $this->makeFlat($rules);

=head4 Arguments

=over 4

=item $rules

CSS-Regeln (String)

=back

=cut

# -----------------------------------------------------------------------------

sub makeFlat {
    my ($this,$rules) = @_;

    $rules =~ s/\s+/ /g;
    $rules =~ s/\} /}\n/g;

    return $rules;
}

# -----------------------------------------------------------------------------

=head3 oneLine() - Mache CSS-Code insgesamt einzeilig

=head4 Synopsis

  $cssCode = $this->oneLine($cssCode);

=head4 Arguments

=over 4

=item $cssCode

(String) CSS-Code als Text (Content des style-Tag).

=back

=cut

# -----------------------------------------------------------------------------

sub oneLine {
    my ($this,$css) = @_;

    $css =~ s/\s+/ /g;

    return $css;
}

# -----------------------------------------------------------------------------

=head3 style() - Generiere StyleSheet-Tags

=head4 Synopsis

  $styleTags = Quiq::Css->style($h,@specs);

=head4 Arguments

=over 4

=item @specs

Liste von Style-Spezifikationen.

=back

=head4 Description

Übersetze die Style-Spezifikationen @specs in eine Folge von
<link>- und/oder <style>-Tags.

Mögliche Style-Spezifikationen:

=over 4

=item "inline:$file":

Datei $file wird geladen und ihr Inhalt wird hinzugefügt.

=item $string (Zeichenkette mit enthaltenen '{')

Zeichenkette $string wird hinzugefügt.

=item $url (Zeichenkette ohne '{'):

Zeichenkette wird als URL interpretiert und ein <link>-Tag

  <link rel="stylesheet" type="text/css" href="$url" />

hinzugefügt.

=item \@specs (Arrayreferenz):

Wird zu @specs expandiert.

=back

=head4 Example

B<Code zum Laden eines externen Stylesheet:>

  $style = Quiq::Css->style('/css/stylesheet.css');
  =>
  <link rel="stylesheet" type="text/css" href="/css/stylesheet.css" />

B<Stylesheet aus Datei einfügen:>

  $style = Quiq::Css->style('inline:/css/stylesheet.css');
  =>
  <Inhalt der Datei /css/stylesheet.css>

B<Mehrere Stylesheet-Spezifikationen:>

  $style = Quiq::Css->style(
      '/css/stylesheet1.css'
      '/css/stylesheet2.css'
  );
  =>
  <link rel="stylesheet" type="text/css" href="/css/stylesheet1.css" />
  <link rel="stylesheet" type="text/css" href="/css/stylesheet2.css" />

B<Mehrere Stylesheet-Spezifikationen via Arrayreferenz:>

  $style = Quiq::Css->style(
      ['/css/stylesheet1.css','/css/stylesheet2.css']
  );

Dies ist nützlich, wenn die Spezifikation von einem Parameter
einer umgebenden Methode kommt.

=cut

# -----------------------------------------------------------------------------

sub style {
    my $class = shift;
    my $h = shift;
    # @_: @spec

    my $linkTags = '';
    my $style = '';

    while (@_) {
        my $spec = shift;

        if (ref $spec) {
            unshift @_,@$spec;
            next;
        }
        elsif (!defined $spec || $spec eq '') {
            next;
        }
        elsif ($spec =~ s/^inline://) {
            my $data = Quiq::Path->read($spec);
            # FIXME: Optional Kommentare entfernen

            # Leerzeilen entfernen
            $data =~ s|\n\s*\n+|\n|g;

            # /* eof */ und Leerzeichen am Ende entfernen

            $data =~ s|\s+$||;
            $data =~ s|\s*/\* eof \*/$||;

            $style .= "$data\n";
        }
        elsif ($spec =~ /\{/) {
            # Stylesheet-Definitionen, wenn { enthalten
            Quiq::String->removeIndentation(\$spec);
            $style .= "$spec\n";
        }
        else {
            $linkTags .= $h->tag('link',
                rel => 'stylesheet',
                type => 'text/css',
                href => $spec,
            );
        }
    }
    
    return $h->cat(
        $linkTags,
        $h->tag('style',
            -ignoreIfNull => 1,
            $style
        ),
    );
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
