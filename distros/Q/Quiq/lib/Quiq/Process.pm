package Quiq::Process;
use base qw/Quiq::System/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.151';

use Cwd ();
use Quiq::System;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Process - Information über den laufenden Prozess

=head1 BASE CLASS

L<Quiq::System>

=head1 METHODS

=head2 Prozess-Eigenschaften

=head3 cwd() - Aktuelles Verzeichnis (Liefern/Setzen)

=head4 Synopsis

    $dir = $this->cwd;
    $this->cwd($dir);

=head4 Alias

cd()

=head4 Description

Liefere das aktuelle Verzeichnis ("current working directory") des
Prozesses. Ist ein Argument angegeben, wechsele in das betreffende
Verzeichnis.

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

    my $dir = shift;
    if (!defined($dir) || $dir eq '' || $dir eq '.') {
        return;
    }
    CORE::chdir $dir or do {
        $this->throw(
            'PROC-00001: Cannot change directory',
            Argument => $dir,
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

    $uid = $class->euid;
    $class->euid($uid);

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
            'PROC-00002: Cannot set EUID',
            UID => $<,
            EUID => $>,
            NewEUID => $uid,
            Error => "$!",
        );
    };

    return;
}

# -----------------------------------------------------------------------------

=head3 user() - Benutzername

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

=head3 homeDir() - Home-Verzeichnis des Benutzers

=head4 Synopsis

    $path = $class->homeDir;
    $path = $class->homeDir($subPath);

=head4 Description

Liefere das Home-Verzeichnis des Benutzers, der den Prozess
ausführt.

=cut

# -----------------------------------------------------------------------------

sub homeDir {
    my $class = shift;
    # @_: $subPath

    if (!exists $ENV{'HOME'}) {
        $class->throw(
            'PROCESS-00001: Environment-Variable HOME existiert nicht',
        );
    }

    my $path = $ENV{'HOME'};
    if (@_) {
        $path .= "/$_[0]";
    }

    return $path;
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
