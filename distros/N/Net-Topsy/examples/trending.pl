#!/usr/bin/env perl
use strict;
use warnings;
use Net::Topsy;

=head1 SYNOPSIS

perl -Ilib examples/trending.pl

Returns the top 25 trending terms, with links.

=cut

my $topsy  = Net::Topsy->new;
my $search = $topsy->trending( { perpage => 25 });
my $iter   = $search->iter;
while ($iter->has_next) {
    my $item = $iter->next;
    printf "%-20s %s\n", $item->{term}, $item->{url};
}
