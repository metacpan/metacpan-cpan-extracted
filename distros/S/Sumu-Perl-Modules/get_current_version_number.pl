#!/usr/bin/perl

use strict;
use warnings;

my $current_commit_id = `./get_current_commit_id.pl`;
chomp $current_commit_id;

#
print convert_2_version();

=head1 NAME
    Convert NNN to N.N.N
=head2 DESC
=cut

sub convert_2_version {
    my @val = split(//, $current_commit_id);
    my $out;
    for (@val) {
        $out .= qq{$_.};
    }
    #
    $out =~ s!\.$!!;
    #
    return $out;
}

1;

