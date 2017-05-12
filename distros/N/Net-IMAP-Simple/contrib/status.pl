#!/usr/bin/perl

use strict;
use warnings;
use lib 'inc', "blib/lib", "blib/arch";
use rebuild_iff_necessary;
use slurp_fetchmail;
use Data::Dump qw(dump);

my $imap = slurp_fetchmail->login(use_ssl=>1);

warn dump( $imap->status(shift) );
