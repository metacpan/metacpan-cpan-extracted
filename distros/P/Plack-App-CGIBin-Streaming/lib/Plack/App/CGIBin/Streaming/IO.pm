package Plack::App::CGIBin::Streaming::IO;

use 5.014;
use strict;
use warnings;
use Plack::App::CGIBin::Streaming;

sub PUSHED {
    #my ($class, $mode, $fh) = @_;

    return bless +{read_mode => (substr($_[1], 0, 1) eq 'r')}, $_[0];
}

sub WRITE {
    #my ($self, $buf, $fh) = @_;

    $Plack::App::CGIBin::Streaming::R->print_content($_[1]);
    return length $_[1];
}

sub FLUSH {
    #my ($self, $fh) = @_;

    return 0 if $_[0]->{in_flush} or $_[0]->{read_mode};
    local $_[0]->{in_flush}=1;

    $Plack::App::CGIBin::Streaming::R->flush
        unless $Plack::App::CGIBin::Streaming::R->suppress_flush;

    return 0;
}

sub READ {
    #my ($self, $buf, $len, $fh) = @_;

    return $_[3]->read($_[1], $_[2]);
}

sub SEEK {
    #my ($self, $pos, $whence, $fh) = @_;

    return -1
        unless ($_[0]->{read_mode} and
                $Plack::App::CGIBin::Streaming::R->env->{'psgix.input.buffered'});

    return $_[3]->seek($_[1], $_[2]) ? 0 : -1;
}

sub BINMODE {
    #my ($self, $fh) = @_;

    # pop the layer when we are done
    return if $Plack::App::CGIBin::Streaming::R->binmode_ok;

    # otherwise keep it
    return 0;
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::App::CGIBin::Streaming::IO - a helper PerlIO layer for
Plack::App::CGIBin::Streaming

=head1 SYNOPSIS

 binmode HANDLE, 'via(Plack::App::CGIBin::Streaming::IO)';

=head1 DESCRIPTION

This module provides a L<PerlIO::via> layer to capture all the output
written to C<HANDLE>. It uses the global variable
C<$Plack::App::CGIBin::Streaming::R> and passes the output via the
C<print_content> method.

A flush operation is passed by calling the C<flush> method.

Attempts to read from a file handle configured with this layer result in an
exception.

=head1 AUTHOR

Torsten Förtsch E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT

Copyright 2014 Binary.com

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). A copy of the full
license is provided by the F<LICENSE> file in this distribution and can
be obtained at

L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 SEE ALSO

=over 4

=item * L<Plack::App::CGIBin::Streaming>

=back

=cut
