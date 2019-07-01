package Quiq::Html::Widget::ReadOnly;
use base qw/Quiq::Html::Widget/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Widget::ReadOnly - Nicht-änderbarer Text

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

Widget-Wert wird nicht kommuniziert.

=item hidden => $bool (Default: 0)

Widget ist (aktuell) unsichtbar.

=item name => $name (Default: undef)

Name des Hidden-Felds.

=item text => $str (Default: undef)

Text, der angezeigt wird. Ist dieses Attribut nicht gesetzt,
wird der Wert des Attributs value angezeigt.

=item value => $str (Default: undef)

Wert (vom Anwender nicht änderbar).

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
        name => undef,
        style => undef,
        text => undef,
        value => undef,
    );

    # Werte Konstruktoraufruf
    $self->set(@_);

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

    my $self = ref $this? $this: $this->new(@_);

    # Attribute

    my ($class,$disabled,$id,$name,$style,$text,$value) =
        $self->get(qw/class disabled id name style text value/);

    if (!defined $value) {
        $value = '';
    }
    if (!defined $text) {
        $text = $value;
    }

    # Generierung

    return '' if !$name;

    my $str = $h->tag('input',
        -nl => 0,
        type => 'hidden',
        name => $name,
        disabled => $disabled,
        value => $value,
    );
    $str .= $text;

    # Wenn CSS-Attribut(e) angegeben sind, in <span> einfassen

    if ($id || $class || $style) {
        $str = $h->tag('span',
            id => $id,
            class => $class,
            style => $style,
            '-',
            $str
        );
    }

    return "$str\n";
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
