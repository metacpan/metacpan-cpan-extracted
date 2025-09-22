# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Zugferd::Entity::Umsatzsteuer - Umsatzsteuer

=head1 BASE CLASS

L<Quiq::Zugferd::Entity>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Umsatzsteuersatz.

=cut

# -----------------------------------------------------------------------------

package Quiq::Zugferd::Entity::Umsatzsteuer;
use base qw/Quiq::Zugferd::Entity/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.231';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $vrk = $class->new(@keyVal);

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        prozentsatz => undef,           # BT-119
        summeBetraege => undef,         # BT-116
        umsatzsteuerbetrag => undef,    # BT-117
        umsatzsteuerkategorie => undef, # BT-118
        befreiungsgrund => undef,       # BT-120
        m3Umsatzsteuercode => undef,    # intern
        assigned => 0,                  # intern
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.231

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
