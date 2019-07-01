package Quiq::Html::Widget::TextField;
use base qw/Quiq::Html::Widget/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

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

=item size => $n (Default: undef)

Breite des Feldes in Zeichen.

=item title => $text (Deafult: undef)

Text Tooltip.

=item value => $str (Default: undef)

Anfänglicher Wert des Textfelds.

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
        maxLength => undef,
        name => undef,
        onKeyUp => undef,
        size => undef,
        style => undef,
        title => undef,
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

    my ($class,$disabled,$id,$maxLength,$name,$onKeyUp,$size,$style,
        $title,$value) = $self->get(qw/class disabled id maxLength name
        onKeyUp size style title value/);

    if (!defined $maxLength) {
        $maxLength = $size;
    }
    elsif ($maxLength == 0) {
        $maxLength = undef;
    }

    # Generierung

    return $h->tag('input',
        type => 'text',
        id => $id,
        class => $class,
        style => $style,
        name => $name,
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
