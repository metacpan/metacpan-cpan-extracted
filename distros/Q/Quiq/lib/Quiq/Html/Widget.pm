package Quiq::Html::Widget;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Html::Widget - Basisklasse für HTML-Widgets

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse implementiert Funktionalität, die allen Widget-Klassen
gemeinsam ist. Sie besitzt keinen Konstruktor, setzt also in den
abgeleiteten Widget-Klassen die Existenz gewisser Attribute
voraus.

=head2 Grundsätzliches über Widget-Klassen

Die Klassen generieren HTML ohne visuelle Eigenschaften. Visuelle
Eigenschaften sollten per CSS definiert werden. Die Verbindung zur
Stylesheet-Definition wird über die Objektattribute C<class> und
C<id> hergestellt. Das Attribut C<style> existiert, sollte aber
möglichst nicht benutzt werden, damit der HTML-Quelltext frei von
CSS-Eigenschaften bleibt.

=over 2

=item *

Jedes Widget hat einen Namen, der mit $w->name() abgefragt
werden kann.

=item *

Jedes Widget hat einen Wert, der mit $w->value() abgefragt und
gesetzt werden kann. Dieser Wert ist entweder ein skalarer Wert
oder ein Array von Werten.

=item *

Jedes Widget ist entweder sichtbar oder unsichtbar, was mit
$w->hidden() geprüft werden kann.

=item *

Jedes Widget ist entweder dekativiert oder aktiviert, was mit
$w->disabled() festgestellt werden kann.

=back

=head1 METHODS

=head2 Objektmethoden

=head3 name() - Name des Widget

=head4 Synopsis

    $name = $w->name;
    $name = $w->name($name);

=head4 Description

Liefere/Setze den Namen des Widget.

=cut

# -----------------------------------------------------------------------------

sub name {
    my $self = shift;
    # @_: $name

    if (@_) {
        $self->set(name=>shift);
    }

    return $self->get('name');
}

# -----------------------------------------------------------------------------

=head3 value() - Wert des Widget

=head4 Synopsis

    $value | $valueA = $w->value;
    $value = $w->value($value);
    $valueA = $w->value(\@values);

=head4 Description

Liefere und/oder setze den Wert des Widget.

=cut

# -----------------------------------------------------------------------------

sub value {
    my $self = shift;
    # @_: $value -or- $valueA

    my $multi = $self->exists('values')? 1: 0;

    if (@_) {
        my $arg = shift;
        if ($multi) {
            if (!ref $arg) {
                $arg = [$arg];
            }
            $self->{'values'} = $arg;
        }
        else {
            if (ref $arg) {
                if (@$arg > 1) {
                    $self->throw;
                }
                $arg = $arg->[0];
            }
            $self->{'value'} = $arg;
        }
    }
    
    return $multi? $self->{'values'}: $self->{'value'};
}

# -----------------------------------------------------------------------------

=head3 hidden() - Hidden-Eingenschaft des Widget

=head4 Synopsis

    $bool = $w->hidden;

=head4 Description

Liefere die Hidden-Eigenschaft des Widget.

=cut

# -----------------------------------------------------------------------------

sub hidden {
    return shift->get('hidden');
}

# -----------------------------------------------------------------------------

=head3 disabled() - Disabled-Eingenschaft des Widget

=head4 Synopsis

    $bool = $w->disabled;

=head4 Description

Liefere die Disabled-Eigenschaft des Widget.

=cut

# -----------------------------------------------------------------------------

sub disabled {
    return shift->get('disabled');
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.149

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
