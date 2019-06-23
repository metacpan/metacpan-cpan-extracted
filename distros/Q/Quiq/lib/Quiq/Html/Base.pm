package Quiq::Html::Base;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Base - Basisklasse für HTML-Komponenten

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse ist die Basisklasse für alle HTML-Konstrukte, die aus
mehr als einem HTML-Tag aufgebaut sind und/oder eine komplexe
Logik besitzen, die durch eine Klasse gekapselt werden soll.

=head1 ATTRIBUTES

=over 4

=item class => $class (Default: undef)

CSS-Klasse.

=item id => $str (Default: undef)

DOM-Id der Komponente.

=item cssPrefix => $str (Default: '')

Präfix für CSS-Klassennamen. Dieser Präfix wird den
CSS-Klassennamen vorangestellt. (MEMO: dieses Konzept ist zweifelhaft
und sollte abgeschafft werden)

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $obj = $class->new(@keyVal);

=head4 Description

Instantiiere eine Html-Komponente mit allen Attributen (auch
der Subklasse) und liefere eine Referenz auf das Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        class => undef,
        cssPrefix => undef,
        id => undef,
    );
    $self->unlockKeys;
    $self->set(@_); # Wir dürfen die Attribute beliebig erweitern
    $self->lockKeys;

    return $self;
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
