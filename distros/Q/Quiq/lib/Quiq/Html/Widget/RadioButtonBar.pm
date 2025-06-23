# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Widget::RadioButtonBar - Zeile von Radio Buttons

=head1 BASE CLASS

L<Quiq::Html::Widget>

=head1 ATTRIBUTES

=over 4

=item class => $class (Default: undef)

CSS Klasse des Konstruktes.

=item default => $default (Default: keiner)

Wert, der angenommen wird, wenn value ein Leerstring oder C<undef> ist.

=item disabled => $bool (Default: 0)

Das gesamte Konstrukt ist disabled. Keine Auswahl möglich.

=item hidden => $bool (Default: 0)

Das gesamte Konstrukt ist nicht sichtbar.

=item id => $id (Default: undef)

CSS-Id des Konstruktes.

=item labels => \@labels (Default: [])

Liste der Label rechts neben den Radio-Buttons.

=item name => $name (Default: undef)

Name, unter dem der ausgewählte Button kommuniziert wird.

=item onClick => \@onClick (Default: [])

Liste der OnClick-Handler.

=item options => \@options (Default: []) 

Liste der Radio-Button-Werte. Der Wert des ausgewählten Radio Button
wird gesendet.

=item orientation => 'h'|'v' (Default: 'h')

Horizentale oder vertikale Ausrichtung der Radio-Buttons.

=item buttonClass => $class (Default: undef)

CSS Klasse der Radio Buttons.

=item style => $style (Default: undef)

CSS Definition des Konstruktes (inline).

=item titles => \@titles (Default: [])

Tooltip-Texte der Radio Buttons.

=item undefIf => $bool (Default: 0)

Wenn wahr, liefere C<undef> als Widget-Code.

=item value => $value (Default: undef)

Aktueller Wert. Stimmt dieser mit dem Wert (s. Attribut option)
eines der Radio Buttons überein, wird dieser Radio-Button
aktiviert.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::Widget::RadioButtonBar;
use base qw/Quiq::Html::Widget/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Html::Widget::RadioButton;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

  $e = $class->new(@keyVal);

=head4 Description

Instantiiere ein RadioButtonBar-Objekt und liefere eine Referenz
auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    # Defaultwerte

    my $self = $class->SUPER::new(
        class => undef,
        default => undef,
        disabled => 0,
        hidden => 0,
        id => undef,
        labels => [],
        name => undef,
        onClick => [],
        options => [],
        orientation => 'h',
        buttonClass => undef,
        style => undef,
        titles => [],
        undefIf => 0,
        value => undef,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 html() - Generiere HTML

=head4 Synopsis

  $html = $e->html($h);
  $html = $class->html($h,@keyVal);

=head4 Description

Generiere den HTML-Code des RadioButtonBar-Objekts und liefere
diesen zurück. Als Klassenmethode gerufen, wird das Objekt intern
erzeugt und mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    # Attribute

    my ($class,$default,$disabled,$hidden,$id,$labelA,$name,$onClickA,
        $optionA,$orientation,$buttonClass,$style,$titleA,$undefIf,$value) =
        $self->get(qw/class default disabled hidden id labels name onClick
        options orientation buttonClass style titles undefIf value/);

    # Generierung

    if ($undefIf) {
        return undef;
    }

    if ($hidden || !@$optionA) {
        return '';
    }

    if (!defined($value) || $value eq '' && !grep {$_ eq ''} @$optionA) {
        $value = $default;
    }

    return $h->tag('span',
        -fmt => 'v', # generierten Code einzeilig belassen
        -ignoreTagIf => !$id && !$class && !$style,
        id => $id,
        class => $class,
        style => $style,
        do {
            my $html;
            for (my $i = 0; $i < @$optionA; $i++) {
                if ($html) {
                    $html .= $orientation eq 'v'? $h->tag('br',-nl=>0): ' ';
                }
                $html .= Quiq::Html::Widget::RadioButton->html($h,
                    class => $buttonClass,
                    disabled => $disabled,
                    label => $labelA->[$i] // $optionA->[$i],
                    name => $name,
                    onClick => $onClickA->[$i],
                    option => $optionA->[$i],
                    title => $titleA->[$i],
                    value => $value,
                );
                chomp $html;
            }
            $html;
        }
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
