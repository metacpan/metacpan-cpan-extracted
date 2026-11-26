#!perl

# A client owns the reverse zone for its own address, so it chooses how many
# names the PTR lookup returns.  _check_dns forward-confirms the names that
# match the rule's domain; without a limit that is one lookup per name, each
# for a distinct name and so each a cache miss resolved upstream.

use Test2::V0 -no_srand;

use Net::DNS::Resolver::Mock;

use Robots::Validate;

use experimental qw( signatures );

my $IP   = '198.51.100.13';
my $ARPA = '13.100.51.198.in-addr.arpa.';

# Counted at send(), which both query() and search() funnel through.
package Counting::Resolver {
    use parent -norequire, 'Net::DNS::Resolver::Mock';
    our $CALLS = 0;
    sub send { $CALLS++; return shift->SUPER::send(@_) }
}

my @RULE = ( { name => 'ex', agents => ['examplebot'], domain => '.crawl.example.local' } );

sub lookups ( $ptr_count, %extra ) {
    my $zone = "";
    $zone .= "$ARPA 3600 IN PTR n$_.crawl.example.local.\n" for 1 .. $ptr_count;

    my $resolver = Counting::Resolver->new;
    $resolver->zonefile_parse($zone);

    my $rv = Robots::Validate->new( resolver => $resolver, config => \@RULE, %extra );
    $rv->_agents;

    $Counting::Resolver::CALLS = 0;
    my $res = $rv->validate( $IP, 'examplebot/1.0' );
    return ( $Counting::Resolver::CALLS, $res );
}

subtest 'the forward-confirmation loop is bounded' => sub {

    # None of these PTR names has a forward record, so every one of them is
    # tried and the count is the loop length plus the single PTR query.
    my ($few)  = lookups(2);
    my ($many) = lookups(50);

    is $few, 3, 'two PTR names cost one PTR query plus two forward queries';

    is $many, 5, 'fifty PTR names cost no more than the default limit of four forward queries';

    my ($raised) = lookups( 50, max_forward_lookups => 10 );
    is $raised, 11, 'the limit is what bounds it, and it is configurable';
};

subtest 'bounding does not break confirmation' => sub {

    my $resolver = Net::DNS::Resolver::Mock->new;
    $resolver->zonefile_parse(<<"ZONE");
$ARPA 3600 IN PTR node.crawl.example.local.
node.crawl.example.local. 3600 IN A $IP
ZONE

    my $rv = Robots::Validate->new( resolver => $resolver, config => \@RULE );

    is $rv->validate( $IP, 'examplebot/1.0' ), [ 'ex' => 'examplebot' ], 'a genuine single-PTR host still validates';

    my $second = Net::DNS::Resolver::Mock->new;
    $second->zonefile_parse(<<"ZONE");
$ARPA 3600 IN PTR decoy.crawl.example.local.
$ARPA 3600 IN PTR node.crawl.example.local.
decoy.crawl.example.local. 3600 IN A 203.0.113.9
node.crawl.example.local. 3600 IN A $IP
ZONE

    my $rv2 = Robots::Validate->new( resolver => $second, config => \@RULE );

    is $rv2->validate( $IP, 'examplebot/1.0' ), [ 'ex' => 'examplebot' ],
      'a host whose confirming name is not the first PTR record still validates';
};

done_testing;
