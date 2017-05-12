use strict;
use warnings;
use Test::More 'no_plan';
use POE::Filter::IRCD;

my $filter = POE::Filter::IRCD->new();
isa_ok( $filter, 'POE::Filter::IRCD' );

my $line = ':pretend.dancer.server 005 CPAN MODES=4 CHANLIMIT=#:20 NICKLEN=16 USERLEN=10 HOSTLEN=63 TOPICLEN=450 KICKLEN=450 CHANNELLEN=30 KEYLEN=23 CHANTYPES=# PREFIX=(ov)@+ CASEMAPPING=ascii CAPAB IRCD=dancer :are available on this server';

foreach my $irc_event ( @{ $filter->get( [ $line ] ) } ) {
  ok( ref $irc_event eq 'HASH', 'Okay it is a hashref' );
  is( scalar @{ $irc_event->{params} }, 16, 'There are 16 params' );
}
