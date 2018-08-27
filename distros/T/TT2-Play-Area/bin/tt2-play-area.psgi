#!/usr/bin/perl

# PODNAME: tt2-play-area.psgi

use strict;
use warnings;

use Plack::Builder;
use TT2::Play::Area;

my $secret_key = $ENV{TT2_PLAYAREA_SECRET};
unless ($secret_key) {
    open my $rand, '<', '/dev/urandom' or die 'Failed to open /dev/urandom';
    my $bytes = '0' x 32;
    die "Failed to read sufficient from random - $!"
      unless sysread( $rand, $bytes, 32 ) == 32;
    close $rand;
    $secret_key = unpack 'H*', $bytes;
}

builder {
    enable 'Session::Cookie',
      session_key => 'tt2-play-area',
      expires     => 12 * 3600,         # 12 hour
      secret      => $secret_key;
    enable 'CSRFBlock';

    TT2::Play::Area->to_app;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

tt2-play-area.psgi

=head1 VERSION

version 0.002

=head1 AUTHOR

Colin Newell <colin.newell@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Colin Newell.

This is free software, licensed under:

  The MIT (X11) License

=cut
