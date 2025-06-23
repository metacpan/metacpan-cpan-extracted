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

=item addNull => $bool (Default: 0)

Wenn gesetzt, füge Auswahl für Nullwert ('') am Anfang der Liste hinzu.
Es erscheint der Text '---'.

=item disabled => $bool (Default: 0)

Widget kann nicht editiert werden.

=item hidden => $bool (Default: 0)

Widget ist (aktuell) unsichtbar.

=item javaScript => $js (Default: undef)

JavaScript-Code, der an den Widget-Code angehängt wird.

=item name => $name (Default: undef)

Name des Widget.

=item undefIf => $bool (Default: 0)

Wenn wahr, liefere C<undef> als Widget-Code.

=item value => $str (Default: undef)

Anfänglich ausgewählter Wert.

=item onChange => $js (Default: undef)

JavaScript-Code bei Änderung der Auswahl ausgeführt wird.

=item options => \@opt (Default: [])

Liste der möglichen Werte.

=item optionPairs => \@pairs (Default: [])

Liste der möglichen Werte und ihrer Anzeigetexte. Beispiel:

  optionPairs => [
      0 => 'Nein',
      1 => 'Ja',
      2 => 'Vielleicht',
  ]

=item readonly => $bool (Default: 0)

Zeige das Feld und seinen Wert unveränderbar an.

=item texts => \@text (Default: [])

Liste der angezeigten Werte. Wenn nicht angegeben, wird die Liste der
möglichen Werte (Attribut "options") angezeigt.

=item title => $str (default: undef)

Beschreibungstext.

=item styles => \@styles (Default: [])

Liste der CSS-Definitionen für die einzelnen Optionen. Kann z.B. für
verschiedene Hintergrundfarben genutzt werden.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::Widget::SelectMenu;
use base qw/Quiq::Html::Widget/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Html::Widget::Hidden;
use Quiq::Html::Widget::TextField;
use Quiq::JavaScript;

# -----------------------------------------------------------------------------

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
        addNull => 0,
        class => undef,
        disabled => 0,
        hidden => 0,
        id => undef,
        javaScript => undef,
        name => undef,
        onChange => undef,
        options => [],
        optionPairs => [],
        readonly => 0,
        style => undef,
        styles => [],
        texts => [],
        title => undef,
        undefIf => 0,
        value => undef,
    );

    # Werte Konstruktoraufruf
    $self->set(@_);

    my $optionPairs = $self->{'optionPairs'};
    if (@$optionPairs) {
        my (@options,@texts);
        for (my $i = 0; $i < @$optionPairs; $i += 2) {
            push @options,$optionPairs->[$i];
            push @texts,$optionPairs->[$i+1];
        }
        $self->{'options'} = \@options;
        $self->{'texts'} = \@texts;
    }
    elsif (@{$self->{'options'}} && !@{$self->{'texts'}}) {
        # Sind keine Texte gesetzt, setzen wir sie identisch zu den Optionen
        $self->{'texts'} = [@{$self->{'options'}}];
    }

    if ($self->{'addNull'}) {
        # Wir fügen eine Nullauswahl hinzu
        $self->{'options'} = ['',@{$self->{'options'}}];
        $self->{'texts'} = ['---',@{$self->{'texts'}}];
    }

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

    my ($addNull,$class,$disabled,$id,$javaScript,$name,$onChange,
        $options,$readonly,$style,$styles,$texts,$title,$undefIf,$value) =
        $self->get(qw/addNull class disabled id javaScript name onChange
        options readonly style styles texts title undefIf value/);

    # Generierung

    if ($undefIf) {
        return undef;
    }

    my $html;
    if ($readonly) {
        # Anzuzeigenden Wert ermitteln

        my ($option,$text) = ($options->[0],$texts->[0]);
        if (defined $value) {
            for (my $i = 0; $i < @$options; $i++) {
                if ($options->[$i] eq $value) {
                    $option = $options->[$i];
                    $text = $texts->[$i];
                    last;
                }
            }
        }

        if (!$disabled) {
            $html .= Quiq::Html::Widget::Hidden->html($h,
                name => $name,
                value => $option,
            );
        }
        $html .= Quiq::Html::Widget::TextField->html($h,
            # name => $name,
            # id => $id,
            class => $class,
            style => $style,
            disabled => $disabled,
            readonly => 1,
            size => length($text),
            title => $title,
            value => $text,
        );
    }
    else {
        my $str;
        for (my $i = 0; $i < @$options; $i++) {
            my $option = $options->[$i];
            my $text = $texts->[$i];
            my $style = $styles->[$i];

            $str .= $h->tag('option',
                -nl => 0,
                value => $option,
                style => $style,
                selected => defined($value) && $option eq $value,
                $text
            );
        }

        $html = $h->tag('select',
            name => $name,
            id => $id,
            class => $class,
            style => $style,
            disabled => $disabled,
            onchange => Quiq::JavaScript->line($onChange),
            title => $title,
            '-',
            $str
        );
    }
    chomp $html;

    if ($javaScript) {
        $html .= "\n".$h->tag('script',$javaScript);
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
