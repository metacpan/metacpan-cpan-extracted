#!/usr/local/bin/perl

use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new
(
    module_name   => 'Net::BitTorrent::PeerPacket',
    dist_abstract => 'Peer packet parse and create implementation',
    license       => 'perl',
    dist_author   => 'josh mcadams',
    requires      => {Carp => 0},
);

$build->create_build_script;

