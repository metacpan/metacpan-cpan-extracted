# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PostgreSql::Psql - Wrapper für psql

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

  use Quiq::PostgreSql::Psql;
  
  Quiq::PostgreSql::Psql->run($database,@opt);

=head1 DESCRIPTION

Die Klasse stellt einen Wrapper für den PostgreSQL-Client psql dar.

=cut

# -----------------------------------------------------------------------------

package Quiq::PostgreSql::Psql;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Udl;
use Quiq::CommandLine;
use Expect ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 run() - Starte psql-Sitzung ohne Passworteingabe

=head4 Synopsis

  $exitCode = $class->run($database);

=head4 Arguments

=over 4

=item $database

Name der Datenbank oder der Universal Database Locator (UDL).
Der Name muss in der Datenbank-Konfigurationsdatei definiert sein.

=back

=head4 Options

=over 4

=item -command => $cmd

Führe Kommando $cmd aus und terminiere die Verbindung.

=item -echo => $bool (Default: I<wenn -script 1, sonst 0>)

Gib alle Kommandos, die an den Server geschickt werden, auf stdout aus.

=item -log => $file

Logge Sitzung nach Datei $file.

=item -script => $file

Führe SQL-Skript $file aus und terminiere die Verbindung.

=item -showInternal => $bool (Default: 0)

Gib die Queries aus, die psql im Zusammenhang mit Backslash-Kommandos
intern ausführt.

=item -stopOnError => $bool (Default: I<wenn -script 1, sonst 0>)

Terminiere beim ersten Fehler.

=item -debug => $bool (Default: 0)

Gib das ausgeführte psql-Kommando auf STDOUT aus.

=back

=head4 Returns

Bei interaktiver Sitzung 0. Bei Skript- oder Kommando-Ausführung
wie bei psql(1).

=head4 Description

Rufe psql auf und führe eine Anmeldung durch, auch bei
Passwort-Authentisierung. Die Datenbank kann per Name kontaktiert werden
kann, wenn der UDL in die Konfiguration (s. Quiq::Database::Config)
eingetragen wurde.

=head4 Example

  $ perl -MQuiq::PostgreSql::Psql -E 'Quiq::PostgreSql::Psql->run("test")'
  Password for user xv882js:
  Pager usage is off.
  Timing is on.
  psql (8.2.15)
  SSL connection (cipher: DHE-RSA-AES256-SHA, bits: 256)
  Type "help" for help.
  
  dsstest=>

=cut

# -----------------------------------------------------------------------------

sub run {
    my ($class,$database) = splice @_,0,2;

    # Options

    my $command = undef;
    my $debug = 0;
    my $echo = 0;
    my $log = undef;
    my $script = undef;
    my $showInternal = 0;
    my $stopOnError = 0;

    $class->parameters(\@_,
        -command => \$command,
        -debug => \$debug,
        -echo => \$echo,
        -log => \$log,
        -script => \$script,
        -showInternal => \$showInternal,
        -stopOnError => \$stopOnError,
    );

    # Führe Operation aus

    my $udl = Quiq::Udl->new($database);
    if ($udl->dbms ne 'postgresql') {
        $class->throw(
            'PSQL-00001: Not a PostgeSQL UDL',
            Udl => $udl->asString,
        );
    }

    my $c = Quiq::CommandLine->new('psql');
    for my $opt (qw/user host port/) {
        if (my $val = $udl->$opt) {
            $c->addLongOption(
                "--$opt" => $val,
            );
        }
    }
    $c->addBoolOption('--echo-hidden'=>$showInternal);
    if ($command) {
        $c->addOption(-P=>'pager=off');
        $c->addLongOption('--command'=>$command);
    }
    if ($script) {
        $c->addLongOption('--file'=>$script);
        $stopOnError = 1;
        $echo = 1;
    }
    if ($stopOnError) {
        $c->addLongOption('--set'=>'ON_ERROR_STOP=1');
    }
    $c->addBoolOption('--echo-all'=>$echo);
    $c->addLongOption('--log-file'=>$log);
    if (my $database = $udl->db) {
        $c->addArgument($database);
    }

    my $cmd = $c->command;
    # if ($debug) {
        say $cmd;
    # }

    my $exp = Expect->new;
    if ($debug) {
        $exp->exp_internal(1);
    }
    $exp->spawn($cmd) || do {
        $class->throw(
            'EXPECT-00099: Cannot spawn command',
            Command => $cmd,
        );
    };

    # Anmeldung. Wir unterscheiden drei Fälle.

    my $interact = $command || $script? 0: 1;
    $exp->expect(3,[
        # mit Passwort
        -re => 'Password.*?:',sub {
            my $exp = shift;
            $exp->send($udl->password."\n");
        },
    ],[
        # ohne Passwort
        -re => '^psql ',sub {
        },
    ],[
        # Verbindung kommt nicht zustande
        -re => '^psql:',sub {
            # Ende der Kommunikation
            $interact = 0;
        },
    ]);

    if ($interact) {
        # Benutzer-Interaktion

        $exp->interact;
        return 0;
    }

    $exp->expect(undef);
    return $exp->exitstatus/256;
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
