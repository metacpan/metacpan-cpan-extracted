package Quiq::System;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Quiq::Shell;
use Quiq::FileHandle;
use Socket ();
use Sys::Hostname ();
use 5.010;
use Quiq::Option;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::System - Information über das System und seine Umgebung

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Host

=head3 numberOfCpus() - Anzahl der CPUs

=head4 Synopsis

    $n = $this->numberOfCpus;

=head4 Description

Liefere die Anzahl der CPUs des Systems. Diese Methode ist nicht
portabel, sie basiert auf /proc/cpuinfo des Linux-Kernels bzw.
dem dem Kommando 'sysctl -n hw.ncpu' von FreeBSD. Im Falle eines
unbekannten Systems liefert die Methode 1.

=cut

# -----------------------------------------------------------------------------

sub numberOfCpus {
    my $this = shift;

    state $n = 0;
    if (!$n) {
        if ($^O eq 'freebsd') {
            # Fix: CPAN Testers
            $n = Quiq::Shell->exec('sysctl -n hw.ncpu',-capture=>'stdout');
            chomp $n;
        }
        elsif ($^O eq 'linux') {
            my $fh = Quiq::FileHandle->new('<','/proc/cpuinfo');
            while (<$fh>) {
                if (/^processor/) {
                    $n++;
                }
            }
            $fh->close;
        }
        else {
            # Default
            $n = 1;
        }
    }

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
den Quiq::System->hostname() liefert.

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

=head4 See Also

Pragma encoding

=head4 Example

Gib non-ASCII-Zeichen im Encoding der Umgebung auf STDOUT aus:

    my $encoding = Quiq::System->encoding;
    binmode STDOUT,":encoding($encoding)";
    print "äöüßÄÖÜ\n";

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

    $user = $this->user;
    $user = $this->user($uid);

=head4 Description

Liefere den Namen des Benutzers mit User-Id (UID) $uid. Ist keine
User-Id angegeben, verwende die effektive User-Id des laufenden
Prozesses.

=cut

# -----------------------------------------------------------------------------

sub user {
    my $this = shift;
    my $uid = shift // $>;

    return getpwuid($uid) // do {
        $this->throw(
            'SYS-00001: Benutzer existiert nicht',
            Uid => $uid,
            Error => "$!",
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
            'SYS-00001: Benutzer existiert nicht',
            User => $user,
            Error => "$!",
        );
    };
}

# -----------------------------------------------------------------------------

=head2 Suchpfad

=head3 searchProgram() - Suche Programm via PATH

=head4 Synopsis

    $path = $class->searchProgram($program);

=head4 Options

=over 4

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn das Programm nicht gefunden wird,
sondern liefere C<undef>.

=back

=cut

# -----------------------------------------------------------------------------

sub searchProgram {
    my ($class,$program) = splice @_,0,2;

    my $sloppy = 0;

    if (@_) {
        Quiq::Option->extract(\@_,
            -sloppy => \$sloppy,
        );
    }

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

    if ($sloppy) {
        return undef;
    }

    $class->throw(
        'PATH-00020: Programm/Skript nicht gefunden',
        Program => $program,
        Paths => $ENV{'PATH'},
    );
}

# -----------------------------------------------------------------------------

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
