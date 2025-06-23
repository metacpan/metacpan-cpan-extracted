# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::JavaScript - Generierung von JavaScript-Code

=head1 BASE CLASS

L<Quiq::Object>

=cut

# -----------------------------------------------------------------------------

package Quiq::JavaScript;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Template;
use Quiq::Path;
use Scalar::Util ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $p = $class->new;

=head4 Returns

JavaScript-Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück. Da die Klasse ausschließlich Klassenmethoden
enthält, hat das Objekt ausschließlich die Funktion, eine abkürzende
Aufrufschreibweise zu ermöglichen.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    return bless \(my $dummy),$class;
}

# -----------------------------------------------------------------------------

=head3 code() - Erstelle JavaScript-Code in Perl

=head4 Synopsis

  $js = $this->code(@keyVal,$text);

=head4 Arguments

=over 4

=item @keyVal

Liste von Platzhalter/Wert-Paaren. Die Platzhalter beginnen
und enden mit zwei Unterstrichen.

=item $text

JavaScript-Code mit Platzhaltern (String)

=back

=head4 Returns

JavaScript-Code (String)

=head4 Description

Setze die Platzhalter/Wert-Paare @keyVal in den JavaScript-Code $text
ein und liefere den resultierenden JavaScript-Code zurück. Als
Zeilenfortsetzungszeichen kann eine Tilde (~) verwendet werden
(Achtung: dann darf $text nicht mit q~...~ gequotet werden).

Die Methode ist vor allem nützlich, wenn der JavaScript-Code
jQuery-Aufrufe mit Dollar-Zeichen ($) enthält oder die Zeilen
überlang sind.

=head4 Example

  $js = $this->code(q°
      var __NAME__ = (function() {
          return {
              x: __VALUE__,
          };
      })();°,
      __NAME__ => 'dgr',
      __VALUE__ => 4711,
  );

liefert

  var dgr = (function() {
      return {
          x: 4711,
      };
  })();

=cut

# -----------------------------------------------------------------------------

sub code {
    my $this = shift;
    my $text = shift;
    # @_: @keyVal

    return Quiq::Template->combine(
        placeholders => \@_,
        template => $text,
    );
}

# -----------------------------------------------------------------------------

=head3 line() - Mache JavaScript-Code einzeilig

=head4 Synopsis

  $line = $this->line($code);

=head4 Arguments

=over 4

=item $code

Mehrzeiliger JavaScript-Code (String)

=back

=head4 Returns

JavaScript-Code einzeilig (String)

=head4 Description

Wandele mehrzeiligen JavaScript-Code in einzeiligen JavaScript-Code
und liefere diesen zurück. Die Methode ist nützlich, wenn formatierter,
mehrzeiliger JavaScript-Code in ein HTML Tag-Attribut (JavaScript-Handler
wie onclick="..." oder onchange="...") eingesetzt werden soll.

=head4 Example

Aus

  var s = '';
  for (var i = 0; i < 10; i++)
      s += 'x';

wird

  var s = ''; for (var i = 0; i < 10; i++) s += 'x';

=head4 Details

Die Regeln der Umwandlung:

=over 2

=item *

ist $code C<undef>, wird C<undef> geliefert

=item *

Kommentare (\s*//.*) werden entfernt

=item *

Leerzeilen und Zeilen nur aus Whitespace werden entfernt

=item *

Whitespace (einschl. Zeilenumbruch) am Anfang und am Ende
jeder Zeile wird entfernt

=item *

alle Zeilen werden mit einem Leerzeichen als Trenner konkateniert

=back

Damit dies sicher funktioniert, muss jede JavaScript-Anweisung
mit einem Semikolon am Zeilenende beendet werden und darf nicht,
wie JavaScipt es auch erlaubt, weggelassen werden.

=cut

# -----------------------------------------------------------------------------

sub line {
    my ($this,$code) = @_;

    if (!defined $code) {
        return undef;
    }

    my $line = '';
    open my $fh,'<',\$code or $this->throw;
    while (<$fh>) {
        s~(^|\s+)//.*~~; # Kommentar entfernen
        s/^\s+//;
        s/\s+$//;
        next if $_ eq '';

        if ($line ne '') {
            $line .= ' ';
        }
        $line .= $_;
    }
    close $fh;

    return $line;
}

# -----------------------------------------------------------------------------

=head3 script() - Generiere einen oder mehrere <script>-Tags

=head4 Synopsis

  $html = Quiq::JavaScript->script($h,@specs);

=head4 Arguments

=over 4

=item @specs

Liste von Script-Spezifikationen.

=back

=head4 Description

Übersetze die Code-Spezifikationen @specs in einen oder mehrere
Script-Tags.

Mögliche Code-Spezifikationen:

=over 4

=item "inline:$file":

Datei $file wird geladen und ihr Inhalt wird in einen Script-Tag
eingefasst.

=item $string (Zeichenkette mit runden Klammern oder Leerzeichen)

Zeichenkette $string wird in einen Script-Tag eingefasst.

=item $url (Zeichenkette ohne runde Klammern oder Leerzeichen):

Zeichenkette wird als URL interpretiert und in einen Script-Tag
mit src-Attribut übersetzt.

=item \@specs (Arrayreferenz):

Wird zu @specs expandiert.

=back

=head4 Examples

Code zum Laden einer JavaScript-Datei über URL:

  $html = Quiq::JavaScript->script($h,'https://host.dom/scr.js');
  =>
  <script src="https://host.dom/scr.js" type="text/javascript"></script>

Code aus Datei einfügen:

  $html = Quiq::JavaScript->script($h,'inline:js/script.css');
  =>
  <script type="text/javascript">
    ...
  </script>

Code direkt einfügen:

  $html = Quiq::JavaScript->script($h,q|
      ...
  |);
  =>
  <script type="text/javascript">
    ...
  </script>

Mehrere Code-Spezifikationen:

  $html = Quiq::JavaScript->script(
      '...'
      '...'
  );

Mehrere Code-Spezifikationen via Arrayreferenz:

  $html = Quiq::JavaScript->script(
      ['...','...']
  );

Dies ist nützlich, wenn die Spezifikation von einem Parameter
einer umgebenden Methode kommt.

=cut

# -----------------------------------------------------------------------------

sub script {
    my $this = shift;
    my $h = shift;
    # @_: @spec

    my $scriptTags = '';

    while (@_) {
        my $spec = shift;

        if (!defined $spec || $spec eq '') {
            next;
        }

        my $type = Scalar::Util::reftype($spec);
        if ($type && $type eq 'ARRAY') {
            unshift @_,@$spec;
            next;
        }

        if ($spec =~ s/^inline://) {
            my $data = Quiq::Path->read($spec);

            # "// eof" und Leerzeichen am Ende entfernen

            $data =~ s|\s+$||;
            $data =~ s|\s*// eof$||;

            $scriptTags .= $h->tag('script',
                $data
            );
        }
        elsif ($spec =~ /[\s\(]/) {
            # Javascript-Code, wenn Whitespace oder Klammer enthalten
            $scriptTags .= $h->tag('script',
                $spec
            );       
        }
        else {
            # sonst URL
            $scriptTags .= $h->tag('script',
                type => 'text/javascript',
                src => $spec,
            );
        }
    }

    return $scriptTags;
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
