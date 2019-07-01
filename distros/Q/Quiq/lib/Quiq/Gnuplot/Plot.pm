package Quiq::Gnuplot::Plot;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Quiq::Gnuplot::Graph;
use Quiq::Gnuplot::Arrow;
use Quiq::Gnuplot::Label;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Gnuplot::Plot - Gnuplot-Plot

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Plot.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Plot-Objekt

=head4 Synopsis

    $plt = Quiq::Gnuplot::Plot->new;

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        terminal => undef,
        output => undef,
        timeSeries => 0,
        formatX => undef,
        ytics => undef,
        yMin => undef,
        yMax => undef,
        title => undef,
        titleFont => 'giant',
        xlabel => undef,
        ylabel => undef,
        width => undef,
        height => undef,
        graphs => [],
        arrows => [],
        labels => [],
        mxTics => 1,
        myTics => 1,
        legendPosition => 'left top',
        xMin => undef,
        xMax => undef,
    );
    $self->set(@_);
    
    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 title() - Setze/liefere Plot-Titel

=head4 Synopsis

    $title = $plt->title;
    $title = $plt->title($title);

=cut

# -----------------------------------------------------------------------------

sub title {
    my $self = shift;
    # @_: $title

    if (@_) {
        $self->{'title'} = shift;
    }

    return $self->{'title'};
}

# -----------------------------------------------------------------------------

=head3 addGraph() - Füge Graph zum Plot-Objekt hinzu

=head4 Synopsis

    $plt->addGraph($gph);
    $plt->addGraph(@keyVal);

=head4 Alias

add()

=head4 Description

Füge Graph $gph oder einen Graph mit der Attributen @keyVal
zum Plot hinzu. In letzterem Fall instantiiert die Methode
das Quiq::Gnuplot::Graph-Objekt.

=cut

# -----------------------------------------------------------------------------

sub addGraph {
    my $self = shift;
    # @_: $gph -oder- @keyVal

    my $gph;
    if (@_ == 1) {
        $gph = shift;
    }
    else {
        $gph = Quiq::Gnuplot::Graph->new(@_);
    }
    push @{$self->{'graphs'}},$gph;

    return;
}

{
    no warnings 'once';
    *add = \&addGraph;
}

# -----------------------------------------------------------------------------

=head3 addArrow() - Füge Arrow zum Plot-Objekt hinzu

=head4 Synopsis

    $plt->addArrow($arw);
    $plt->addArrow(@keyVal);

=head4 Description

Füge Arrow $arw oder einen Arrow mit der Attributen @keyVal
zum Plot hinzu. In letzterem Fall instantiiert die Methode
selbst das Quiq::Gnuplot::Arrow-Objekt.

=cut

# -----------------------------------------------------------------------------

sub addArrow {
    my $self = shift;
    # @_: $arw -oder- @keyVal

    my $arw;
    if (@_ == 1) {
        $arw = shift;
    }
    else {
        $arw = Quiq::Gnuplot::Arrow->new(@_);
    }
    push @{$self->{'arrows'}},$arw;

    return;
}

# -----------------------------------------------------------------------------

=head3 addLabel() - Füge Label zum Plot-Objekt hinzu

=head4 Synopsis

    $plt->addLabel($lab);
    $plt->addLabel(@keyVal);

=head4 Description

Füge Label $lab oder ein Label mit den Attributen @keyVal
zum Plot hinzu. In letzterem Fall instantiiert die Methode
selbst das Quiq::Gnuplot::Label-Objekt.

=cut

# -----------------------------------------------------------------------------

sub addLabel {
    my $self = shift;
    # @_: $lab -oder- @keyVal

    my $lab;
    if (@_ == 1) {
        $lab = shift;
    }
    else {
        $lab = Quiq::Gnuplot::Label->new(@_);
    }
    push @{$self->{'labels'}},$lab;

    return;
}

# -----------------------------------------------------------------------------

=head3 graphsWithData() - Liefere Graphen mit Daten

=head4 Synopsis

    @gph | $gphA = $plt->graphsWithData;

=cut

# -----------------------------------------------------------------------------

sub graphsWithData {
    my $self = shift;

    my @arr;
    my $gphA = $self->{'graphs'};
    for my $gph (@$gphA) {
        if ($gph->hasData) {
            push @arr,$gph;
        }
    }

    return wantarray? @arr: \@arr;
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
