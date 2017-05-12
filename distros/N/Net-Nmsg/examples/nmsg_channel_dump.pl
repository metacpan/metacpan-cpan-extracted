#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::IO;

sub print_nmsg { print shift->as_str, "\n\n" };

my $ch = shift || die "channel required";
my $io = Net::Nmsg::IO->new;
$io->add_input_channel($ch);
$io->add_output_cb(\&print_nmsg);
$io->loop;
