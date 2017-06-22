package Prty::Parallel;
use base qw/Prty::Object/;

use strict;
use warnings;

our $VERSION = 1.108;

use Prty::Option;
use Prty::System;
use Prty::Progress;
use Scalar::Util ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Parallel - Führe eine Berechnung parallel aus

=head1 BASE CLASS

L<Prty::Object>

=head1 EXAMPLE

Lasse 50 Prozesse für jeweils eine Sekunde schlafen. Die
Ausführungsdauer beträgt ungefähr 50/ANZAHL_CPUS Sekunden, da
immer ANZAHL_CPUS Prozesse parallel ausgefhrt werden.

    $| = 1;
    Prty::Parallel->compute([1..50],sub {
        my ($elem,$i) = @_;
        sleep 1;
        return;
    });

=head1 METHODS

=head2 Parallele Berechnung

=head3 compute() - Führe Subroutine parallel aus

=head4 Synopsis

    $class->compute(\@elements,$sub,@opt);

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

=item -progressMeter => $bool (Default: 1)

Zeige Fortschrittsanzeige an.

=back

=head4 Returns

nichts

=cut

# -----------------------------------------------------------------------------

sub compute {
    my ($class,$elementA,$sub) = splice @_,0,3;
    # @_: @opt

    # Optionen

    my $maxProcesses = 0;
    my $progressMeter = 1;
    
    Prty::Option->extract(\@_,
        -maxProcesses => \$maxProcesses,
        -progressMeter => \$progressMeter,
    );

    if (!$maxProcesses) {
        $maxProcesses = Prty::System->numberOfCpus;
    }

    # Ausführung

    my $pro = Prty::Progress->new(scalar @$elementA);

    my $i = 0;
    my $runningProcesses = 0;
    for my $elem (@$elementA) {
        $i++;

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
            print $pro->msg($i,'i/n x% t/t(t) x/s');
        }
        elsif ($type eq 'ARRAY') {
            print $pro->msg($i,'i/n x% t/t(t) x/s: %s',$elem->[0]);
        }
        else {
            print $pro->msg($i,'i/n x% t/t(t) x/s: %s',$elem);
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

1.108

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
