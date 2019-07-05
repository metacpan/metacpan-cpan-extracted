package Quiq::ExampleCode;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Quiq::Option;
use Quiq::String;
use Quiq::Hash;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::ExampleCode - Führe Beispielcode aus

=head1 BASE CLASS

L<Quiq::Hash>

=head1 SYNOPSIS

(1) Code $code ausführen und den Code selbst und sein Resultat nach
STDOUT schreiben. Das Resultat (Skalar- oder List-Kontext) wird
direkt zurückgeliefert.

    my $exa = Quiq::ExampleCode->new;
    $res|@res = $exa->execute($code,-variables=>\@keyval);
    ...

(2) Code $code ausführen und den Code selbst und sein Resultat in
Form eines Objektes zurückliefern. Die Ausgabe auf STDOUT
unterbleibt.

    my $exa = Quiq::ExampleCode->new(
        -objectReturn => 1,
        -verbose => 0,
    );

Ausführung im Skalar-Kontext:

    $obj = $exa->execute($code,-variables=>\@keyval);
    my $code = $obj->code;
    my $res = $obj->result;
    ...

Im List-Kontext:

    $obj = $exa->execute($code,-variables=>\@keyval,-listContext=>1);
    my $code = $obj->code;
    my $resA = $obj->result;
    ...

=head1 DESCRIPTION

Die Klasse dient zum Ausführen von Beispielcode in Perl. Beispielcode
ist dadurch gekennzeichnet, dass der Code und sein Resultat gegenüber
gestellt werden.

=head1 EXAMPLES

=head2 Setzen von Variablen

Variable vorab setzen:

    $exa->setVariable(
        ffm => $ffm,
    );
    my $cmd = $exa->execute(q|
        $ffm->videoToImages('video.mp4','img',
            -aspectRatio => '4:3',
            -framestep => 6,
            -start => 3,
            -stop => 10,
        );
    |);

Variable per Option -variables bei Aufruf setzen:

    my $cmd = $exa->execute(q|
        $ffm->videoToImages('video.mp4','img',
            -aspectRatio => '4:3',
            -framestep => 6,
            -start => 3,
            -stop => 10,
        );|,
        -variables => [
            ffm => $ffm,
        ],
    );

oder (in anderer Reihenfolge):

    my $cmd = $exa->execute(
        -variables => [
            ffm => $ffm,
        ],q|
            $ffm->videoToImages('video.mp4','img',
                -aspectRatio => '4:3',
                -framestep => 6,
                -start => 3,
                -stop => 10,
            );
        |,
    );

=head1 METHODS

=head2 Konstruktor

=head3 new() - Erzeuge Instanz

=head4 Synopsis

    $exa = $class->new(@opt);

=head4 Options

=over 4

=item -fileHandle => $fh (Default: \*STDOUT)

FileHandle, über die Informationen über die ausgeführten Beispiele
ausgegeben wird.

=item -objectReturn => $bool (Default: 0)

Liefere bei Aufruf von $exa->L<execute|"execute() - Führe Beispielcode aus">() nicht den Wert des
Beispielcode, sondern ein Objekt, das den Beispielcode und
den Wert enthält.

=item -verbose => $bool (Default: 1)

Gib Informationen über die ausgeführten Beispiele auf
der FileHandle -fileHandle aus.

=back

=head4 Description

Instantiiere ein Example-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: $dir,@opt

    # Optionen

    my $fileHandle = \*STDOUT;
    my $objectReturn = 0;
    my $verbose = 1;

    Quiq::Option->extract(-mode=>'sloppy',\@_,
        -fileHandle => \$fileHandle,
        -objectReturn => \$objectReturn,
        -verbose => \$verbose,
    );

    # Instantiiere Objekt

    return $class->SUPER::new(
        fileHandle => $fileHandle,
        objectReturn => $objectReturn,
        verbose => $verbose,
    );
}
    

# -----------------------------------------------------------------------------

=head2 Variablen setzen

=head3 setVariable() - Setze Variable für Beispielcode-Ausführung

=head4 Synopsis

    $exa->setVariable(@keyVal);

=head4 Description

Setze Variable, so dass die folgende Kommando-Ausführung (Methode
L<execute|"execute() - Führe Beispielcode aus">()) im Kontext der Klasse Quiq::ExampleCode ausgeführt werden
kann. Die Methode liefert keinen Wert zurück.

