#!perl

# A DNS lookup that returns no answer at all -- SERVFAIL, REFUSED, a timeout --
# says nothing about the client.  It must not be reported as the "fake robot"
# verdict, which the POD defines as a defined-but-false return and which
# bad_robot turns into a true answer.  KNOWN ISSUES records that robot rDNS
# "may randomly fail", so this is not a rare input.

use Test2::V0 -no_srand;

use Net::DNS::Resolver::Mock;

use Robots::Validate;

use experimental qw( signatures );

my $IP   = '198.51.100.13';
my $ARPA = '13.100.51.198.in-addr.arpa.';

# Up, but cannot answer: Net::DNS reports this by returning undef from query().
package Failing::Resolver {
    use parent -norequire, 'Net::DNS::Resolver::Mock';
    sub send { return undef }
}

my @RULE = ( { name => 'ex', agents => ['examplebot'], domain => '.crawl.example.local' } );

# Answers definitively, and the answer does not match the rule.
my $answering = Net::DNS::Resolver::Mock->new;
$answering->zonefile_parse("$ARPA 3600 IN PTR host.elsewhere.example.\n");

# Answers definitively, and the answer confirms.
my $confirming = Net::DNS::Resolver::Mock->new;
$confirming->zonefile_parse( <<"ZONE" );
$ARPA 3600 IN PTR node.crawl.example.local.
node.crawl.example.local. 3600 IN A $IP
ZONE

sub rv ( $resolver, %extra ) {
    return Robots::Validate->new( resolver => $resolver, config => [@RULE], %extra );
}

for my $mode (qw/ first relaxed strict/) {

    subtest "validation_mode=${mode}" => sub {

        my $failing = rv( Failing::Resolver->new, validation_mode => $mode );

        is $failing->validate( $IP, 'examplebot/1.0' ), undef,
          'a resolver that cannot answer leaves the client unknown';

        is $failing->bad_robot( $IP, 'examplebot/1.0' ), undef,
          'and bad_robot does not accuse it';

        # The behaviour the fix must not break.
        my $definitive = rv( $answering, validation_mode => $mode );

        is $definitive->validate( $IP, 'examplebot/1.0' ), '',
          'a definitive answer that does not match is still an imposter';

        ok $definitive->bad_robot( $IP, 'examplebot/1.0' ),
          'and bad_robot still accuses it';

        my $good = rv( $confirming, validation_mode => $mode );

        is $good->validate( $IP, 'examplebot/1.0' ), [ 'ex' => 'examplebot' ],
          'a confirmed robot still validates';
    };
}

done_testing;
