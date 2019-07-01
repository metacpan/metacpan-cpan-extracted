package Quiq::Stopwatch;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.148';

use Time::HiRes ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Stopwatch - Zeitmesser

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

    use Quiq::Stopwatch;
    
    my $stw = Quiq::Stopwatch->new;
    ...
    printf "%.2f\n",$stw->elapsed;

=head1 DESCRIPTION

Die  Klasse implementiert einen einfachen hochauflösenden Zeitmesser.
Mit Aufruf des Konstruktors wird die Zeitmessung gestartet. Mit der
Methode elapsed() kann die seitdem vergangene Zeit abgefragt werden.
Die Zeit wird in Sekunden gemessen. Die Genauigkeit (d.h. die maximale
Anzahl der Nachkommastellen) ist systemabhängig.

=head1 SEE ALSO

Klasse Quiq::Duration

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $stw = $class->new;

=head4 Returns

Stopwatch-Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere dieses zurück. Hiermit
wird die Zeitmessung gestartet.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $t0 = Time::HiRes::gettimeofday;
    return bless \$t0,$class;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 elapsed() - Vergangene Zeit in Sekunden

=head4 Synopsis

    $sec = $stw->elapsed;

=head4 Returns

Sekunden (Float)

=head4 Description

Ermittele die vergangene Zeit in Sekunden und liefere diese zurück.

=cut

# -----------------------------------------------------------------------------

sub elapsed {
    my $self = shift;
    return Time::HiRes::gettimeofday-$$self;
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
