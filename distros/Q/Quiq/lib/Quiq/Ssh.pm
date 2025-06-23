# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Ssh - Führe Kommando per SSH aus

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine SSH-Verbindung zu einem Host.
Über die Verbindung können Shell-Kommandos ausgeführt werden. Die
Klasse ist ein Wrapper für die Klasse Net::SSH::Perl, die das
SSH Netzprotokoll direkt spricht.

=head2 Installation

Sollte es bei der Installation von Net::SSH::Perl in
Crypt::Curve25519 zu dem Fehler kommen

  curve25519-donna-c64.c:99:1: error: conflicting types for ‘fmul’
   fmul(felem output, const felem in2, const felem in) {
   ^~~~
  In file included from /home/fs2/sys/opt/perlbrew/perls/perl-5.30.0/lib/5.30.0/x86_64-linux/CORE/perl.h:2068,
                   from Curve25519.xs:3:
  /usr/include/x86_64-linux-gnu/bits/mathcalls-narrow.h:30:20: note: previous declaration of ‘fmul’ was here
   __MATHCALL_NARROW (__MATHCALL_NAME (mul), __MATHCALL_REDIR_NAME (mul), 2);
              ^~~~~~~~~~~~~~~

kann dieser mit

  $ grep -rl "fmul" ./ | xargs sed -i 's/fmul/fixedvar/g'

behoben werden. Siehe: L<https://github.com/ajgb/crypt-curve25519/issues/9#issuecomment-447845725>

=head1 EXAMPLE

Zeige den Inhalt des Homeverzeichnisses auf Host dssp an:

  $ perl -MQuiq::Ssh -E 'print Quiq::Ssh->new("dssp")->exec("ls")'

=cut

# -----------------------------------------------------------------------------

package Quiq::Ssh;
use base qw/Quiq::Hash/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Parameters;
use Net::SSH::Perl ();
use Quiq::Shell;
use Quiq::Exit;
use Encode ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $ssh = $class->new($host,@opt);

=head4 Arguments

=over 4

=item $host

Hostname

=back

=head4 Options

=over 4

=item -debug => $bool (Default: 0)

Schreibe Debug-Information über die SSH-Kommunikation nach STDERR.

=item -loginShell => $bool (Default: 1)

Default für Methode exec(): Führe Kommandos per Login-Shell aus.

=item -user => $user (Default: I<Wert von $USER>)

Name des Benutzers.

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt für die Ausführung von Kommandos via SSH
auf Host $host über den Benutzer $user.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: $host,@opt

    # Argumente und Optionen

    my ($argA,$opt) = Quiq::Parameters->extractToObject(\@_,1,1,
        -debug => 0,
        -loginShell => 1,
        -user => $ENV{'USER'},
    );
    my $host = shift @$argA;

    # Operation ausführen

    my $obj = Net::SSH::Perl->new($host,
        # interactive => 0,
        debug => $opt->debug,
    );

    # Login

    eval {$obj->login($opt->user)};
    if ($@) {
        $@ =~ s/ at .*//;
        $class->throw(
            'SSH-00099: Login failed',
            Reason => $@,
        );
    }

    # Objekt instantiieren

    return $class->SUPER::new(
        loginShell => $opt->loginShell,
        obj => $obj,
    );
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 exec() - Führe Kommando aus

=head4 Synopsis

  ($stdout,$stderr) = $ssh->exec($cmd,@opt);
  ($stdout,$stderr,$exit) = $ssh->exec($cmd,-sloppy=>1,@opt);

=head4 Arguments

=over 4

=item $cmd (String)

Kommandozeile

=back

=head4 Options

=over 4

=item -loginShell => $bool (Default: I<Wert der Option beim Konstruktor>)

Führe das Remote-Kommando unter einer Login-Shell aus. Als Shell
wird die bash verwendet.

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn das Remote-Kommando fehlschlägt, sondern
liefere den Exitcode als dritten Returnwert zurück.

=back

=head4 Returns

=over 4

=item $stdout

(String) Ausgabe des Kommandos auf stdout. Wenn keine Ausgabe, Leerstring.

=item $stderr

(String) Ausgabe des Kommandos auf stderr. Wenn keine Ausgabe, Leerstring.

=item $exit

(Integer) Exitcode des Kommandos. Wird gesetzt, wenn C<< -sloppy=>1 >> ist,
sonst konstant 0.

=back

=cut

# -----------------------------------------------------------------------------

sub exec {
    my $self = shift;
    # @_: $cmd,@opt

    # Argumente und Optionen

    my $loginShell = $self->get('loginShell');
    my $sloppy = 0;

    my $argA = $self->parameters(1,1,\@_,
        -loginShell => \$loginShell,
        -sloppy => \$sloppy,
    );
    my $cmd = shift @$argA;

    # Operation ausführen

    if ($loginShell) {
        # Login-Shell

        $cmd =~ s/'/\\'/g; # Single Quotes schützen
        $cmd = "/bin/bash -lc '$cmd'";
    }

    # Wenn wir Encoden gibt es bei </dev/null folgende Meldung:
    # "sysread() is deprecated on :utf8 handles. This will be a
    # fatal error in Perl 5.30 at .../Net/SSH/Perl/Channel.pm line 156."
    $cmd = Encode::encode('utf-8',$cmd);
    # $cmd = Encode::decode('utf-8',$cmd);
    my ($stdout,$stderr,$exit) = $self->obj->cmd($cmd);
    $stdout //= '';
    $stderr //= '';
    $exit //= 0;
    if (!$sloppy) {
        # $exit ist als Exitcode kodiert
        # Quiq::Shell->checkError($exit*256,undef,$cmd);
        Quiq::Exit->check($exit*256,$cmd);
    }

    return ($stdout,$stderr,$exit);
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
