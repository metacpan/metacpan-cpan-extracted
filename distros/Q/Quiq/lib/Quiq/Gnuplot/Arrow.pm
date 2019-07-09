package Quiq::Gnuplot::Arrow;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gnuplot::Arrow - Gnuplot-Arrow

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Arrow, also eine Linie
zwischen zwei Punkten mit optionaler Dekoration.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Arrow-Objekt

=head4 Synopsis

    $aow = Quiq::Gnuplot::Arrow->new(@keyVal);

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        from => [], # [$x,$y]
        to => [],   # [$x,$y]
        heads => undef, # nohead, head, backhead, heads
        lineType => undef,
        lineWidth => undef,
        lineStyle => undef,
    );
    $self->set(@_);
    
    return $self;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.151

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
