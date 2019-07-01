package Quiq::Html::Widget::SelectMenu;
use base qw/Quiq::Html::Widget/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Widget::SelectMenu - Liste mit Einzelauswahl

=head1 BASE CLASS

L<Quiq::Html::Widget>

=head1 ATTRIBUTES

=over 4

=item id => $id (Default: undef)

CSS Id.

=item class => $class (Default: undef)

CSS Klasse.

=item style => $style (Default: undef)

CSS Definition (inline).

=item disabled => $bool (Default: 0)

Widget kann nicht editiert werden.

=item hidden => $bool (Default: 0)

Widget ist (aktuell) unsichtbar.

=item javaScript => $js (Default: undef)

JavaScript-Code, der an den Widget-Code angehängt wird.

=item name => $name (Default: undef)

Name des Widget.

=item value => $str (Default: undef)

Anfänglich ausgewählter Wert.

=item onChange => $js (Default: undef)

JavaScript-Code bei Änderung der Auswahl ausgeführt wird.

=item options => \@opt (Default: [])

Liste der möglichen Werte.

=item texts => \@text (Default: [])

Liste der angezeigten Werte. Wenn nicht angegeben, wird die Liste der
möglichen Werte (Attribut "options") angezeigt.

=item styles => \@styles (Default: [])

Liste der CSS-Definitionen für die einzelnen Optionen. Kann z.B. für
verschiedene Hintergrundfarben genutzt werden.

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $e = $class->new(@keyVal);

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    # Defaultwerte

    my $self = $class->SUPER::new(
        class => undef,
        disabled => 0,
        hidden => 0,
        id => undef,
        javaScript => undef,
        name => undef,
        onChange => undef,
        options => [],
        style => undef,
        styles => [],
        texts => [],
        value => undef,
    );

    # Werte Konstruktoraufruf
    $self->set(@_);

    # Existenz des Werts prüfen. Wenn nicht existent,
    # setzen wir den ersten Wert.

    my $value = $self->{'value'};
    my $optionA = $self->{'options'};

    if (!defined($value) || !grep {$_ eq $value} @$optionA) {
        $self->{'value'} = $optionA->[0];
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML-Code

=head4 Synopsis

    $html = $e->html($h);
    $html = $class->html($h,@keyVal);

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;
    # @_: @keyVal

    my $self = ref $this? $this: $this->new(@_);

    # Attribute

    my ($class,$disabled,$id,$javaScript,$name,$onChange,$options,$style,
        $styles,$texts,$value) =
        $self->get(qw/class disabled id javaScript name onChange options style
        styles texts value/);

    # Generierung

    my $str;
    for (my $i = 0; $i < @$options; $i++) {
        my $option = $options->[$i];
        my $text = $texts->[$i];
        if (!defined $text) {
            $text = $option;
        }
        my $style = $styles->[$i];

        $str .= $h->tag('option',
            -nl => 0,
            value => $option,
            style => $style,
            selected => defined($value) && $option eq $value,
            $text
        );
    }

    my $html = $h->tag('select',
        name => $name,
        id => $id,
        class => $class,
        style => $style,
        disabled => $disabled,
        onchange => $onChange,
        '-',
        $str
    );
    chomp $html;

    if ($javaScript) {
        $html .= "\n".$h->tag('script',$javaScript);
    }

    return $html;
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
