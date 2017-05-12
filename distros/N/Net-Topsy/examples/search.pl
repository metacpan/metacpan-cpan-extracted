#!/usr/bin/env perl
use strict;
use warnings;
use Net::Topsy;
my $search_term = shift || 'perl';

=head1 SYNOPSIS

TOPSY_API_KEY=somekey perl -Ilib examples/search.pl search_term

Shows the top 30 matches for today. After installing Net::Topsy, you
will not need the -Ilib flag.

=cut

my $topsy  = Net::Topsy->new;
my $result = $topsy->search({
                               q => $search_term,
                               page   =>  1,  # default
                               perpage => 30, # 30 per page
                               window => 'd', # today
                            });
my $iter = $result->iter;
while ($iter->has_next) {
    my $item = $iter->next;
    printf "%-60s : %d : %s\n", $item->{title} ,$item->{hits}, $item->{url};
}
