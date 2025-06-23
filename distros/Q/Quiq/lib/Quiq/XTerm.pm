# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::XTerm - XTerminal Fenster

=head1 BASE CLASS

L<Quiq::Hash>

=cut

# -----------------------------------------------------------------------------

package Quiq::XTerm;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Shell;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere XTerminal-Fenster-Objekt

=head4 Synopsis

  $xtl = $class->new;
  $xtl = $class->new($program);

=head4 Arguments

=over 4

=item $program (Default: 'xterm')

X-Terminal-Programm. Mögliche Werte: 'xterm', 'gnome-terminal'.

=back

=head4 Description

Instantiiere ein X-Terminal-Fenster-Objekt und liefere eine
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

=head2 Attributmethoden

=head3 program() - Name des X-Terminals

=head4 Synopsis

  $program = $xtl->program;

=head4 Returns

String

=head4 Description

Liefere den Namen des X-Terminal-Programms (siehe Konstruktor) zurück.

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
