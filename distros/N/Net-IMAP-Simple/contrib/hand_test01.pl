#!/usr/bin/perl

use strict;
use warnings;
use lib 'inc', "blib/lib", "blib/arch";
use rebuild_iff_necessary;
use slurp_fetchmail;
use Data::Dump qw(dump);

my $imap = slurp_fetchmail->login(use_ssl=>1);

my @c;
for my $box (map {split m/\s+/} (@ARGV ? @ARGV : ("INBOX"))) {
    push @c, {
        selectres => dump($imap->select($box)), 
        box => $imap->current_box, first_unseen=>$imap->unseen, recent=>$imap->recent,
    };
}

warn dump(@c) . "\n";
