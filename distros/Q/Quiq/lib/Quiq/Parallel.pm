package Quiq::Parallel;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = 1.132;

use Quiq::Option;
use Quiq::System;
use Quiq::Progress;
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
ist, bietet sich die Methode $class->L</runFetch>() an. Hier ein
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

=over 4

=item -maxProcesses => $n (Default: Anzahl der CPUs des Rechners)

Die maximale Anzahl parallel laufender Prozesse.

=item -progressMeter => $bool (Default: 0)

Zeige Fortschrittsanzeige an.

=back

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

=item -progressMeter => $bool (Default: 0)

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

Tip: Die Anzahl der vorhandenen CPUs liefert die Methode

    $n = Quiq::System->numberOfCpus;

=cut

# -----------------------------------------------------------------------------

sub runFetch {
    my ($class,$fetchSub,$sub) = splice @_,0,3;
    # @_: @opt

    # Optionen

    my $maxFetches = 0;
    my $maxProcesses = 0;
    my $progressMeter = 0;
    
    Quiq::Option->extract(\@_,
        -maxFetches => \$maxFetches,
        -maxProcesses => \$maxProcesses,
        -progressMeter => \$progressMeter,
    );
    if (!$maxProcesses) {
        $maxProcesses = Quiq::System->numberOfCpus;
    }

    # Ausführung

    my $pro = Quiq::Progress->new($maxFetches);

    my $i = 0;
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
            wait;
            $runningProcesses--;
        }

        if (!fork) {
            # Child
            $sub->($elem,$i);
            exit;
        }

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
        $runningProcesses++;
    }

    while (wait >= 0) {
    }

    print $pro->msg;
    
    return;    
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.132

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
