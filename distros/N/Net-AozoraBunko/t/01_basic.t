use strict;
use warnings;
use utf8;
use Test::More 0.88;

use Net::AozoraBunko;

# all methods
can_ok(
    'Net::AozoraBunko',
    qw/
        new
        authors author
        works all_works
        get_text get_zip
        search_author search_work
    /,
);

#----- new
my $ab = Net::AozoraBunko->new;
isa_ok($ab, 'Net::AozoraBunko');

{
    is ref $ab->ua, 'LWP::UserAgent', 'ua';
    is $ab->ua->timeout, 10, 'ua default timeout';
}

require LWP::UserAgent;
{
    my $ab_with_ua = Net::AozoraBunko->new({
        ua => LWP::UserAgent->new(timeout => 69)
    });
    is $ab_with_ua->ua->timeout, 69, 'constract with LWP::UserAgent';

    $ab_with_ua->ua(LWP::UserAgent->new(timeout => 55));
    is $ab_with_ua->ua->timeout, 55, 'set ua obj';
}

done_testing;


