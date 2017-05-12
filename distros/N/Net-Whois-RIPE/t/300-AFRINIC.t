use strict;
use warnings;

use Test::More qw(no_plan);

use_ok 'Net::Whois::Generic';

my $c = Net::Whois::Generic->new( disconnected => 1, unfiltered => 1 );
isa_ok $c, 'Net::Whois::Generic';

my $org;
eval { ($org) = $c->query( 'ORG-AFNC1-AFRINIC', { type => 'organisation' } ) };

SKIP: {
    skip "Network issue",14 if ( $@ =~ /IO::Socket::INET/ );

    ok !$@, qq{Client performs queries without dying $@};
    isa_ok $org, 'Net::Whois::Object::Organisation::AFRINIC';

    my @o;
    eval { @o = $c->query('105.0.0.1') };
    ok !$@, qq{Client performs queries without dying $@};
    for my $o (@o) {
        my $type = ref $o;
        ok( $type =~ /(AFRINIC|Information)/, "Object " . $o->class . " returned" );
    }
}
