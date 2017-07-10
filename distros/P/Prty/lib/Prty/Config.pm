package Prty::Config;
use base qw/Prty::Hash/;

use strict;
use warnings;

our $VERSION = 1.117;

use Prty::Perl;
use Prty::Process;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Config - Konfigurationsdatei in "Perl Object Notation"

=head1 BASE CLASS

L<Prty::Hash>

=head1 SYNOPSIS

    use Prty::Config;
    
    my $cfg = Prty::Config->new('/etc/myapp/test.conf');
    my $database = $cgf->get('database');

=head1 DESCRIPTION

Ein Objekt der Klasse Prty::Config repräsentiert eine Menge von
Attribut/Wert-Paaren, die in einer Perl-Datei spezifiziert sind.

Beispiel für den Inhalt einer Konfigurationsdatei:

    host => 'localhost',
    datenbank => 'entw1',
    benutzer => ['sys','system']

=head2 Platzhalterersetzung

Im Wert einer Konfigurationsvariable können Platzhalter
eingebettet sein. Ein solcher Platzhalter wird mit Prozentzeichen
(%) begrenzt und beim Lese-Zugriff durch den Wert der betreffenden
Konfigurationsvariable ersetzt. Beispiel:

    Konfigurationsdatei:
    
        VarDir => '/var/opt/myapp',
        SpoolDir => '%VarDir%/spool',
    
    Code:
    
        $val = $cfg->get('SpoolDir');
        =>
        '/var/opt/myapp/spool'

=head2 Besondere Platzhalter

=over 4

=item %CWD%

Wird durch den Pfad des aktuellen Verzeichnisses ersetzt.
Anwendungsfall: Testkonfiguration für Zugriff auf aktuelles
Verzeichnis über einen Dienst wie FTP:

    test.conf
    ---------
    FtpUrl => 'user:passw@localhost:%CWD%'

=back

=head1 METHODS

=head2 Konstruktor

=head3 new() - Instantiiere Konfigurationsobjekt

=head4 Synopsis

    [1] $cfg = $class->new($file);
    [2] $cfg = $class->new(\@dirs,$file);
    [3] $cfg = $class->new($str);
    [4] $cfg = $class->new(@keyVal);

=head4 Description

[1] Instantiiere Konfigurationsobjekt aus Datei $file
und liefere eine Referenz auf dieses Objekt zurück.

[2] Durchsuche die Verzeichnisse @dirs nach Datei $file.
Die erste gefundene Datei wird geöffnet. Ein Leerstring '' in @dirs
hat dieselbe Bedeutung wie '.' und steht für das aktuelle Verzeichnis.

[3] Als Parameter ist der Konfigurationscode als Zeichenkette
der Form "$key => $val, ..." angegeben.

[4] Die Konfiguration ist inline angegeben.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: $file -or- \@dirs,$file -or- $str

    my %cfg;
    if (@_ == 1 && $_[0] =~ /=>/) { # $str ("$key => $val, ...")
        %cfg = eval shift;
    }
    elsif (@_ >= 2 && !ref $_[0]) { # @keyVal
        %cfg = @_;
    }
    else {
        # Parameter

        my $dirA;
        if (Prty::Perl->isArrayRef($_[0])) { # \@dirs
            $dirA = shift;
        }
        my $cfgFile = shift;

        # Configdatei suchen, wenn \@dirs

        if ($dirA) {
            for my $dir (@$dirA) {
                my $file = $dir? "$dir/$cfgFile": $cfgFile;
                if (-e $file) {
                    $cfgFile = $file;
                    last;
                }
            }
        }
 
        if (substr($cfgFile,0,1) ne '/') {
            # Wenn der Dateiname kein absoluter Pfad ist,
            # müssen wir ./ voranstellen, weil perlDoFile()
            # die Datei sonst nicht findet. Warum?
    
            $cfgFile = "./$cfgFile";
        }
    
        if (!-e $cfgFile) {
            $class->throw(q{CFG-00002: Konfigurationsdatei nicht gefunden},
                ConfigFile=>$cfgFile,
            );
        }

        %cfg = Prty::Perl->perlDoFile($cfgFile);
    }

    my $self = bless \%cfg,$class;
    # $self->lockKeys;

    return $self;
}

# -----------------------------------------------------------------------------

=head2 Werte abfragen

=head3 get() - Liefere Konfigurationswerte

=head4 Synopsis

    $val = $cfg->get($key);
    @vals = $cfg->get(@keys);

=head4 Description

Liefere den Wert des Konfigurationsattributs $key bzw. die Werte
der Konfigurationsattribute @keys.

Existiert ein Konfigurationsattribut nicht, wirft die Methode eine
Exception.

=cut

# -----------------------------------------------------------------------------

sub get {
    my $self = shift;
    # @_: @keys

    # Existenz der Attribute überprüfen

    for my $key (@_) {
        if (!exists $self->{$key}) {
            $self->throw(
                q{CFG-00001: Config-Variable existiert nicht},
                Variable=>$key,
            );
        }
    }

    # Aufruf an try() delegieren
    return $self->try(@_);
}

# -----------------------------------------------------------------------------

=head3 try() - Liefere Konfigurationswerte ohne Exception

=head4 Synopsis

    $val = $cfg->try($key);
    @vals = $cfg->try(@keys);

=head4 Description

Liefere den Wert des Konfigurationsattributs $key bzw. die Werte
der Konfigurationsattribute @keys. Existiert ein
Konfigurationsattribut nicht, liefere undef.

=cut

# -----------------------------------------------------------------------------

sub try {
    my $self = shift;
    # @_: @keys

    my @arr;
    for my $key (@_) {
        my $val = $self->{$key};
        if (!ref $val && defined $val) {
            # Platzhalter suchen und ersetzen
            for my $key ($val =~ /%(\w+)%/g) {
                if ($key eq 'CWD') {
                    $val =~ s/%CWD%/Prty::Process->cwd/e;
                }
                else {
                    $val =~ s/%$key%/$self->get($key)/e;
                }
            }
        }
        push @arr,$val;
    }

    return wantarray? @arr: $arr[0];
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.117

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
