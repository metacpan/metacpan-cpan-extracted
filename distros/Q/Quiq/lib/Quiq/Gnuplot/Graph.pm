package Quiq::Gnuplot::Graph;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gnuplot::Graph - Gnuplot-Graph

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Graph.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Graph-Objekt

=head4 Synopsis

    $gph = Quiq::Gnuplot::Graph->new(@keyVal);

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        title => undef,
        with => undef,
        style => undef,
        data => [],
    );
    $self->set(@_);
    
    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 hasData() - Prüfe, ob Graph Daten hat

=head4 Synopsis

    $bool = $gph->hasData;

=cut

# -----------------------------------------------------------------------------

sub hasData {
    my $self = shift;
    my $dataA = $self->{'data'};
    return @$dataA? 1: 0;
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
