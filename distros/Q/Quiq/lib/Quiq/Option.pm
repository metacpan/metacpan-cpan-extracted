package Quiq::Option;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.148';

use Quiq::Hash;
use Scalar::Util ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Option - Verarbeitung von Programm- und Methoden-Optionen

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Klassenmethoden

=head3 extract() - Extrahiere Optionen aus Argumentliste

=head4 Synopsis

    $opt = $class->extract(@opt,\@args,@keyVal); # Options-Objekt
    $class->extract(@opt,\@args,@keyVal);        # Options-Variablen

=head4 Options

=over 4

=item -dontExtract => $bool (Default: 0)

Entferne die Optionen I<nicht> aus der Argumentliste.

=item -mode => 'strict'|'sloppy' (Default: 'strict')

Im Falle von C<< -mode=>'strict' >> (dem Default), wird eine Exception
ausgelöst, wenn eine unbekannte Option vorkommt. Im Falle von
C<< -mode=>'sloppy' >> wird das Argument stillschweigend übergangen.

=item -properties => $bool (Default: 0)

Argumentliste aus Schlüssel/Wert-Paaren, bei denen die Schlüssel
nicht mit einem Bindestrich (-) beginnen. Eine Unterscheidung
zwischen Optionen und Argumenten gibt es nicht.

=item -simpleMessage => $bool (Default: 0)

Wirf im Falle eines Fehlers eine einzeilige Fehlermeldung als Exception.

=back

=head4 Description

Extrahiere die Optionen @keyVal aus der Argumentliste @args und
weise sie im Void-Kontext Variablen zu oder im Skalar-Kontext
einem Optionsobjekt.

B<Schreibweisen für eine Option>

Eine Option kann auf verschiedene Weisen angegeben werden.

Als Programm-Optionen:

    --log-level=5    (ein Argument)
    --logLevel=5     (mixed case)

Als Methoden-Optionen:

    -log-level 5     (zwei Argumente)
    -logLevel 5      (mixed case)

Die Schreibweise mit zwei Bindestrichen wird typischerweise bei
Programmaufrufen angegeben. Die Option besteht aus I<einem> Argument,
bei dem der Wert durch ein Gleichheitszeichen vom Optionsnamen
getrennt angegeben ist.

Die Schreibweise mit einem Bindestrich wird typischerweise bei
Methodenaufrufen angegeben. In Perl ist bei einem Bindestrich
kein Quoting nötig. Die Option besteht aus I<zwei> Argumenten.

Beide Schreibweisen sind gleichberechtigt, so dass derselbe Code
sowohl Programm- als auch Methodenoptionen verarbeiten kann.

Ist C<< -properties=>1 >> gesetzt, ist die Argumentliste eine
Abfolge Schlüssel/Wert-Paaren ohne Bindestrich als
Options-Kennzeichen:

    a 1 b 2 c 3

=head4 Examples

=over 2

=item *

Instantiierung eines Options-Objekts:

    sub meth {
        my $self = shift;
        # @_: @args
    
        my $opt = Quiq::Option->extract(\@_,
            -logLevel => 1,
            -verbose => 0,
        );
        ...
    
        if ($opt->verbose) {
            ...
        }
    }

Das gelieferte Options-Objekt $opt ist eine Quiq::Hash-Instanz.
Die Schlüssel haben keine führenden Bindestriche. Eine Abfrage
des Optionswerts ist per Methode möglich:

    $verbose = $opt->verbose;

=item *

Setzen von Options-Variablen:

    sub meth {
        my $self = shift;
        # @_: @args
    
        my $logLevel = 1;
        my $verbose = 0;
    
        Quiq::Option->extract(\@_,
            -logLevel => \$logLevel,
            -verbose => \$verbose,
        );
        ...
    
        if ($verbose) {
            ...
        }
    }

=item *

Optionen bei Programmaufruf:

    $ prog --log-level=2 --verbose file.txt

=item *

Optionen bei Methodenaufruf:

    $prog->begin(-logLevel=>2,-verbose=>1,'file.txt');

=item *

