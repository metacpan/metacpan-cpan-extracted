#!/usr/bin/perl

use Test::More 0.88;

use strict;
use warnings;
no  warnings 'syntax';

unless ($ENV {AUTHOR_TESTING}) {
    plan skip_all => "AUTHOR tests";
    exit;
}

sub version;

SKIP: {
    open my $fh, "<", "MANIFEST" or do {
        skip "Failed to open MANIFEST", 1;
    };
    while (<$fh>) {
        chomp;
        unless (-e) {
            fail "$_ does not exist";
            next;
        }
      SKIP: {
            my $mode = (stat) [2];
            skip "Failed to grab permissions of $_", 1 unless $mode;
            my $perm = $mode & 07777;

            is $perm, /\.t/ ? 0755 : 0644, "Permissions of $_"
        }
    }
}

done_testing;

__END__
