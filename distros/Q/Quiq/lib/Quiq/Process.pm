# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Process - Informationen über den laufenden Prozess

=head1 BASE CLASS

L<Quiq::System>

=cut

# -----------------------------------------------------------------------------

package Quiq::Process;
use base qw/Quiq::System/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Path;
use Cwd ();
use Quiq::System;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 cwd() - Aktuelles Verzeichnis (Liefern/Setzen)

=head4 Synopsis

  $dir = $this->cwd;
  $this->cwd($dir);

=head4 Alias

cd()

=head4 Description

Liefere das aktuelle Verzeichnis ("current working directory") des
Prozesses. Ist ein Argument angegeben, wechsele in das betreffende
Verzeichnis. Tilde-Nt

=head4 Examples

Liefere aktuelles Verzeichnis:

  $dir = Quiq::Process->cwd;

Wechsele Verzeichnis:

  Quiq::Process->cwd('/tmp');

=cut

# -----------------------------------------------------------------------------

sub cwd {
    my $this = shift;
    # @_: $dir

    if (!@_) {
        return Cwd::cwd;
    }

    my $dir = Quiq::Path->expandTilde(shift);
    if (!defined($dir) || $dir eq '' || $dir eq '.') {
        return;
    }
    CORE::chdir $dir or do {
        $this->throw(
            'PROCESS-00001: Cannot change directory',
            Directory => $dir,
            CurrentWorkingDirectory => Cwd::cwd,
        );
    };

    return;
}

{
    no warnings 'once';
    *cd = \&cwd;
}

# -----------------------------------------------------------------------------

=head3 euid() - Effektive User-Id (Liefern/Setzen)

=head4 Synopsis

  $uid = $this->euid;
  $this->euid($uid);

=head4 Description

Liefere die Effektive User-Id (EUID) des Prozesses. Ist ein Argument
angegeben, setze die EUID auf die betreffende User-Id.

Um die Effektive User-Id zu ermitteln, kann auch einfach die globale
Perl-Variable $> abgefragt werden.

=head4 Examples

Liefere aktuelle EUID:

  $uid = Quiq::Process->euid;

Setze EUID:

  Quiq::Process->euid(1000);

=cut

# -----------------------------------------------------------------------------

sub euid {
    my $this = shift;
    # @_: $uid

    if (!@_) {
        return $>;
    }

    my $uid = shift;
    $> = $uid;
    if ($> != $uid) {
        $this->throw(
            'PROCESS-00002: Cannot set effective user id (EUID)',
            UID => $<,
            EUID => $>,
            NewEUID => $uid,
            Error => "$!",
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head3 homeDir() - Home-Verzeichnis des Benutzers

=head4 Synopsis

  $path = $this->homeDir;
  $path = $this->homeDir($subPath);

=head4 Description

Liefere das Home-Verzeichnis des Benutzers, der den Prozess
ausführt.

=cut

# -----------------------------------------------------------------------------

sub homeDir {
    my $this = shift;
    # @_: $subPath

    if (!exists $ENV{'HOME'}) {
        $this->throw(
            'PROCESS-00003: Environment variable HOME does not exist',
        );
    }

    my $path = $ENV{'HOME'};
    if (@_) {
        $path .= "/$_[0]";
    }

    return $path;
}

# -----------------------------------------------------------------------------

=head3 mtime() - Zeitpunkt der letzten Änderung am Programm

=head4 Synopsis

  $mtime = $this->mtime;

=head4 Returns

Unix Epoch (Integer)

=head4 Description

Liefere den Zeitpunkt der letzten Änderung an den Dateien
des (Perl-)Prozesses in Unix Epoch.

Diese Information ist nützlich, wenn das Programm z.B. Dateien
generiert und selbst entscheiden möchte, ob eine Neugenerierung
aufgrund einer Änderung am Programm nötig ist.

=cut

# -----------------------------------------------------------------------------

sub mtime {
    my $this = shift;

    my $mtime = (stat($0))[9];
    for (values %INC) {
        if ((my $t = (stat)[9]) > $mtime) {
            $mtime = $t;
        }
    }

    return $mtime;
}

# -----------------------------------------------------------------------------

=head3 uid() - UID des Prozesses oder eines (beliebigen) Benutzers

=head4 Synopsis

  $uid = $this->uid;
  $uid = $this->uid($user);

=head4 Description

Liefere die reale User-Id des Prozesses. Ist Parameter $user
angegeben, liefere die User-Id des betreffenden Benutzers.

=cut

# -----------------------------------------------------------------------------

sub uid {
    my ($this,$user) = @_;
    return $user? $this->SUPER::uid($user): $<;
}

# -----------------------------------------------------------------------------

=head3 user() - Name des ausführenden Benutzers

=head4 Synopsis

  $user = $this->user;

=head4 Description

Liefere den Namen des Benutzers, unter dessen Rechten der
Prozess ausgeführt wird.

=cut

# -----------------------------------------------------------------------------

sub user {
    my $this = shift;
    return Quiq::System->user($>);
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
