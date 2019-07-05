package Quiq::Ipc;
use base qw/Quiq::Object/;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '1.149';

use Quiq::Option;
use Quiq::Shell;
use IPC::Open3 ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::Ipc - Interprozesskommunikation

=head1 BASE CLASS

L<Quiq::Object>

=head1 METHODS

=head2 Methods

=head3 filter() - Rufe ein Kommando als Filter auf

=head4 Synopsis

    $out = Quiq::Ipc->filter($cmd,$in,@opt);
    ($out,$err) = Quiq::Ipc->filter($cmd,$in,@opt);
    $out = Quiq::Ipc->filter($cmd,@opt);
    ($out,$err) = Quiq::Ipc->filter($cmd,@opt);

=head4 Options

=over 4

=item -ignoreError => $bool (Default: 0)

Ignoriere Exitcode von Kommando $cmd. D.h. es wird keine Exception
geworfen, wenn das Kommando fehlschlägt.

=back

=head4 Description

Rufe Kommando $cmd als Filter auf. Das Kommando erhält die Daten
$in auf stdin und liefert die Daten $out und $err auf stdout
bzw. stderr. In Skalarkontext wird nur die Ausgabe auf stdout
geliefert.

Achtung: Der Aufruf kann zu einem SIGPIPE führen, wenn per
Parameter $in Daten an $cmd gesendet werden und das Kommando
terminiert, bevor es alle Daten gelesen hat. Insbesondere sollten
keine Daten an ein Kommando gesendet werden, das nicht von stdin
liest!

=cut

# -----------------------------------------------------------------------------

sub filter {
    my $class = shift;
    my $cmd = shift;
    # @_: $in,@opt -or- @opt
    
    my $ignoreError = 0;

    Quiq::Option->extract(\@_,
        -ignoreError => \$ignoreError,
    );
    my $in = shift;

    local (*W,*R,*E,$/);
    my $pid = IPC::Open3::open3(\*W,\*R,\*E,$cmd);
    unless ($pid) {
        $class->throw(
            'IPC-00001: Kann Filterkommando nicht forken',
            Cmd => $cmd,
        );
    }

    if (defined $in) {
        print W $in;
    }
    close W;

    my $out = <R>;
    close R;

    my $err = <E>;
    close E;

    waitpid $pid,0;
    if (!$ignoreError) {
        # FIXME: checkError nach Quiq::Ipc verlagern,
        # in checkExit umbenennen
        Quiq::Shell->checkError($?,$err,$cmd);
    }

    return wantarray? ($out,$err): $out;
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
