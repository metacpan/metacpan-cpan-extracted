package Prty::System;
use base qw/Prty::Object/;

use strict;
use warnings;

our $VERSION = 1.113;

use Prty::FileHandle;
use Socket ();
use Sys::Hostname ();
use 5.010;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::System - Information über das System und seine Umgebung

=head1 BASE CLASS

L<Prty::Object>

=head1 METHODS

=head2 Host

=head3 numberOfCpus() - Anzahl der CPUs

=head4 Synopsis

    $n = $this->numberOfCpus;

=head4 Description

Liefere die Anzahl der CPUs des Systems. Diese Methode ist nicht
portabel, sie basiert auf /proc/cpuinfo des Linux-Kernels.

=cut

# -----------------------------------------------------------------------------

sub numberOfCpus {
    my $this = shift;

    my $n = 0;
    my $fh = Prty::FileHandle->new('<','/proc/cpuinfo');
    while (<$fh>) {
        if (/^processor/) {
            $n++;
        }
    }
    $fh->close;

    return $n;
}

# -----------------------------------------------------------------------------

=head3 hostname() - Hostname des Systems oder zu IP

=head4 Synopsis

    $hostname = $this->hostname;
    $hostname = $this->hostname($ip);

=head4 Description

Liefere "den" Hostnamen des Systems. Es ist der Name, den die
Methode Sys::Hostname::hostname() liefert.

=head4 See Also

Sys::Hostname

=cut

# -----------------------------------------------------------------------------

sub hostname {
    my $this = shift;
    # @_: $ip

    if (@_) {
        my $ip = shift;
        # FIXME: Fehlerbehandlung
        return gethostbyaddr(Socket::inet_aton($ip),Socket::AF_INET);
    }

    return Sys::Hostname::hostname;
}

# -----------------------------------------------------------------------------

=head3 ip() - IP des Systems oder zu Hostname

=head4 Synopsis

    $ip = $this->ip;
    $ip = $this->ip($hostname);

=head4 Description

Liefere die IP-Adresse des Systems (Aufruf ohne Parameter) oder die
IP-Adresse für $hostname.

Die IP-Adresse des Systems ist die IP-Adresse zu dem Hostnamen,
den Prty::System->hostname() liefert.

=cut

# -----------------------------------------------------------------------------

sub ip {
    my $this = shift;
    my $host = shift || $this->hostname;

    return Socket::inet_ntoa(scalar gethostbyname $host);
}

# -----------------------------------------------------------------------------

=head2 Encoding

=head3 encoding() - Character-Encoding der Umgebung

=head4 Synopsis

    $encoding = $this->encoding;

=head4 Description

Liefere das in der Umgebung eingestellte Character-Encoding. In dieses
Encoding sollten Ausgaben auf das Terminal gewandelt werden.

Wir ermitteln das Encoding durch Aufruf der internen Funktion
_get_locale_encoding() des Pragmas encoding.

=head4 Example

Gib non-ASCII-Zeichen im Encoding der Umgebung auf STDOUT aus:

    my $encoding = Prty::System->encoding;
    binmode STDOUT,":encoding($encoding)";
    print "äöüßÄÖÜ\n";

=head4 See Also

Pragma encoding

=cut

# -----------------------------------------------------------------------------

sub encoding {
    my $this = shift;
    require encoding;
    my $encoding = encoding::_get_locale_encoding();
    $encoding =~ s/-strict$//; # Korrektur utf-8-strict
    return $encoding;
}

# -----------------------------------------------------------------------------

=head2 User

=head3 user() - Benutzername zu User-Id

=head4 Synopsis

    $user = $this->user($uid);

=head4 Description

Liefere den Namen des Benutzers mit User-Id (UID) $uid.

=cut

# -----------------------------------------------------------------------------

sub user {
    my ($this,$uid) = @_;

    return getpwuid($uid) // do {
        $this->throw(
            q{SYS-00001: Benutzer existiert nicht},
            Uid=>$uid,
            Error=>"$!",
        );
    };
}

# -----------------------------------------------------------------------------

=head3 uid() - User-Id zu Benutzername

=head4 Synopsis

    $uid = $this->uid($user);

=head4 Description

Liefere die User-Id (UID) des Benutzers mit dem Namen $user.

=cut

# -----------------------------------------------------------------------------

sub uid {
    my ($this,$user) = @_;

    return getpwnam($user) // do {
        $this->throw(
            q{SYS-00001: Benutzer existiert nicht},
            User=>$user,
            Error=>"$!",
        );
    };
}

# -----------------------------------------------------------------------------

=head2 Suchpfad

=head3 searchProgram() - Suche Programm via PATH

=head4 Synopsis

    $path = $class->searchProgram($program);

=cut

# -----------------------------------------------------------------------------

sub searchProgram {
    my ($class,$program) = @_;

    if (substr($program,0,1) eq '/') {
        # Wenn absoluter Pfad, diesen liefern
        return $program;
    }

    # PATH absuchen

    for my $path (split /:/,$ENV{'PATH'}) {
        if (-e "$path/$program") {
            return "$path/$program";
        }
    }

    # Nicht gefunden

    $class->throw(
        q{PATH-00020: Programm/Skript nicht gefunden},
        Program=>$program,
        Paths=>$ENV{'PATH'},
    );
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.113

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2017 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
