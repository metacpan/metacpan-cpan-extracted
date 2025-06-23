# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Component::Bundle - Bündel von HTML-Komponenten

=head1 BASE CLASS

L<Quiq::List>

=head1 SYNOPSIS

  use Quiq::Html::Component::Bundle;
  
  # Instantiiere Objekt
  $b = Quiq::Html::Component::Bundle->new(\@components);
  
  # Liste aller Komponenten
  @components | $componentA = $b->components;
  
  # Lookup einer Komponente
  $c = $b->component($name);
  
  # Zusammenfassung der Bestandteile der Komponenten
  
  @resources | $resourceA = $b->resources;
  @css | $css = $b->css;
  @html | $html = $b->html;
  @js | $js = $b->js;
  @ready | $ready = $b->ready;
  
  # Platzhalter-Liste für HTML
  @keyVal = $b->htmlPlaceholders;

=head1 DESCRIPTION

Ein Objekt der Klasse speichert mehrere HTML-Komponenten
vom Typ Quiq::Html::Component und stellt Methoden zur Verfügung,
deren Bestandteile abzufragen.

=head1 SEE ALSO

=over 2

=item *

Quiq::Html::Component

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::Component::Bundle;
use base qw/Quiq::List/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $b = $class->new;
  $b = $class->new(\@components);

=head4 Arguments

=over 4

=item @components

Liste der HTML-Komponenten

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$componentA) = @_;
    return $class->SUPER::new($componentA);
}

# -----------------------------------------------------------------------------

=head3 component() - Liefere HTML-Komponente

=head4 Synopsis

  $c = $b->component($name);

=head4 Arguments

=over 4

=item $name

Name der HTML-Komponente

=back

=head4 Returns

HTML-Komponente (Object)

=head4 Description

Liefere die HTML-Komponente mit dem Namen $name.

=cut

# -----------------------------------------------------------------------------

sub component {
    my ($self,$name) = @_;

    for my $c (@{$self->elements}) {
        if ($c->name eq $name) {
            return $c;
        }
    }

    $self->throw(
        'BUNDLE-00001: Component not found',
        Name => $name,
    );
}

# -----------------------------------------------------------------------------

=head3 components() - Liste der HTML-Komponenten

=head4 Synopsis

  @components | $componentA = $b->components;

=head4 Returns

Liste von HTML-Komponenten. Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste der HTML-Komponenten.

=cut

# -----------------------------------------------------------------------------

sub components {
    return shift->elements;
}

# -----------------------------------------------------------------------------

=head3 css() - CSS-Code der Komponenten

=head4 Synopsis

  $css | @css = $c->css;

=head4 Description

Liefere den CSS-Code der Komponenten. Im Arraykontext die Liste der
Array-Elemente, im Skalarkontext deren Konkatenation.

=cut

# -----------------------------------------------------------------------------

sub css {
    return shift->getValue('css');
}

# -----------------------------------------------------------------------------

=head3 html() - HTML-Code der Komponenten

=head4 Synopsis

  $html | @html = $c->html;

=head4 Description

Liefere den HTML-Code der Komponenten. Im Arraykontext die Liste der
Array-Elemente, im Skalarkontext deren Konkatenation.

=cut

# -----------------------------------------------------------------------------

sub html {
    return shift->getValue('html');
}

# -----------------------------------------------------------------------------

=head3 htmlPlaceholders() - Platzhalterliste für HTML

=head4 Synopsis

  @keyVal = $c->htmlPlaceholders;

=head4 Returns

Liste von Schlüssel/Wert-Paaren

=head4 Description

Liefere die Liste von Schlüssel/Wert-Paaren für eine
HTML-Platzhalterersetzung.

=cut

# -----------------------------------------------------------------------------

sub htmlPlaceholders {
    my $self = shift;

    my @arr;
    for my $c (@{$self->elements}) {
        push @arr,'__'.uc($c->name).'__'=>scalar $c->html;
    }

    return @arr;
}

# -----------------------------------------------------------------------------

=head3 js() - JavaScript-Code der Komponenten

=head4 Synopsis

  $js | @js = $c->js;

=head4 Description

Liefere den JavaScript-Code der Komponenten. Im Arraykontext die Liste der
Array-Elemente, im Skalarkontext deren Konkatenation.

=cut

# -----------------------------------------------------------------------------

sub js {
    return shift->getValue('js');
}

# -----------------------------------------------------------------------------

=head3 ready() - Ready-Handler der Komponenten

=head4 Synopsis

  $ready | @ready = $c->ready;

=head4 Description

Liefere den/die Ready-Handler der Komponenten. Im Arraykontext die
Liste der Array-Elemente, im Skalarkontext deren Konkatenation.

=cut

# -----------------------------------------------------------------------------

sub ready {
    return shift->getValue('ready');
}

# -----------------------------------------------------------------------------

=head3 resources() - Resourcen aller Komponenten

=head4 Synopsis

  @resources | $resourceA = $c->resources;

=head4 Returns

Liste von Resource-URLs. Im Skalarkontext eine Referenz auf die Liste.

=head4 Description

Liefere die Liste der Resource-URLs aller Komponenten. Mehrfachnennungen
werden gefiltert.

=cut

# -----------------------------------------------------------------------------

sub resources {
    my $self = shift;

    my @arr;
    for my $c (@{$self->elements}) {
        push @arr,$c->resources;
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head2 Private Methoden

=head3 getValue() - Liefere Attributwert

=head4 Synopsis

  $str | @arr = $obj->getValue($key);

=head4 Description

Liefere den Wert des Attributs $key. Im Arraykontext die Liste der
Array-Elemente, im Skalarkontext deren Konkatenation.

=cut

# -----------------------------------------------------------------------------

sub getValue {
    my ($self,$key) = @_;

    my @arr;
    for my $c (@{$self->components}) {
         push @arr,$c->$key;
    }

    return wantarray? @arr: join '',@arr;
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
