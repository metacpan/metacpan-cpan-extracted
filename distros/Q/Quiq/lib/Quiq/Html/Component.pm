# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Component - Eigenständige Komponente einer HTML-Seite

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

  use Quiq::Html::Component;
  
  # Instantiiere Objekt
  
  $c = Quiq::Html::Component->new(
      name => $name
      resources => \@resources,
      css => $css | \@css,
      html => $html | \@html,
      js => $js | \@js,
      ready => $js | \@js,
  );
  
  # Frage Eigenschaften ab
  
  $name = $c->name;
  @resources = $c->resources;
  $css | @css = $c->css;
  $html | @html = $c->html;
  $js | @js = $c->js;
  $ready | @ready = $c->ready;
  
  # Generiere HTML-Fragment
  
  $h = Quiq::Html::Tag->new;
  $html = $c->fragment($h);

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine eigenständige Komponente
einer HTML-Seite bestehend aus HTML-, CSS- und JavaScript-Code
(normaler Code und jQuery ready-Handler). Der Zweck besteht darin,
diese Bestandteile zu einer logischen Einheit zusammenzufassen. Die
Bestandteile können über Methoden der Klasse abgefragt werden, um
sie systematisch in die unterschiedlichen Abschnitte einer
HTML-Seite (<head>, <body>, <style>, <script>, $(function()
{...})) einsetzen zu können. Die Resourcen mehrerer Komponenten
(Attribut resources) können zu einer Liste ohne Dubletten konsolidiert
werden. Dies ist allerdings Aufgabe des Nutzers bzw. der Klasse
Quiq::Html::Component::Bundle. Ein Objekt der Klasse
speichert die einzelnen Bestandteile lediglich, die Methoden
manipulieren diese nicht. Einzig die Methode L<fragment|"fragment() - Generiere HTML">() führt
eine Verarbeitung durch, indem sie zusammenfassenden HTML-Code über
allen Komponenten generiert.

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::Component;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Css;
use Quiq::JavaScript;
use Quiq::JQuery::Function;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $c = $class->new(@keyVal);

=head4 Attributes

Alle Attribute außer C<name> können mehrfach angegeben werden.

=over 4

=item name => $name

Name der Komponente. Unter diesem Namen kann die Komponente aus einem
Bündel von Komponenten ausgewählt werden. Siehe Quiq::Html::Bundle.

=item resources => \@resources

Liste von Resourcen (CSS- und JavaScript-Dateien), die von der
Komponente benötigt werden. Eine Resource wird durch ihren
URL spezifiziert. Es sollte eine einheitliche Schreibweise über
mehreren Komponenten verwendet werden, damit die Resource-Listen
konsolidiert werden können.

=item css => $css | \@css

Der CSS-Code der Komponente. Besteht der CSS-Code aus mehreren Teilen,
kann das Attribut mehrfach oder eine Array-Referenz angegeben
werden.

=item html => $html | \@html (Default: '')

Der HTML-Code der Komponente. Besteht der HTML-Code aus
mehreren Teilen, kann das Attribut mehrfach oder eine Array-Referenz
angegeben werden.

=item js => $js | \@js

Der JavaScript-Code der Komponente. Besteht der JavaScript-Code aus
mehreren Teilen, kann das Attribut mehrfach oder eine Array-Referenz
angegeben werden.

=item ready => $js | \@js

Der Ready-Handler der Komponente. Gibt es mehrere Ready-Handler
kann das Attribut mehrfach oder eine Array-Referenz angegeben werden.

