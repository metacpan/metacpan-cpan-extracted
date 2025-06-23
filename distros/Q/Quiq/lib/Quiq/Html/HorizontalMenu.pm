# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::HorizontalMenu - Einfaches horizontales Menü

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert ein horizontales Menü
zur Auswahl von Links.

=head1 ATTRIBUTES

=over 4

=item active => $name

Der Name oder das Label des ausgewählten Menüelements.

=item class => $class

CSS-Klasse.

=item id => $id

CSS-Id des Menüs.

=item items => \@items

Die Elemente des Menüs. Struktur eines Menüelements:

  {
      name => $name,
      class => undef,
      label => $label,
      url => $url,
  }

=item style => $style

CSS-Style.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::HorizontalMenu;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Hash;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Menü-Objekt

=head4 Synopsis

  $e = $class->new(@keyVal);

=head4 Arguments

=over 4

=item @keyVal

Liste von Attribut/Wert-Paaren. Die Werte werden auf dem Objekt
gesetzt. Siehe Abschnitt ATTRIBUTES.

=back

=head4 Returns

=over 4

=item $e

Menü-Objekt

=back

=head4 Description

Instantiiere ein Menü-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        active => undef,
        class => undef,
        id => undef,
        items => [],
        style => undef,
    );
    $self->set(@_);

    my @items;
    for (@{$self->items}) {
        push @items,Quiq::Hash->new($_,
            name => undef,
            class => undef,
            label => undef,
            url => undef,
        );
    }
    $self->items(\@items);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML-Code

=head4 Synopsis

  $html = $e->html($h);
  $html = $class->html($h,@keyVal);

=head4 Arguments

=over 4

=item $h

Objekt für die HTML-Generierung, d.h. eine Instanz der Klasse
Quiq::Html::Tag.

=item @keyVal

Siehe Konstruktor.

=back

=head4 Returns

HTML-Code (String)

=head4 Description

Generiere den HTML-Code des Menüs und liefere diesen
zurück. Als Klassenmethode gerufen, wird das Objekt intern
mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;
    # @_: @keyVal

    my $self = ref $this? $this: $this->new(@_);

    my ($active,$cssClass,$id,$itemA,$style) =
        $self->get(qw/active class id items style/);
    $active //= '';

    my $html = '';
    for my $itm (@$itemA) {
        if ($html) {
            $html .= ' | ';
        }

        $html .= $h->tag('a',
            -ignoreTagIf => ($itm->name // $itm->label) eq $active,
            class => $itm->class,
            href => $itm->url,
            $itm->label
        );
    }
    if ($html) {
        $html = $h->tag('div',
            class => $cssClass,
            id => $id,
            style => $style,
            "[ $html ]"
        );
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
