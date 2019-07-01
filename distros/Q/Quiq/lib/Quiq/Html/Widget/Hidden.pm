package Quiq::Html::Widget::Hidden;
use base qw/Quiq::Html::Widget/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Widget::Hidden - Nicht sichtbares und nicht änderbares Formularelement

=head1 BASE CLASS

L<Quiq::Html::Widget>

=head1 DESCRIPTION

Ein Hidden-Widget kommuniziert unter einem Namen einen oder
mehrere Werte. Das Widget ist für den Anwender unsichtbar und
sein Zustand kann von diesem nicht manipuliert werden.

=head1 ATTRIBUTES

=over 4

=item id => $id (Default: undef)

Id.

=item name => $name (Default: undef)

Name.

=item value => $str | \@arr (Default: undef)

Wert bzw. Liste von Werten.

=item hidden => 1

Widget ist unsichtbar. Diese Eigenschaft gilt für Hidden-Widgets
immer und ist nicht änderbar.

=item ignoreIfNull => $bool (Default: 0)

Generiere Leerstring, wenn Wert Null (undef oder Leerstring) ist.

=item disabled => $bool (Default: 0)

Das Element wird nicht submittet.

=back

=head1 EXAMPLES

Html::Tag-Objekt instantiieren:

    $obj = Quiq::Html::Tag->new;

Keine Information:

    $html = Quiq::Html::Widget::Hidden->html($h);
    -->
    Leerstring

Wert:

    $html = Quiq::Html::Widget::Hidden->html($h,
        name => 'x',
        value => 4711,
    );
    -->
    <input type="hidden" name="x" value="4711" />\n

Liste von Werten:

    $html = Quiq::Html::Widget::Hidden->html($h,
        name => 'x',
        value => [4711,4712],
    );
    -->
    <input type="hidden" name="x" value="4711" />\n
    <input type="hidden" name="x" value="4712" />\n

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
        id => undef,
        disabled => 0,
        hidden => 1,
        ignoreIfNull => 0,
        name => undef,
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

    # *** Attribute ***

    my ($id,$disabled,$ignoreIfNull,$name,$value) =
        $self->get('id','disabled','ignoreIfNull','name','value');

    # Wert auf Array abbilden. Wenn ignoreIfNull erfüllt, Leerstring liefern.

    my $arr;
    if (ref $value) {
        $arr = $value;
        if ($ignoreIfNull && @$arr == 0) {
            return '';
        }
    }
    else {
        if (!defined($value) || $value eq '') {
            if ($ignoreIfNull) {
                return '';
            }
            $value = '';
        }
        $arr = [$value];
    }

    # *** Generierung ***

    return '' if !$name;

    my $str = '';
    for my $val (@$arr) {
        $str .= $h->tag('input',
            type => 'hidden',
            id => $id,
            disabled => $disabled,
            name => $name,
            value => $val,
        );
    }

    return $str;
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
