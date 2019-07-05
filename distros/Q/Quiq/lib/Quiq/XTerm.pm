package Quiq::XTerm;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Quiq::Shell;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::XTerm - XTerminal Fenster

=head1 BASE CLASS

L<Quiq::Hash>

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere XTerminal-Fenster-Objekt

=head4 Synopsis

    $xtl = $class->new;
    $xtl = $class->new($program);

=head4 Arguments

=over 4

=item $program

Art des X-Terminals. Mögliche Werte: 'xterm' (Default),
'gnome-terminal'.

=back

=head4 Description

Instantiiere ein XTerminal-Fenster-Objekt und liefere eine
Referenz auf dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    my $program = shift || 'xterm';

    if ($program !~ /^(xterm|gnome-terminal)$/) {
        $class->throw(
            'XTERM-00001: Unknown terminal type',
            Type => $program,
        );
    }

    return $class->SUPER::new(
        program => $program,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 launch() - Öffne X-Term und führe Kommando aus

=head4 Synopsis

    $xtl->launch($x,$y,$width,$height,$cmdLine);

=head4 Arguments

=over 4

=item $x

X-Koordinate des Fensters.

=item $y

X-Koordinate des Fensters.

=item $width

Breite des Fensters in Zeichen.

=item $height

Höhe des Fensters in Zeichen.

=item $cmdLine

Kommandozeile des Programms, das gestartet werden soll.

=back

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub launch {
    my ($self,$x,$y,$width,$height,$cmdLine) = @_;

    my $program = $self->program;

    my $cmd = $program;
    if ($program eq 'xterm') {
        $cmd .= " -geometry ${width}x${height}+$x+$y";
    }
    elsif ($program eq 'gnome-terminal') {
        $cmd .= " --geometry=${width}x${height}+$x+$y";
    }

    # $cmd .= qq| -e "`launch $cmdLine`"|;
    $cmd .= qq| -e "$cmdLine"|;

    Quiq::Shell->exec("$cmd &",log=>1);

    return;
}

# -----------------------------------------------------------------------------

=head3 program() - Name des Programms

=head4 Synopsis

    $program = $xtl->program;

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
