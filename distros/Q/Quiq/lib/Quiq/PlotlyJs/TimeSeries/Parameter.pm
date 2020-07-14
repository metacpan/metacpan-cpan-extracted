package Quiq::PlotlyJs::TimeSeries::Parameter;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.185';

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PlotlyJs::TimeSeries::Parameter - Ein zu plottender Parameter

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse speichert Information über eine Zeitreihe, die
von der Klasse Quiq::PlotlyJs::TimeSeries::DiagramGroup
herangezogen wird, um diese in ein Diagramm zu plotten.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

  $par = $class->new(@attVal);

=head4 Attributes

Pflichtangaben sind B<fett> wiedergegeben

=over 4

=item B<< color => $color >>

Farbe, in der die Zeitreihe dargestellt wird. Alle Schreibweisen,
die in CSS erlaubt sind, sind zulässig, also NAME, #XXXXXX
oder rgb(NNN,NNN,NNN,NNN).

=item B<< name => $name >>

Name des Parameters.

=item B<< unit => $unit >>

Einheit der Parameterwerte.

=item x => \@x

Referenz auf Array der Zeit-Werte in JavaScript-Epoch.

=item B<< xMin => $val >>

Kleinster Zeitwert der Zeitreihe.

=item B<< xMax => $val >>

Größter Zeitwert der Zeitreihe.

=item y => \@y

Referenz auf Array der Y-Werte (Weltkoordinaten).

=item B<< yMin => $val >>

Kleinster Parameterwert der Zeitreihe.

=item B<< xMax => $val >>

Größter Parameterwert der Zeitreihe.

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @attVal

    my $self = $class->SUPER::new(
        color => '#ff0000',
        name => 'plot',
        x => [],
        xMin => undef,
        xMax => undef,
        y => [],
        yMin => undef,
        yMax => undef,
        unit => undef,
    );
    $self->set(@_);

    return $self;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.185

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2020 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
