# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Page - HTML-Seite

=head1 BASE CLASS

L<Quiq::Html::Base>

=head1 SYNOPSIS

  use Quiq::Html::Page;
  
  $h = Quiq::Html::Producer->new;
  
  $obj = Quiq::Html::Page->new(
      body => 'hello world!',
  );
  
  $html = $obj->html($h);

=head1 ATTRIBUTES

=over 4

=item body => $str (Default: '')

Rumpf der Seite.

=item bodyOnly => $bool (Default: 0)

Liefere als Returnwert von asHtml() nur den Body anstelle der
Gesamtseite.

=item comment => $str (Default: undef)

Kommentar am Anfang der Seite.

=item components => \@components

Liste der HTML-Komponenten, die in die Seite eingesetzt werden.
Die Komponentenbestandteile werden automatisch zu den Seitenbestandteilen
hinzugefüht. Im Seiten-HTML-Code wird der HTML-Code der Komponente
an der Postion des Platzhalters __<NAME>__ eingesetzt.

=item encoding => $charset (Default: 'utf-8')

Encoding der Seite, z.B. 'iso-8859-1'.

=item head => $str (Default: '')

Kopf der Seite.

=item load => \@arr

Liste von Ladeanweisungen für CSS- und JavaScript-Dateien. Die
Ladeanweisungen werden vor anderem CSS- und JavaScript-Code
(s. Attribute javaScript und styleSheet) in den Head der Seite
geschrieben. Eine CSS-Datei wird durch die Angabe eines Paars
css => $url, eine JavaScript-Datei durch die Angabe eines Paars
js => $url geladen. Hat $url die Endung .css oder .js, kann die
Typangabe auch weggelassen werden. Beispiel:

  load => [
      css => 'https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css',
      js => 'https://code.jquery.com/ui/1.12.1/jquery-ui.min.js',
  ],

Oder kurz (da die Dateiendungen den Typ verraten):

  load => [
      'https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css',
      'https://code.jquery.com/ui/1.12.1/jquery-ui.min.js',
  ],

=item noNewline => $bool (Default: 0)

Füge kein Newline am Ende der Seite hinzu.

=item placeholders => \@keyVal (Default: [])

Ersetze im generierten HTML-Code die angegebenen Platzhalter durch
ihre Werte.

=item javaScript => $url|$jsCode|[...] (Default: undef)

URL oder JavaScript-Code am Ende der Seite. Mehrfach-Definition,
wenn Array-Referenz. Das Attribut kann mehrfach auftreten, die
Werte werden zu einer Liste zusammengefügt.

=item javaScriptToHead => $bool (Default: 0)

Setze den JavaScrip-Code nicht an das Ende des Body, sondern in
den Head der HTML-Seite.

=item ready => $jsCode (Default: [])

Führe JavaScript-Code $jsCode aus, wenn das DOM geladen ist.
Dies ist so implementiert, dass der Code in einen jQuery
ready-Handler eingebettet wird:

  $(function() {
      $jsCode
  });

Das Konstrukt setzt also jQuery voraus. Das Attribut kann mehrfach
auftreten, es werden dann mehrere ready-Handler aufgesetzt.

=item styleSheet => $spec | \@specs (Default: undef)

Einzelne Style-Spezifikation oder Liste von Style-Spezifikationen.
Siehe Methode Quiq::Css->style(). Das Attribut kann mehrfach
auftreten, die Werte werden zu einer Liste zusammengefügt.

=item title => $str (Default: undef)

Titel der Seite.

=item topIndentation => $n (Default: 2)

Einrückung des Inhalts der obersten Elemente <head> und <body>.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::Page;
use base qw/Quiq::Html::Base/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Html::Component::Bundle;
use Quiq::Css;
use Quiq::JQuery::Function;
use Quiq::JavaScript;
use Quiq::Template;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $obj = $class->new(@keyVal);

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        body => '',
        bodyOnly => 0,
        comment => undef,
        components => [],
        encoding => 'utf-8',
        head => '',
        load => [],
        noNewline => 0,
        placeholders => [],
        javaScript => [],
        javaScriptToHead => 0,
        ready => [],
        styleSheet => [],
        title => '',
        topIndentation => 2,
    );

    while (@_) {
        my $key = shift;
        my $val = shift;

        if ($key eq 'javaScript' || $key eq 'load' || $key eq 'ready' ||
                $key eq 'styleSheet') {
            my $arr = $self->get($key);
            push @$arr,ref $val? @$val: $val;
        }
        else {
            $self->set($key=>$val);
        }
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

  $html = $obj->html($h);
  $html = $class->html($h,@keyVal);

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($body,$bodyOnly,$comment,$componentA,,$encoding,$head,$loadA,
        $noNewline,$placeholderA,$title,$jsA,$javaScriptToHead,$readyA,
        $cssA,$topIndentation) =
        $self->get(qw/body bodyOnly comment components encoding head load
        noNewline placeholders title javaScript javaScriptToHead ready
        styleSheet topIndentation/);

    my $b = Quiq::Html::Component::Bundle->new($componentA);

    # Resourcen (CSS- und JavaScript-Dateien) laden
    my $loadTags = $h->loadFiles(@$loadA,$b->resources);

    # Stylesheet-Defininition(en)
    my $styleTags = Quiq::Css->style($h,@$cssA,$b->css);

    # ready-Handler

    for ($b->ready,@$readyA) {
        push @$jsA,Quiq::JQuery::Function->ready($_);
    }

    # Script-Definition(en)

    my $scriptTags;
    for my $js ($b->js,@$jsA) {
        $scriptTags .= Quiq::JavaScript->script($h,$js);
    }

    # Wenn $body keinen body-Tag enthält, fügen wir ihn hinzu.

    if ($body !~ /^<body/i) {
        $body = $h->tag('body',
            -ind => $topIndentation,
            '-',
            $body,
            $javaScriptToHead? (): $scriptTags,
        );
    }

    my $html = $bodyOnly? $body: $h->cat(
        $h->doctype,
        $h->comment(-nl=>2,$comment),
        $h->tag('html',
            '-',
            $h->tag('head',
                -ind => $topIndentation,
                '-',
                $h->tag('title',
                    -ignoreIf => !$title,
                    '-',
                    $title,
                ),
                $h->tag('meta',
                    'http-equiv' => 'content-type',
                    content => "text/html; charset=$encoding",
                ),
                $h->cat($head),
                $loadTags,
                $styleTags,
                $javaScriptToHead? $scriptTags: (),
            ),
            $body,
        ),
    );

    # Platzhalter ersetzen

    my @placeholders = (@$placeholderA,$b->htmlPlaceholders);
    if (@placeholders) {
        my $tpl = Quiq::Template->new('text',\$html);
        $html = $tpl->replace(@placeholders)->asString;
    }

    if ($noNewline) {
        chomp $html;
    }

    return $html;
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
