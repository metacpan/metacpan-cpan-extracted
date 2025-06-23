# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Widget::TextField - Einzeiliges Textfeld

=head1 BASE CLASS

L<Quiq::Html::Widget>

=head1 ATTRIBUTES

=over 4

=item id => $id (Default: undef)

Id des Textfelds.

=item class => $class (Default: undef)

CSS Klasse des Textfelds.

=item style => $style (Default: undef)

CSS Definition (inline).

=item disabled => $bool (Default: 0)

Widget kann nicht editiert werden.

=item hidden => $bool (Default: 0)

Widget ist (aktuell) unsichtbar.

=item maxLength => $n (Default: Wert von "size")

Maximale Länge des Eingabewerts in Zeichen. Ein Wert von "0" beutet
keine Eingabebegrenzung.

=item name => $name (Default: undef)

Name des Textfelds.

=item onKeyUp => $js (Default: undef)

JavaScript-Handler.

=item password => $bool (Default: 0)

Wenn gesetzt, wird der Eingawert verschleiert.

=item readonly => $bool (Default: 0)

Zeige das Feld und seinen Wert unveränderbar an.

=item size => $n (Default: undef)

Breite des Feldes in Zeichen.

=item title => $text (Default: undef)

Text Tooltip.

=item undefIf => $bool (Default: 0)

Wenn wahr, liefere C<undef> als Widget-Code.

=item value => $str (Default: undef)

Anfänglicher Wert des Textfelds.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::Widget::TextField;
use base qw/Quiq::Html::Widget/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

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
        class => undef,
        disabled => 0,
        hidden => 0,
        id => undef,
        maxLength => undef,
        name => undef,
        onKeyUp => undef,
        password => 0,
        readonly => 0,
        size => undef,
        style => undef,
        title => undef,
        undefIf => 0,
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
    # @_: @keyVal

    my $self = ref $this? $this: $this->new(@_);

    # Attribute

    my ($class,$disabled,$id,$maxLength,$name,$onKeyUp,$password,
        $readonly,$size,$style, $title,$undefIf,$value) =
        $self->get(qw/class disabled id maxLength name onKeyUp password
        readonly size style title undefIf value/);

    if (!defined $maxLength) {
        $maxLength = $size;
    }
    elsif ($maxLength == 0) {
        $maxLength = undef;
    }

    # Whitespace entfernen

    if (defined $value) {
        $value =~ s/^\s+//;
        $value =~ s/\s+$//;
    }

    # Generierung

    if ($undefIf) {
        return undef;
    }

    return $h->tag('input',
        type => $password? 'password': 'text',
        id => $id,
        class => $class,
        style => $style,
        name => $name,
        readonly => $readonly,
        disabled => $disabled,
        onkeyup => $onKeyUp,
        size => $size,
        maxlength => $maxLength,
        value => $value,
        title => $title,
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
