package Prty::Epoch;
use base qw/Prty::Object/;

use strict;
use warnings;

our $VERSION = 1.124;

use Time::HiRes ();
use POSIX ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Epoch - Ein Zeitpunkt

=head1 BASE CLASS

L<Prty::Object>

=head1 GLOSSARY

=over 4

=item Epoch-Wert

Anzahl der Sekunden seit 1.1.1970, 0 Uhr in hoher Auflösung,
also ggf. mit Nachkommastellen.

=back

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert einen Zeitpunkt. Die Klasse
implementiert Operationen auf einem solchen Zeitpunkt. Der
Zeitpunkt kann hochauflösend sein, also auch Sekundenbruchteile
umfassen.

=head1 METHODS

=head2 Konstruktor

=head3 new() - Konstruktor

=head4 Synopsis

    $t = $class->new;
    $t = $class->new($epoch);

=head4 Description

Instantiiere ein Zeitpunkt-Objekt für Epoch-Wert $epoch und
liefere dieses zurück. Ist kein Epoch-Wert angegeben, wird
der aktuelle Zeitpunkt genommen.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $epoch = shift // scalar(Time::HiRes::gettimeofday);
    return bless \$epoch,$class;
} 

# -----------------------------------------------------------------------------

=head2 Externe Repräsentation

=head3 epoch() - Liefere Epoch-Wert

=head4 Synopsis

    $epoch = $t->epoch;

=head4 Description

Liefere den Epoch-Wert des Zeitpunkts.

=head4 Example

    Prty::Epoch->new->epoch;
    =>
    1464342621.73231

=cut

# -----------------------------------------------------------------------------

sub epoch {
    return ${(shift)}
} 

# -----------------------------------------------------------------------------

=head3 as() - Erzeuge String-Darstellung

=head4 Synopsis

    $str = $t->as($fmt);

=head4 Description

Liefere eine externe Repräsentation gemäß Formatangabe $fmt.
Der Zeitpunkt wird in der lokalen Zeitzone interpretiert.

=head4 Example

    Prty::Epoch->new->as('YYYY-MM-DD HH:MI:SS');
    =>
    2016-05-27 11:50:21

=cut

# -----------------------------------------------------------------------------

sub as {
    my ($self,$fmt) = @_;

    my $strFmt;
    if ($fmt eq 'YYYY-MM-DD HH:MI:SS') {
        $strFmt = '%Y-%m-%d %H:%M:%S';
    }
    else {
        $self->throw;
    }
    
    return POSIX::strftime($strFmt,localtime $$self);
} 

# -----------------------------------------------------------------------------

=head1 VERSION

1.124

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2018 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
