# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PostgreSql::PgDump - Wrapper für pg_dump

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

  use Quiq::PostgreSql::PgDump;
  
  Quiq::PostgreSql::PgDump->run($database,@opt);

=head1 DESCRIPTION

Die Klasse stellt einen Wrapper für den PostgreSQL-Client pg_dump dar.

=head1 EXAMPLE

  $ perl -MQuiq::PostgreSql::PgDump -E 'Quiq::PostgreSql::PgDump->run("prod","--table","p_muster.admviews","--schema-only","--debug")'

=cut

# -----------------------------------------------------------------------------

package Quiq::PostgreSql::PgDump;
use base qw/Quiq::Object/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Stopwatch;
use Quiq::Udl;
use Quiq::CommandLine;
use Expect ();

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 run() - Rufe pg_dump ohne Passwortabfrage auf

=head4 Synopsis

  $class->run($database,@opt);

=head4 Arguments

=over 4

=item $database

Name der Datenbank oder der Universal Database Locator (UDL).
Ist ein Name angegeben, muss in der Datenbank-Konfigurationsdatei
definiert sein.

=back

=head4 Options

Alle Optionen von C<pg_dump>, plus

=over 4

=item -debug => $bool (Default: 0)

Gib das ausgeführte pg_dump-Kommando auf STDOUT aus.

=back

=cut

# -----------------------------------------------------------------------------

sub run {
    my ($class,$database) = splice @_,0,2;
    # @_: @opt

    my $stw = Quiq::Stopwatch->new;

    # Options (alle anderen Argumente befinden sich auf @_)

    my $debug = 0;

    $class->parameters(1,\@_,
        -debug => \$debug,
    );

    # Führe Operation aus

    my $udl = Quiq::Udl->new($database);
    if ($udl->dbms ne 'postgresql') {
        $class->throw(
            'PSQL-00001: Not a PostgeSQL UDL',
            Udl => $udl->asString,
        );
    }

    my $c = Quiq::CommandLine->new('pg_dump');
    for my $opt (qw/user host port/) {
        if (my $val = $udl->$opt) {
            $c->addLongOption(
                "--$opt" => $val,
            );
        }
    }
    $c->addBoolOption('--schema-only'=>1);
    $c->addString("@_"); 

    if (my $database = $udl->db) {
        $c->addArgument($database);
    }

    my $cmd = $c->command;
    if ($debug) {
        say $cmd;
    }

    my $exp = Expect->new;
    $exp->spawn($cmd) || do {
        $class->throw(
            'EXPECT-00099: Cannot spawn command',
            Command => $cmd,
        );
    };

    # Anmeldung. Wir unterscheiden drei Fälle.

    my $interact = 0;
    $exp->expect(3,[
        # mit Passwort
        -re => 'Password.*?:',sub {
            my $exp = shift;
            $exp->send($udl->password."\n");
            $interact = 1;
        },
    ],
    #[
    #    # ohne Passwort
    #    -re => '^psql ',sub {
    #        $interact = 1;
    #    },
    #],
    [
        # Verbindung kommt nicht zustande
        -re => '^pg_dump:',sub {
            # Ende der Kommunikation
        },
    ]);

    if ($interact) {
        # Benutzer-Interaktion
        $exp->interact;
    }

    printf "Duration: %s\n",$stw->elapsedReadable;

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
