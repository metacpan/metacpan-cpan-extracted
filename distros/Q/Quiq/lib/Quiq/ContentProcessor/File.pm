# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ContentProcessor::File - Basisklasse für Ausgabe-Dateien

=head1 BASE CLASS

L<Quiq::Hash>

=cut

# -----------------------------------------------------------------------------

package Quiq::ContentProcessor::File;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Datei-Objekt

=head4 Synopsis

  $fil = $class->new($ent,@keyVal);

=cut

# -----------------------------------------------------------------------------

sub new {
    my ($class,$ent) = splice @_,0,2;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        entity => $ent,
        name => undef,
        type => undef,
        data => undef,
        method => undef,
        isCode => 0,
        mode => undef,
    );
    $self->set(@_);
    $self->weaken('entity');
    
    return $self;
}

# -----------------------------------------------------------------------------

=head2 Generierung

=head3 generate() - Generiere Datei-Inhalt

=head4 Synopsis

  $data = $fil->generate;

=cut

# -----------------------------------------------------------------------------

sub generate {
    my $self = shift;

    if (my $method = $self->get('method')) {
        return $self->$method();
    }
    
    return $self->data;
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
