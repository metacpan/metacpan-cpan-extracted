#!/usr/bin/perl

use strict;
use warnings;

use Net::Nmsg::IO;

sub print_nmsg { print shift->as_str, "\n\n" };

my $file = shift || die "file required";
my $io = Net::Nmsg::IO->new;
$io->add_input($file);
$io->add_output_cb(\&print_nmsg);
$io->loop;