Abfrage einer Option:

    $logLevel = $opt->logLevel;

=item *

Abfrage mehrerer Optionen:

    ($verbose,$logLevel) = $opt->get('verbose','logLevel');

=back

=cut

# -----------------------------------------------------------------------------

sub extract {
    my $class = shift;
    # @_: @opt,$argA,@optVal

    # Verarbeitungs-Optionen

    my $dontExtract = 0;
    my $mode = 'strict';
    my $properties = 0;
    my $simpleMessage = 0;

    while (!ref $_[0]) {
        my $key = shift;

        if ($key eq '-mode') {
            $mode = shift;
        }
        elsif ($key eq '-properties') {
            $properties = shift;
        }
        elsif ($key eq '-simpleMessage') {
            $simpleMessage = shift;
        }
        elsif ($key eq '-dontExtract') {
            $dontExtract = shift;
        }
        else {
            if ($simpleMessage) {
                die "Ungültige Methodenoption: $key\n";
            }
            $class->throw(
                'OPT-00002: Ungültige Methodenoption',
                Option => $key,
            );
        }
    }
    my $argA = shift;

    # Wir sind im VarMode, wenn die Methode im Void-Kontext gerufen wird.
    # Im VarMode enthält der Options-Hash Referenzen auf Programm-Variablen,
    # auf die wir die Optionswerte schreiben, nicht die Options-Defaultwerte.
    # Im VarMode können wir sofort zurückkehren, wenn die Argumentliste
    # leer ist.

    my $varMode = defined wantarray? 0: 1;
    if ($varMode && !@$argA) {
        return;
    }

    # Options-Hash initialisieren

    my %opt;
    while (@_) {
        my $key = shift;
        $key =~ s/^-+//; # Optionsnamen ohne führende Bindestriche
        $opt{$key} = shift;
    }

    # Argumente auswerten und auf Options-Hash schreiben

    my $i = 0;
    while ($i < @$argA) {
        my ($key,$dashPrefix,$val,$skip);

        $key = $argA->[$i];
        $dashPrefix = defined($key) && $key =~ s/^(-+)//? $1: '';

        if ($properties) {
            # Property-Liste: KEY,VAL

            $val = $argA->[$i+1];
            $skip = 2;
        }
        elsif ($dashPrefix eq '--') {
            # Programm-Option: --KEY=VAL

            if ($key eq '') {
                # Ende der Optionsliste, Option '--'
                splice @$argA,$i,1;
                last;
            }
            ($key,$val) = split /=/,$key,2;
            if (!defined $val) {
                $val = 1;
            }
            $skip = 1;
        }
        elsif ($dashPrefix eq '-' && $key ne '') { # '-' ist normaler Wert
            # Methoden-Option: -KEY,VAL

            if ($key eq 'h' && exists $opt{'help'}) {
                $key = 'help';
                $val = 1;
                $skip = 1;
            }
            else {
                $val = $argA->[$i+1];
                $skip = 2;
            }
        }
        else {
            # Keine Option, weitergehen
            $i++;
            next;
        }

        if (!$properties) {
            # eingebettete Bindestriche in CamelCase-Schreibweise wandeln
            $key =~ s/(.)-(.)/$1\U$2/g;
        }

        # warn "KEY=$key VAL=$val\n";

        # Existenz des Key prüfen

        if (!exists $opt{$key}) {
            if ($mode eq 'sloppy') {
                $i += $skip;
                next;
            }
            if ($simpleMessage) {
                die "Ungültige Option: $dashPrefix$key\n";
            }
            $class->throw(
                'OPT-00001: Ungültige Option',
                Option => "$dashPrefix$key",
            );
        };

        # Optionswert setzen

        if (defined $val) { # Defaultwert bleibt. NEU! 27.7.2014
            if ($varMode) {
                ${$opt{$key}} = $val;
            }
            else {
                $opt{$key} = $val;
            }
        }

        if ($dontExtract) {
            # Optionen bleiben in Argumentliste, Index weiterschalten
            $i += $skip;
        }
        else {
            # Option und Wert aus Argumentliste entfernen
            splice @$argA,$i,$skip;
        }
    }

    if ($varMode) {
        return;
    }
    else {
        return Quiq::Hash->new(\%opt);
    }
}

