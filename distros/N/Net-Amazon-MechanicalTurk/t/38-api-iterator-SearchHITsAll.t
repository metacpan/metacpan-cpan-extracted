#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
BEGIN { push(@INC, "lib", "t"); }
use TestHelper;

my $mturk = TestHelper->new;

if (!$ENV{MTURK_TEST_WRITABLE}) {
    plan skip_all => "Set environment variable MTURK_TEST_WRITABLE=1 to enable tests which have side-effects.";
}
else {
    plan tests => 7; 
}

sub findAllHITs {
    my ($mturk, $generatedHITs, $pageSize) = @_;
    
    my %prevFound;
    my %notFound;
    while (my ($hitId,$hit) = each %$generatedHITs) {
        $notFound{$hitId} = 1;
    }
    
    #print STDERR "calling SearchHITsAll with pageSize $pageSize\n";
    
    my $hits = $mturk->SearchHITsAll(
        PageSize => $pageSize,
        SortProperty => 'Title'
    );
    my $hitno = 0;
    while (my $hit = $hits->next) {
        if ((++$hitno % $pageSize) == 0) {
            # add some sleep to keep from being throttled
            select(undef, undef, undef, 0.5);
        }
     
        #print STDERR "Found hit " . $hit->{HITId}[0] . " on page " . $mturk->response->result->{PageNumber}[0] . "\n";
        if (exists $notFound{$hit->{HITId}[0]}) {
            if (exists $prevFound{$hit->{HITId}[0]}) {
                #print STDERR "Previously found hit in iteration " . $hit->{HITId}[0] . " on page " . $prevFound{$hit->{HITId}[0]} . ".";
            }
            else {
                $prevFound{$hit->{HITId}[0]} = $mturk->response->result->{PageNumber}[0];
            }
            delete $notFound{$hit->{HITId}[0]};
        }
    }
    
    my $failed = 0;
    while (my ($hitId, $v) = each %notFound) {
        #print STDERR "Could not find hitId $hitId\n";
        $failed = 1;
    }
    
    ok(!$failed, "SearchHITsAll with PageSize $pageSize");
}

#require Net::Amazon::MechanicalTurk::Transport::RESTTransport;
#Net::Amazon::MechanicalTurk->debug(\*STDOUT);
#Net::Amazon::MechanicalTurk::Transport::RESTTransport->debug(\*STDOUT);

$mturk->filterChain->addFilter(sub{
    my ($chain, $targetParams) = @_;
    select(undef,undef,undef,.7);
    $chain->();
});

ok($mturk, "Created client.");

my %generatedHITs;
my $error;

# Generate some hits to search for
# These hits are generated with a title
# that may be sorted.  By default SearchHITs
# sorts by creation time, this becomes an issue
# when 2 hits have the same creation time.
# It is possible for hits of the same creation time
# to switch the order in which they come back between
# multiple calls to the service. If the switching of order
# causes a hit to appear on a different page, you 
# may miss 1 hit and see another twice.
#
foreach my $n (1..9) {
    my $hit = $mturk->newHIT(Title => sprintf("%03d Test HIT", $n));
    #print STDERR "Generated hit: " . $hit->{HITId}[0] . "\n";
    $generatedHITs{$hit->{HITId}[0]} = $hit;
}

ok(1, "Generated some hits.");

findAllHITs($mturk, \%generatedHITs, 4);
findAllHITs($mturk, \%generatedHITs, 1);
findAllHITs($mturk, \%generatedHITs, 3);
findAllHITs($mturk, \%generatedHITs, 15);
findAllHITs($mturk, \%generatedHITs, 100);

while (my ($hitId, $hit) = each %generatedHITs) {
    $mturk->destroyHIT($hitId);
}

