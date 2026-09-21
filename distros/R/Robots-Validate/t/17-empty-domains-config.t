#!perl

# Two configuration values that take the wrong branch when they are empty:
# an empty domain list, which joined into an alternation matches every
# hostname rather than none, and an unset cache_options, which is documented
# as optional but was dereferenced unconditionally on every cached call.

use Test2::V0;

use Test2::Require::Module 'CHI';

use Module::Load qw( autoload );
use Net::DNS::Resolver::Mock;

use Robots::Validate;

use experimental qw( signatures );

my $IP   = '198.51.100.13';
my $ARPA = '13.100.51.198.in-addr.arpa.';

my $resolver = Net::DNS::Resolver::Mock->new;
$resolver->zonefile_parse( <<"ZONE" );
$ARPA 3600 IN PTR host.elsewhere.example.
host.elsewhere.example. 3600 IN A $IP
ZONE

sub with_domain ($domain) {
    my $rv = Robots::Validate->new(
        resolver => $resolver,
        config   => [ { name => 'ex', agents => ['examplebot'], domain => $domain } ],
    );
    return $rv->validate( $IP, 'examplebot/1.0' );
}

subtest 'an empty domain list matches no hostname' => sub {

    is with_domain( [] ), undef,
      'domain => [] is the same as not specifying a domain';

    # The behaviour the fix must not break.
    is with_domain( ['.nowhere.example'] ), '',
      'a one-element list that does not name the host still refuses it';

    is with_domain( [ '.a.example', '.b.example' ] ), '',
      'a two-element list that does not name the host still refuses it';

    is with_domain( ['.elsewhere.example'] ), [ 'ex' => 'examplebot' ],
      'a list that does name the host still validates it';

    is with_domain( [ '.nowhere.example', '.elsewhere.example' ] ), [ 'ex' => 'examplebot' ],
      'and so does a list where only the second entry names it';
};

subtest 'a cache can be configured without cache_options' => sub {

    autoload "CHI";

    my $rv = Robots::Validate->new(
        resolver => $resolver,
        config   => [ { name => 'ex', agents => ['examplebot'], domain => '.elsewhere.example' } ],
        cache    => CHI->new( driver => 'Memory', global => 1, namespace => 't17' ),
    );

    is $rv->cache_options, {}, 'cache_options defaults to an empty hash reference';

    my $res;
    ok lives { $res = $rv->validate( $IP, 'examplebot/1.0' ) },
      'validate does not die when cache_options was not given'
      or note $@;

    is $res, [ 'ex' => 'examplebot' ], 'and it returns the right answer';

    is $rv->validate( $IP, 'examplebot/1.0' ), [ 'ex' => 'examplebot' ],
      'the second, cached call agrees';
};

done_testing;
