package Quiq::Parallel;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.147';

use Quiq::Path;
use Quiq::Parameters;
use Quiq::System;
use Quiq::TempDir;
use Quiq::Progress;
use Quiq::Hash;
use Quiq::FileHandle;
use Scalar::Util ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Parallel - Parallele Verarbeitung

=head1 BASE CLASS

L<Quiq::Object>

=head1 EXAMPLE

Minimales Veranschaulichungsbeispiel: Lasse 50 Prozesse für
jeweils eine Sekunde schlafen. Die Ausführungsdauer beträgt
ungefähr 50/I<Anzahl CPUs> Sekunden, da immer I<Anzahl CPUs>
Prozesse parallel ausgeführt werden.

    Quiq::Parallel->runArray([1..50],sub {
        my ($elem,$i) = @_;
        sleep 1;
        return;
    });

Bei großen Datenmengen oder wenn die Gesamtmenge vorab nicht bekannt
ist, bietet sich die Methode $class->L<runFetch|"runFetch() - Führe Subroutine parallel über gefetchten Elementen aus">() an. Hier ein
Beispiel mit einer unbekannt großen Datenbank-Selektion:

    my $cur = $db->select("
            <SELECT Statement>
        ",
        -cursor => 1,
    );
    
    Quiq::Parallel->runFetch(sub {
            my $i = shift;
            return $cur->fetch;
        },
        sub {
            my ($row,$i) = @_;
    
            <$row verarbeiten>
    
            return;
        },
    );

=head1 METHODS

=head2 Parallele Berechnung

=head3 runArray() - Führe Subroutine parallel über Arrayelementen aus

=head4 Synopsis

    $class->runArray(\@elements,$sub,@opt);

=head4 Arguments

=over 4

=item @elements

Die Elemente, auf denen die Berechnung einzeln durchgeführt wird.

=item $sub

Die Subroutine, die für jedes Element in @elements ausgeführt wird.

=back

=head4 Options

Die gleichen wie L<runFetch|"runFetch() - Führe Subroutine parallel über gefetchten Elementen aus">().

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub runArray {
    my ($class,$elementA,$sub) = splice @_,0,3;
    # @_: @opt

    $class->runFetch(sub {
            my $i = shift;
            return $elementA->[$i-1];
        },
        $sub,
        -maxFetches => scalar @$elementA,
        @_,
    );
    
    return;    
}

# -----------------------------------------------------------------------------

=head3 runFetch() - Führe Subroutine parallel über gefetchten Elementen aus

=head4 Synopsis

    $class->runFetch($fetchSub,$execSub,@opt);

=head4 Arguments

=over 4

=item $fetchSub

Subroutine, die das nächste gefetchte Element liefert:

    $e = $fetchSub->($i); # $i-ter Fetch-Aufruf

=item $execSub

Subroutine, die für jedes gefetchte Element ausgeführt wird.

=back

=head4 Options

=over 4

=item -maxFetches => $n (Default: 0)

Gesamtanzahl der Fetches. 0 bedeutet, die Gesamtanzahl der Fetches
ist (vorab) nicht bekannt.

=item -maxProcesses => $n (Default: Anzahl der CPUs des Rechners)

Die maximale Anzahl parallel laufender Prozesse.

=item -outputDir => $dir (Default: undef)

Verzeichnis, in das die Ausgaben der Prozesse auf STDOUT und STDERR
geschrieben werden, jeweils in eine eigene Datei mit dem Namen

    NNNNNN.out

Die sechstellige Zahl NNNNNNN ist die Nummer des Prozesses in der
Aufrufreihenfolge.

=item -outputFile => $file (Default: undef)

Datei, in der die Ausgaben aller Prozesse (chronologische
Aufrufreihenfolge) zusammengefasst werden. Dies geschieht nach
Beendigung des letzten Prozesses. Wird '-' als Dateiname angegeben,
wird die Ausgabe nach STDOUT geschrieben.

=item -progressMeter => $bool (Default: 1)

Zeige Fortschrittsanzeige an.

=back

=head4 Returns

nichts

=head4 Description

Verarbeite die Elemente, die von Subroutine $fetchSub geliefert
werden, mit der Subroutine $execSub mit parallel laufenden
Prozessen. Per Default wird für die Anzahl der parallelen Prozesse
die Anzahl der CPUs des ausführenden Rechners gewählt. Mit
der Option -maxProcesses kann eine abweichende Anzahl gewählt
werden.

