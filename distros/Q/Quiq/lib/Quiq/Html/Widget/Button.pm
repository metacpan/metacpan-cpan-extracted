package Quiq::Html::Widget::Button;
use base qw/Quiq::Html::Widget/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Widget::Button - Schaltfläche

=head1 BASE CLASS

L<Quiq::Html::Widget>

=head1 ATTRIBUTES

=over 4

=item class => $class (Default: undef)

CSS Klasse.

=item content => $html (Default: undef)

Button-Label (allgemeiner HTML-Content).

=item disabled => $bool (Default: 0)

Keine Eingabe möglich.

=item hidden => $bool (Default: 0)

Nicht sichtbar.

=item id => $id (Default: undef)

CSS-Id.

=item name => $name (Default: undef)

Name, unter dem der Button kommuniziert wird.

=item onClick => \@arr (Default: [])

OnClick-Handler.

=item style => $style (Default: undef)

CSS Definition (inline).

=item title => $str (Default: undef)

Tooltip-Text.

=item type => $type (Default: 'button')

Button-Typ:  'button', 'submit' oder 'reset'.

=item value => $value (Default: undef)

Wert, der gesendet wird.

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
        content => undef,
        disabled => 0,
        hidden => 0,
        id => undef,
        name => undef,
        onClick => undef,
        style => undef,
        title => undef,
        type => 'button',
        value => undef,
    );
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

    my ($class,$content,$disabled,$hidden,$id,$name,$onClick,$style,
        $title,$type,$value) = $self->get(qw/class content disabled hidden id
        name onClick style title type value/);

    if ($hidden) {
        return '';
    }

    return $h->tag('button',
        id => $id,
        name => $name,
        type => $type,
        class => $class,
        style => $style,
        value => $value,
        disabled => $disabled,
        onclick => $onClick,
        $content || $value
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.147

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