Anstelle mittels dieser Methode, können die Variablen auch beim Aufruf
selbst mit der Option -variables angegeben werden.

=head4 Example

    $exa->setVariable(
        obj => $obj,
        x => $x,
        y => $y,
    );

=cut

# -----------------------------------------------------------------------------

sub setVariable {
    my $self = shift;
    # @_: @keyVal

    no strict 'refs';
    while (@_) {
        my $key = shift;
        $$key = shift; # Erzeuge Package-Variable
    }

    return;
}

# -----------------------------------------------------------------------------

=head2 Beispielcode ausführen

=head3 execute() - Führe Beispielcode aus

=head4 Synopsis

    $res|@res = $exa->execute($code,@opt);

=head4 Options

=over 4

=item -asStringCallback => $subRef (Default: undef)

Subroutine-Referenz, die das Resultat des Beispiel-Code in
eine Stringrepräsentation wandelt, die auf dem Bildschirm ausgegeben
werden kann.

=item -listContext => $bool (Default: Wert von wantarray)

Führe den Beispiel-Code im List-Kontext aus. Eine explizite
Setzung ist nur im Falle von -objectReturn=>1 nötig

=item -objectReturn => $bool (Default: 0)

Liefere bei Aufruf von $exa->L<execute|"execute() - Führe Beispielcode aus">() nicht den Wert des
Beispielcode, sondern ein Objekt, das den Beispielcode und
den Wert enthält.

=item -variables => \@keyVal (Default: [])

Setze die angegebenen Variablen im Ausführungskontext des
Beispiel-Code.

=item -verbose => $bool (Default: Konstruktor-Setzung)

Gib Informationen über die ausgeführten Beispiele auf
der FileHandle -fileHandle aus.

=back

=head4 Description

Führe Beispielcode $code aus und liefere das Resultat der Ausführung
$res (Skalar-Kontext) oder @res (Listen-Kontext) zurück.

Ist beim Konstruktor die Option -verbose gesetzt worde, wird
zusätzlich der Beispielcode und das Resultat ausgegeben.

=head4 Example

Der Aufruf

    $cmd = $exa->execute(q|
        $ffm->videoToImages('video.mp4','img',
            -aspectRatio => '4:3',
            -framestep => 6,
            -start => 3,
            -stop => 10,
        );
    |);

führt zu der Ausgabe

    $ffm->videoToImages('video.mp4','img',
        -aspectRatio => '4:3',
        -framestep => 6,
        -start => 3,
        -stop => 10,
    );
    =>
    ffmpeg -y -loglevel error -stats -i 'video.mp4'
        -vf 'framestep=6,crop=ih/3*4:ih'
        -ss 3 -t 7 -qscale:v 2 'img/%06d.jpg'

Der Text nach '=>' ist der gelieferte Wert $cmd.

=cut

# -----------------------------------------------------------------------------

sub execute {
    my $self = shift;
    # @_: @opt

    # Optionen

    my $asStringCallback = undef;
    my $listContext = undef;
    my $objectReturn = $self->objectReturn;
    my $variableA = undef;
    my $verbose = $self->verbose;
    
    Quiq::Option->extract(\@_,
        -asStringCallback => \$asStringCallback,
        -listContext => \$listContext,
        -objectReturn => \$objectReturn,
        -variables => \$variableA,
        -verbose => \$verbose,
    );
    $listContext //= wantarray;
    
    if (@_ != 1) {
        $self->throw('Falsche Anzahl Argumente');
    }
    my $code = shift;

    # Operation ausführen
    
    my $fh = $self->get('fileHandle');

    if ($variableA) {
        $self->setVariable(@$variableA);
    }
    
    $code = Quiq::String->removeIndentation($code);
    if ($verbose) {
        print $fh "\n$code\n=>\n";
    }

    my (@res,$res);
    if ($listContext) {
        no strict 'vars';
        @res = eval $code;
    }
    else {
        no strict 'vars';
        $res = eval $code;
    }
    if ($@) {
        die;
    }
    if ($verbose) {
        my $outp;
        if (my $sub = $asStringCallback) {
            $outp = $asStringCallback->($listContext? \@res: $res);
        }
        else {
            $outp = wantarray? "@res": $res;
        }
        print $fh "$outp\n";
    }

    if ($objectReturn) {
        return Quiq::Hash->new(
            code => $code,
            result => $listContext? \@res: $res,
        );
    }
    
    return wantarray? @res: $res;
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
