# These tests are not under ./t because if hosts move, I don't want the dist to
# stop installing. -- rjbs, 2008-05-22
use strict;
use warnings;
use Test::More tests => 9;
use Net::DNS::GuessTZ qw(tz_from_host);

my %data = (
 'rjbs.manxome.org'  => [ 'America/New_York', 'America/New_York' ],

 'www.google.co.uk'  => [ 'America/New_York', 'Europe/London' ],
 'www.sixapart.jp'   => [ 'America/New_York', 'Asia/Tokyo' ],

 'www.parliament.uk' => [ 'Europe/London',    'Europe/London' ],
);

{
  local $TODO = "fix sample hosts to be in UK by IP";
  is_deeply(
    [ Net::DNS::GuessTZ->_all_tz_from_ip('www.parliament.uk') ],
    [ qw(Europe/London) ],
    "parliament is hosted in Blighty",
  );
}

for my $host (sort keys %data) {
  for my $priority ('ip', 'cc') {
    local $TODO = "fix sample hosts to be in UK by IP";
    my $have = tz_from_host($host, { priority => $priority });
    my $want = $data{ $host }[ $priority eq 'cc' ? 1 : 0 ];

    is($have, $want, "$host, priority: $priority => $want");
  }
}
