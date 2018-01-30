use strict;
use warnings;

use Test::More;
use Net::Async::MPD;

ok my $mpd = Net::Async::MPD->new, 'constructor succeeds';

# Attributes
can_ok $mpd, $_ foreach qw( version auto_connect state password host port );

# Methods
can_ok $mpd, $_ foreach qw( send get idle noidle connect );

done_testing();
