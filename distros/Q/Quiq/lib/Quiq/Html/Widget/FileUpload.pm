# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Widget::FileUpload - Datei Upload Feld

=head1 BASE CLASS

L<Quiq::Html::Widget>

=head1 ATTRIBUTES

=over 4

=item accept => $mimeType (Default: undef)

MIME-Type (oder mit Komma getrennte Liste von MIME-Types) der
Dateien für den Datei-Upload.

=item class => $class (Default: undef)

CSS Klasse des des Feldes.

=item disabled => $bool (Default: 0)

Feld erlaubt keine Eingabe.

=item hidden => $bool (Default: 0)

Widget ist (aktuell) unsichtbar.

=item id => $id (Default: undef)

Id des Feldes.

=item maxLength => $n (Default: Wert von "size")

Maximale Länge des Eingabewerts in Zeichen. Ein Wert von "0" beutet
keine Eingabebegrenzung.

=item size => $n (Default: undef)

Breite des Feldes in Zeichen.

=item name => $name (Default: undef)

Name des Feldes.

=item style => $style (Default: undef)

CSS Definition (inline).

=item undefIf => $bool (Default: 0)

Wenn wahr, liefere C<undef> als Widget-Code.

=back

=cut

# -----------------------------------------------------------------------------

package Quiq::Html::Widget::FileUpload;
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

    my $self = $class->SUPER::new(
        accept => undef,
        class => undef,
        disabled => 0,
        hidden => 0,
        id => undef,
        maxLength => undef,
        name => undef,
        size => undef,
        style => undef,
        undefIf => 0,
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
    # @_: @keyVal

    my $self = ref $this? $this: $this->new(@_);

    # Attribute

    my ($accept,$class,$disabled,$hidden,$id,$maxLength,$name,$size,
        $style,$undefIf,$value) = $self->get(qw/accept class disabled hidden
        id maxLength name size style undefIf value/);

    if (!defined $maxLength) {
        $maxLength = $size;
    }
    elsif ($maxLength == 0) {
        $maxLength = undef;
    }

    # Generierung

    if ($undefIf) {
        return undef;
    }

    if ($hidden) {
        return '';
    }

    return $h->tag('input',
        type => 'file',
        id => $id,
        class => $class,
        style => $style,
        accept => $accept,
        name => $name,
        disabled => $disabled,
        size => $size,
        maxlength => $maxLength,
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
