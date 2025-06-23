# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Exit - Prüfe Exitstatus von Child-Prozess

=head1 BASE CLASS

L<Quiq::Object>

=head1 DESCRIPTION

Die Klasse implementiert eine einzelne Methode. Diese prüft den Status
eines terminierten Child-Prozesses. Im Fehlerfall löst sie eine
Exception aus.

=cut

# -----------------------------------------------------------------------------

package Quiq::Exit;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Cwd ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 check() - Prüfe den Status eines terminierten Child-Prozesses

=head4 Synopsis

  $this->check;
  $this->check($exitCode);
  $this->check($exitCode,$cmd);

=head4 Arguments

=over 4

=item $exitCode (Default: $?)

(Integer) Der Returnwert von system() oder $? im Falle von qx// (bzw. ``).

=item $cmd (Default: undef)

(String) Ausgeführtes Kommando. Dieses wird im Fehlerfall
in den Exception-Text eingesetzt.

=back

=head4 Description

Prüfe den Status eines terminierten Child-Prozesses und löse
eine Execption aus, wenn dieser ungleich 0 ist.

=head4 Examples

Prüfe den Status nach Aufruf von system():

  my $r = system($cmd);
  Quiq::Exit->check($r,$cmd);

Minimale Variante (Prüfung über $?):

  system($cmd);
  Quiq::Exit->check;

Prüfe den Status nach Anwendung des Backtick-Operators:

  $str = `$cmd`;
  Quiq::Exit->check($?,$cmd);

=cut

# -----------------------------------------------------------------------------

sub check {
    my $this = shift;
    my $exitCode = shift;
    my $cmd = shift;

    if ($exitCode == 0) {
        return; # ok
    }
    elsif ($exitCode == -1) {
        $this->throw(
            'CMD-00001: Failed to execute command',
            Command => $cmd,
            ErrorMessage => $!,
        );
    }
    elsif ($exitCode & 127) {       # Abbruch mit Signal
        my $sig = $exitCode & 127;  # unterste 8 Bit sind Signalnummer
        my $core = $exitCode & 128; # das 8. Bit zeigt Coredump an
        $this->throw(
            'CMD-00003: Child died with signal',
            Signal => $sig.($core? ' (Coredump)': ''),
            Command => $cmd,
            ErrorMessage => $!,
        );
    }
    $exitCode >>= 8;
    $this->throw(
        'CMD-00002: Command failed with error',
        ExitCode => $exitCode,
        Command => $cmd,
        Cwd => Cwd::getcwd,
        ErrorMessage => $!,
    );
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