=back

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        cssA => [],
        htmlA => [],
        jsA => [],
        name => undef,
        readyA => [],
        resourceA => [],
    );

    while (@_) {
        $self->putValue(splice @_,0,2);
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 css() - CSS-Code der Komponente

=head4 Synopsis

  $css | @css = $c->css;

=head4 Description

Liefere den CSS-Code der Komponente. Im Arraykontext die Liste der
Array-Elemente, im Skalarkontext deren Konkatenation.

=cut

# -----------------------------------------------------------------------------

sub css {
    return shift->getValue('cssA');
}

# -----------------------------------------------------------------------------

=head3 fragment() - Generiere HTML

=head4 Synopsis

  $html = $c->fragment($h);
  $html = $class->fragment($h,@keyVal);

=head4 Description

Generiere den Frament-Code der Komponente und liefere diesen zurück.
Als Klassenmethode gerufen, wird das Objekt intern erzeugt und mit den
Attributen @keyVal instantiiert.

Der Fragment-Code besteht aus dem HTML-, CSS- und JavaScript-Code der
Komponente. Anwendungsfall ist z.B. eine Ajax-Antwort, die in ein
bestehendes HTML-Dokument eingebettet wird.

Der generierte Code hat den Aufbau:

  <RESOURCEN LADEN>
  <STYLE CODE>
  <HTML CODE>
  <JAVASCRIPT CODE>

=cut

# -----------------------------------------------------------------------------

sub fragment {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($cssA,$htmlA,$jsA,$readyA,$resourceA) =
        $self->get(qw/cssA htmlA jsA readyA resourceA/);

    return $h->cat(
        $h->loadFiles(@$resourceA),
        Quiq::Css->style($h,$cssA),
        join('',@$htmlA),
        Quiq::JavaScript->script($h,$jsA),
        $h->tag('script',
            -ignoreIfNull => 1,
            Quiq::JQuery::Function->ready(join('',@$readyA))
        ),
    );
}

# -----------------------------------------------------------------------------

=head3 html() - HTML-Code der Komponente

=head4 Synopsis

  $html | @html = $c->html;

=head4 Description

Liefere den HTML-Code der Komponente. Im Arraykontext die Liste der
Array-Elemente, im Skalarkontext deren Konkatenation.

=cut

# -----------------------------------------------------------------------------

sub html {
    return shift->getValue('htmlA');
}

# -----------------------------------------------------------------------------

=head3 js() - JavaScript-Code der Komponente

=head4 Synopsis

  $js | @js = $c->js;

=head4 Description

Liefere den JavaScript-Code der Komponente. Im Arraykontext die Liste der
Array-Elemente, im Skalarkontext deren Konkatenation.

=cut

# -----------------------------------------------------------------------------

sub js {
    return shift->getValue('jsA');
}

# -----------------------------------------------------------------------------

=head3 name() - Name der Komponente

=head4 Synopsis

  $name = $c->name;

=head4 Description

Liefere den Namen der Komponente.

=cut

# -----------------------------------------------------------------------------

sub name {
    return shift->{'name'};
}

# -----------------------------------------------------------------------------

=head3 ready() - Ready-Handler der Komponente

=head4 Synopsis

  $ready | @ready = $c->ready;

=head4 Description

Liefere den/die Ready-Handler der Komponente. Im Arraykontext die
Liste der Array-Elemente, im Skalarkontext deren Konkatenation.

=cut

# -----------------------------------------------------------------------------

sub ready {
    return shift->getValue('readyA');
}

# -----------------------------------------------------------------------------

=head3 resources() - Resourcen der Komponente

=head4 Synopsis

  @resources | $resourceA = $c->resources;

=head4 Returns

Liste der Resource-URLs. Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste der Resource-URLs der Komponente.

=cut

# -----------------------------------------------------------------------------

sub resources {
    my $self = shift;
    my $arr = $self->{'resourceA'};
    return wantarray? @$arr: $arr;
}

# -----------------------------------------------------------------------------

=head2 Private Methoden

=head3 getValue() - Liefere Attributwert

=head4 Synopsis

  @arr | $str = $obj->getValue($key);

=head4 Description

Liefere den Wert des Attributs $key. Im Arraykontext die Liste der
Array-Elemente, im Skalarkontext deren Konkatenation.

=cut

# -----------------------------------------------------------------------------

sub getValue {
    my ($self,$key) = @_;
    my $arr = $self->{$key};
    return wantarray? @$arr: join('',@$arr);
}

# -----------------------------------------------------------------------------

=head3 putValue() - Setze Attributwert oder füge ihn hinzu

=head4 Synopsis

  $obj->putValue($key=>$val);

=head4 Description

Setze den Wert $val des Attributs $key oder füge ihn hinzu.

=cut

# -----------------------------------------------------------------------------

sub putValue {
    my ($self,$key,$val) = @_;

    # Übersetze externen Namen in internen Namen

    $key = {
        css => 'cssA',
        html => 'htmlA',
        js => 'jsA',
        name => 'name',
        ready => 'readyA',
        resources => 'resourceA',
    }->{$key};

    # Setze Wert (Skalarattribut) oder füge ihn hinzu (Arrayattribut)
    $self->setOrPush($key=>$val);

    return;
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
