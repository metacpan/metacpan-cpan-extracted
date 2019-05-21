package Quiq::Ssh;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.140';

use Quiq::Parameters;
use Net::SSH::Perl ();
use Quiq::Shell;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Ssh - Führe Kommando per SSH aus

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Ein Objekt der Klasse repräsentiert eine SSH-Verbindung zu einem Host.
Über die Verbindung können Shell-Kommandos ausgeführt werden. Die
Klasse ist ein Wrapper um die Klasse Net::SSH::Perl, die das
SSH Netzprotokoll direkt spricht.

=head1 EXAMPLE

Zeige Inhalt des Homeverzeichnisses auf Host dssp an:

    $ perl -MQuiq::Ssh -E 'print Quiq::Ssh->new("dssp")->exec("ls")'

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
        -user => $ENV{'USER'},
    );
    my $host = shift @$argA;

    # Operation ausführen

    my $obj = Net::SSH::Perl->new($host,
        debug => $opt->debug,
    );

    # Login

    eval {$obj->login($opt->user)};
    if ($@) {
        $@ =~ s/ at .*//;
        $class->throw(
            q~SSH-00099: Login failed~,
            Reason => $@,
        );
    }

    return $class->SUPER::new(
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

=item $cmd

Kommandozeile

=back

=head4 Options

=over 4

=item -login => $bool (Default: 1)

Führe das Remote-Kommando unter einer Login-Shell aus. Als Shell
wird die bash verwendet.

=item -sloppy => $bool (Default: 0)

Wirf keine Exception, wenn das Remote-Kommando fehlschlägt, sondern
liefere den Exitcode als dritten Returnwert zurück.

=back

=head4 Returns

=over 4

=item $stdout

Ausgabe des Kommandos auf stdout.

=item $stderr

Ausgabe des Kommandos auf stderr.

=item $exit

Exitcode des Kommandos. Ist immer 0, außer wenn -sloppy=>1 gesetzt ist.

=back

=cut

# -----------------------------------------------------------------------------

sub exec {
    my $self = shift;
    # @_: $cmd,@opt

    # Argumente und Optionen

    my $login = 1;
    my $sloppy = 0;

    my $argA = Quiq::Parameters->extractToVariables(\@_,1,1,
        -login => \$login,
        -sloppy => \$sloppy,
    );
    my $cmd = shift @$argA;

    # Operation ausführen

    if ($login) {
        # Login-Shell

        $cmd =~ s/'/\\'/g; # Single Quotes schützen
        $cmd = "/bin/bash -lc '$cmd'";
    }

    my ($stdout,$stderr,$exit) = $self->obj->cmd($cmd,'');
    $exit //= 0;
    if (!$sloppy) {
        # $exit ist als Exitcode kodiert
        Quiq::Shell->checkError($exit*256,undef,$cmd);
    }

    return ($stdout,$stderr,$exit);
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.140

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