Tipp: Die Anzahl der vorhandenen CPUs liefert die Methode

    $n = Quiq::System->numberOfCpus;

Die Ausgaben der Prozesse auf STDOUT und STDERR werden in Dateien
gespeichert, wenn Option -outputDir und/oder -outputFile angegeben sind.

=cut

# -----------------------------------------------------------------------------

sub runFetch {
    my $class = shift;
    # @_: Parameters

    # Pfadobjekt
    my $p = Quiq::Path->new;

    # Optionen

    my $maxFetches = 0;
    my $maxProcesses = 0;
    my $outputDir = undef;
    my $outputFile = undef;
    my $progressMeter = 1;
    
    my $argA = Quiq::Parameters->extractToVariables(\@_,2,2,
        -maxFetches => \$maxFetches,
        -maxProcesses => \$maxProcesses,
        -outputDir => \$outputDir,
        -outputFile => \$outputFile,
        -progressMeter => \$progressMeter,
    );
    my ($fetchSub,$sub) = @$argA;

    if (!$maxProcesses) {
        $maxProcesses = Quiq::System->numberOfCpus;
    }

    my $dir;
    if ($outputDir || $outputFile) {
        # Die Prozesse schreiben ihre Ausgabe auf stdout
        # und stderr nach $dir

        if ($outputDir) {
            $p->mkdir($outputDir,-recursive=>1);
        }
        $dir = $outputDir || Quiq::TempDir->new;
    }

    # Aktionen nach Beendigung eines Child-Prozesses

    my $wait = sub {
        my ($pro,$processH,$i) = @_;

        my $pid = wait;
        if ($pid >= 0) {
            my $elem = $processH->{$pid};

            my $type = Scalar::Util::reftype($elem) || '';
            if ($type eq 'HASH') {
                print $pro->msg($i,'i/n x% t/t(t) x/h x/s');
            }
            elsif ($type eq 'ARRAY') {
                print $pro->msg($i,'i/n x% t/t(t) x/h x/s: %s',$elem->[0]);
            }
            else {
                print $pro->msg($i,'i/n x% t/t(t) x/h x/s: %s',$elem);
            }

            delete $processH->{$pid};
        }

        return $pid;
    };

    # Ausführung

    my $pro = Quiq::Progress->new($maxFetches,-show=>$progressMeter);
    if ($maxFetches) {
        my $msg = 'Waiting for first process to finish';
        if ($dir) {
            $msg .= " (see $dir for output files)";
        }
        $msg .= '...';
        print $pro->msg($msg);
    }

    my $i = 0; # Anzahl der gestarteten Prozesse
    my $j = 0; # Anzahl der beendeten Prozesse
    my $processH = Quiq::Hash->new;
    my $runningProcesses = 0;
    while (1) {
        $i++;
        if ($maxFetches && $i > $maxFetches) {
            last;
        }
        my $elem = $fetchSub->($i);
        if (!defined $elem) {
            last;
        }

        if ($runningProcesses >= $maxProcesses) {
            $wait->($pro,$processH,++$j);
            $runningProcesses--;
        }

        if (my $pid = fork) {
            # Parent

            $processH->add($pid=>$elem);
            $runningProcesses++;
        }
        else {
            # Child

            if ($dir) {
                # Lenke stdout und stderr in Ausgabedateien in Verzeichnis
                # $dir um. Die Umlenkung gilt auch für Child-Prozesse.

                my $file = $p->expandTilde(sprintf '%s/%06d.out',$dir,$i);

                CORE::close STDOUT;
                CORE::open STDOUT,'>',$file or $class->throw;
                CORE::open STDERR,'>&',\*STDOUT or $class->throw;
            }

            $sub->($elem,$i);
            exit;
        }
    }

    # Warte auf die letzten Childs

    while ($wait->($pro,$processH,++$j) >= 0) {
    }

    print $pro->msg;

    if ($outputFile) {
        # Die Ausgaben aller Prozesse in Zieldatei schreiben

        my $fh = Quiq::FileHandle->new('>',$outputFile);
        for my $file ($p->glob("$dir/*.out")) {
            $fh->print($p->read($file));
        }
        $fh->close;
    }
    
    return;    
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.147

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