# -----------------------------------------------------------------------------

=head3 extractAll() - Extrahiere alle Optionen als Liste

=head4 Synopsis

    @opts|$optA = $class->extractAll(\@arr);

=head4 Description

Extrahiere alle Option/Wert-Paare aus @arr und liefere diese als Liste
zurück. Im Skalarkontext liefere eine Referenz auf die Liste.

=cut

# -----------------------------------------------------------------------------

sub extractAll {
    my ($this,$argA) = @_;

    my @arr;
    for (my $i = 0; $i < @$argA; $i++) {
        if (substr($argA->[$i],0,1) eq '-') {
            push @arr,splice(@$argA,$i--,2);
        }
    }

    return wantarray? @arr: \@arr;
}

# -----------------------------------------------------------------------------

=head3 extractMulti() - Extrahiere Mehrwert-Optionen

=head4 Synopsis

    $class->extractMulti(@opt,\@arr,$key=>$ref,...);

=head4 Options

=over 4

=item -sloppy => $bool (Default: 0)

Übergehe unbekannte Optionen.

=back

=head4 Description

Extrahiere aus Array @arr die Werte zu den angegebenen Schlüsseln
$key und weise diese an die Variablen-Referenzen $ref zu.
Die Methode liefert keinen Wert zurück.

Eine Referenz kann eine Skalar- oder eine Arrayreferenz sein.
Im Fall einer Skalarreferenz wird der Wert zugewiesen.
Im Falle einer Array-Referenz werden mehrere aufeinanderfolgende
Werte in dem Array gesammelt.

Für das Hinzufügen einer Default-Option, siehe Beispiel.

=head4 Example

    # Optionen
    
    my @select;
    my @from;
    my @where;
    my $limit;
    
    unshift @_,'-select'; # Default-Option
    
    Quiq::Option->extractMulti(\@_,
        -select => \@select,
        -from => \@from,
        -where => \@where,
        -limit => \$limit,
    );
    
    unless (@from) {
        die "FROM-Klausel fehlt\n";
    }
    unless (@select) {
        @select = ('*');
    }

=cut

# -----------------------------------------------------------------------------

sub extractMulti {
    my $this = shift;
    # @_: @opt,\@arr,@keyRef

    # Optionen

    my $sloppy = 0;

    while (!ref $_[0]) {
        my $key = shift;
        if ($key eq '-sloppy') {
            $sloppy = shift;
        }
        else {
            $this->throw(
                'OPT-00004: Ungültige Option',
                Option => $key,
            );
        }
    }

    my $arr = shift;
    my %keyVar = @_;

    my ($ref,$refType);
    for (my $i = 0; $i < @$arr; $i++) {
        my $arg = $arr->[$i];

        if (defined($arg) && exists $keyVar{$arg}) {
            # Argument ist Option

            $ref = $keyVar{$arg};
            $refType = Scalar::Util::reftype($ref);
            if (!defined $refType) {
                $this->throw(
                    'OPT-00002: Ungültige Variablen-Referenz',
                    Option => $arg,
                );
            }
            splice @$arr,$i--,1;
            next;
        }
        # Zahlen beginnen können mit '-' beginnen
        elsif (defined($arg) && $arg =~ /^-\D/) {
            # Unbekannte Option

            if (!$sloppy) {
                $this->throw(
                    'OPT-00001: Ungültige Option',
                    Option => $arg);
            }
            $ref = undef;
            next;
        }
        elsif ($ref) {
            # Argument ist Wert zu Option

            if ($refType eq 'ARRAY') {
                push @$ref,$arg;
            }
            elsif ($refType eq 'SCALAR') {
                $$ref = $arg;
                $ref = undef;
            }
            splice @$arr,$i--,1;
            next;
        }
        else {
            # Unbekanntes Argument -> übergehen
            next;
        }
    }

    return;
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.148

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
