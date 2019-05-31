package Quiq::Config;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.142';

use Quiq::Option;
use Quiq::Path;
use Quiq::Reference;
use Quiq::Unindent;
use Quiq::Perl;
use Quiq::Process;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Config - Konfigurationsdatei in "Perl Object Notation"

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

    use Quiq::Config;
    
    my $cfg = Quiq::Config->new('/etc/myapp/test.conf');
    my $database = $cgf->get('database');

=head1 DESCRIPTION

Ein Objekt der Klasse Quiq::Config repräsentiert eine Menge von
Attribut/Wert-Paaren, die in einer Perl-Datei definiert sind.

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

    [1] $cfg = $class->new($file,@opt);
    [2] $cfg = $class->new(\@dirs,$file,@opt);
    [3] $cfg = $class->new($str);
    [4] $cfg = $class->new(@keyVal);

=head4 Options

=over 4

=item -create => $text

Falls die Konfigurationsdatei nicht existert, erzeuge sie mit
dem Inhalt $text.

=item -secure => $bool (Default: 0)

Prüfe die Sicherheit der Datei. Wenn gesetzt, wird geprüft,
ob die Datei nur für den Benutzer lesbar/schreibbar ist.

=back

=head4 Description

[1] Instantiiere Konfigurationsobjekt aus Datei $file
und liefere eine Referenz auf dieses Objekt zurück. Beginnt $file
mit einer Tilde (~), wird sie zum Homedir des rufenden Users
expandiert.

[2] Durchsuche die Verzeichnisse @dirs nach Datei $file. Beginnt
ein Verzeichnisname mit einer Tilde (~), wird sie zum Homedir des
rufenden Users expandiert. Die erste gefundene Datei wird
geöffnet. Ein Leerstring '' in @dirs hat dieselbe Bedeutung wie
'.' und steht für das aktuelle Verzeichnis.

[3] Als Parameter ist der Konfigurationscode als Zeichenkette
der Form "$key => $val, ..." angegeben.

[4] Die Konfiguration ist inline angegeben.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: $file -or- \@dirs,$file -or- $str

    # Optionen

    my $create = undef;
    my $secure = 0;

    Quiq::Option->extract(\@_,
        -create => \$create,
        -secure => \$secure,
    );

    # Operation ausführen

    my %cfg;
    if (@_ == 1 && $_[0] =~ /=>/) { # "$key => $val, ..."
        %cfg = eval shift;
    }
    elsif (@_ >= 2 && !ref $_[0]) { # @keyVal
        %cfg = @_;
    }
    else {
        # $file -or- \@dirs,$file

        my $p = Quiq::Path->new;

        # Datei suchen

        my $dirA;
        if (Quiq::Reference->isArrayRef($_[0])) { # \@dirs
            $dirA = shift;
        }
        my $cfgFile = $p->expandTilde(shift);

        # Configdatei suchen, wenn \@dirs

        if ($dirA) {
            for (@$dirA) {
                my $dir = $p->expandTilde($_);
                my $file = $dir? "$dir/$cfgFile": $cfgFile;
                if (-e $file) {
                    $cfgFile = $file;
                    last;
                }
            }
        }

        if ($secure) {
            $p->checkFileSecurity($cfgFile);
        }

        if (substr($cfgFile,0,1) ne '/') {
            # Wenn der Dateiname kein absoluter Pfad ist,
            # müssen wir ./ voranstellen, weil perlDoFile()
            # die Datei sonst nicht findet. Warum?
    
            $cfgFile = "./$cfgFile";
        }
    
        if (!-e $cfgFile) {
            if (defined $create) {
                $create = Quiq::Unindent->trimNl($create);
                Quiq::Path->write($cfgFile,$create,-recursive=>1);
            }
            else {
                $class->throw('CFG-00002: Config file not found',
                    ConfigFile => $cfgFile,
                );
            }
        }

        %cfg = Quiq::Perl->perlDoFile($cfgFile);
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
                'CFG-00001: Config-Variable existiert nicht',
                Variable => $key,
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
                    $val =~ s/%CWD%/Quiq::Process->cwd/e;
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

1.142

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
