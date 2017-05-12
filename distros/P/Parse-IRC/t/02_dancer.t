use strict;
use warnings;
use Test::More 'no_plan';
use Parse::IRC;
my $line = ':pretend.dancer.server 005 CPAN MODES=4 CHANLIMIT=#:20 NICKLEN=16 USERLEN=10 HOSTLEN=63 TOPICLEN=450 KICKLEN=450 CHANNELLEN=30 KEYLEN=23 CHANTYPES=# PREFIX=(ov)@+ CASEMAPPING=ascii CAPAB IRCD=dancer :are available on this server';
my $parser = Parse::IRC->new( debug => 1 );
my $data = $parser->parse( $line );
is( ref $data, 'HASH', 'We got a hashref' );
is( scalar @{ $data->{params} }, 16, 'We got 16 params' );
