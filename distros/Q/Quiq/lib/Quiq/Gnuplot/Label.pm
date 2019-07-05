package Quiq::Gnuplot::Label;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gnuplot::Label - Gnuplot-Label

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert ein Label, also einen frei
positionierbaren Text.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Label-Objekt

=head4 Synopsis

    $lab = Quiq::Gnuplot::Label->new(@keyVal);

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        at => [], # [$x,$y]
        text => undef,
        textColor => undef,
        font => undef,
    );
    $self->set(@_);
    
    return $self;
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
