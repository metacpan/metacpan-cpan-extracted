package Prty::Ipc;
use base qw/Prty::Object/;

use strict;
use warnings;

our $VERSION = 1.123;

use Prty::Option;
use Prty::Shell;
use IPC::Open3 ();

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Prty::Ipc - Interprozesskommunikation

=head1 BASE CLASS

L<Prty::Object>

=head1 METHODS

=head2 Methods

=head3 filter() - Rufe ein Kommando als Filter auf

=head4 Synopsis

    ($out,$err) = Prty::Ipc->filter($cmd,$in,@opt);
    ($out,$err) = Prty::Ipc->filter($cmd,@opt);

=head4 Options

=over 4

=item -ignoreError => $bool (Default: 0)

Ignoriere Exitcode von Kommando $cmd. D.h. es wird keine Exception
geworfen, wenn das Kommando fehlschlägt.

=back

=head4 Description

Rufe Kommando $cmd als Filter auf. Das Kommando erhält die Daten
$in auf stdin und liefert die Daten $out und $err auf stdout
bzw. stderr.

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

    Prty::Option->extract(\@_,
        -ignoreError=>\$ignoreError,
    );
    my $in = shift;

    local (*W,*R,*E,$/);
    my $pid = IPC::Open3::open3(\*W,\*R,\*E,$cmd);
    unless ($pid) {
        $class->throw(
            q~IPC-00001: Kann Filterkommando nicht forken~,
            Cmd=>$cmd,
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
        # FIXME: checkError nach Prty::Ipc verlagern,
        # in checkExit umbenennen
        Prty::Shell->checkError($?,$err,$cmd);
    }

    return ($out,$err);
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.123

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2018 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof
