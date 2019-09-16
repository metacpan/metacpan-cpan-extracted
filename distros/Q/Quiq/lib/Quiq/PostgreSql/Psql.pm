package Quiq::PostgreSql::Psql;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.157';

use Quiq::Udl;
use Quiq::CommandLine;
use Expect ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::PostgreSql::Psql - Wrapper für psql

=head1 BASE CLASS

L<Quiq::Object>

=head1 SYNOPSIS

    use Quiq::PostgreSql::Psql;
    
    Quiq::PostgreSql::Psql->psql($database);

=head1 DESCRIPTION

Die Klasse stellt einen Wrapper für den PostgreSQL-Client psql dar.

=head1 METHODS

=head2 Klassenmethoden

=head3 run() - Rufe psql für interaktive Nutzung auf

=head4 Synopsis

    $class->run($database);

=head4 Arguments

=over 4

=item $database

Name der Datenbank oder der Universal Database Locator (UDL).
Der Name muss in der Datenbank-Konfigurationsdatei definiert sein.

=back

=head4 Description

Rufe psql für die interaktive Nutzung am Terminal auf. Der Vorteil dieser
Methode ist, dass die Datenbank per Name kontaktiert werden kann, wenn
der UDL in die Konfiguration (s. Quiq::Database::Config) eingetragen
wurde.

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
    my ($class,$database) = @_;

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
    if (my $database = $udl->db) {
        $c->addArgument($database);
    }

    my $cmd = $c->command;
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
    ],[
        # ohne Passwort
        -re => '^psql ',sub {
            $interact = 1;
        },
    ],[
        # Verbindung kommt nicht zustande
        -re => '^psql:',sub {
            # Ende der Kommunikation
        },
    ]);

    if ($interact) {
        # Benutzer-Interaktion
        $exp->interact;
    }

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.157

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
