# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Database::Config - Datenbank-Konfiguration

=head1 BASE CLASS

L<Quiq::Config>

=head1 DESCRIPTION

Die Klasse kapselt den Zugriff auf eine Konfigurationsdatei, in
der Eingenschaften von einer oder mehrerer Datenbanken hinterlegt sind.
Es können beliebige Eigenschaften spezifiziert werden.
Speziell wird die Abfrage des Universal Database Locators (UDL)
unterstützt. Die Datei darf wegen etwaig enthaltener Passwörter
nur für den Owner lesbar/schreibbar sein. Ist sie es nicht, wird
eine Exception geworfen.

=head2 Aufbau der Konfigurationsdatei

  '<database>' => {
      udl => '<udl>',
      ...
  },
  ...

=over 2

=item *

<database> ist ein beliebger Bezeichner.

=item *

<udl> ist der UDL der Datenbank.

=item *

Der Konfigurationshash {...} wird im Konstruktor zu einem
ungelockten Quiq::Hash instantiiert. Entsprechend können die
Methoden der Klasse Quiq::Hash zum Lesen der
Konfigurationseinträge genutzt werden.

=back

=head1 EXAMPLE

  use Quiq::Database::Config;
  
  $cfg = Quiq::Database::Config->new('~/project/test/db.conf');
  $udl = $cfg->udl('test_db');

=cut

# -----------------------------------------------------------------------------

package Quiq::Database::Config;
use base qw/Quiq::Config/;

use v5.10;
use strict;
use warnings;

our $VERSION = '1.228';

use Quiq::Path;
use Quiq::Hash;

# -----------------------------------------------------------------------------

=head1 METHODS

=head2 Klassenmethoden

=head3 new() - Konstruktor

=head4 Synopsis

  $cfg = $class->new;
  $cfg = $class->new($file);

=head4 Arguments

=over 4

=item $file (Default: '~/.db.conf')

Konfigurationsdatei

=back

=head4 Options

=over 4

=item -sloppy => $bool (Default: 0)

Liefere C<undef>, wenn Datei C<$file> nicht existiert.

=back

=head4 Returns

Objekt

=head4 Description

Instantiiere ein Objekt der Klasse und liefere eine Referenz auf dieses
Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: $file,@opt

    # Optionen

    my $sloppy = 0;

    my $argA = $class->parameters(0,1,\@_,
        -sloppy => \$sloppy,
    );
    my $file = shift @$argA // '~/.db.conf';

    if (!Quiq::Path->exists($file) && $sloppy) {
        return undef;
    }

    # Objekt instantiieren

    my $self = $class->SUPER::new($file,
        -secure => 1,
    );
    for (keys %$self) {
        $self->{$_} = Quiq::Hash->new($self->{$_})->unlockKeys;
    }
    $self->set(configFile=>$file);

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Objektmethoden

=head3 udl() - Universal Database Locator

=head4 Synopsis

  $udl = $cfg->udl($database);

=head4 Arguments

=over 4

=item $database

Name der Datenbank (String).

=back

=head4 Returns

Universal Database Locator (String).

=head4 Description

Ermittele den Universal Database Locator (UDL) der Datenbank $database
und liefere diesen zurück.

=cut

# -----------------------------------------------------------------------------

sub udl {
    my ($self,$database) = @_;

    my $h = $self->try($database) // $self->throw(
        'CONFIG-00001: Database not defined',
        Database => $database,
        ConfigFile => $self->configFile,
    );

    my $udl = $h->try('udl') // $self->throw(
        'CONFIG-00002: No UDL',
        Database => $database,
        ConfigFile => $self->configFile,
    );

    return $udl;
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
