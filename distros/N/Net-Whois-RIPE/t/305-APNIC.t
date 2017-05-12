use strict;
use warnings;

use Test::More qw(no_plan);

use_ok 'Net::Whois::Generic';

my $c = Net::Whois::Generic->new( disconnected => 1, unfiltered => 0 );
isa_ok $c, 'Net::Whois::Generic';

my $mntner;
eval { ($mntner) = $c->query( 'MAINT-APNIC-AP', { type => 'mntner' } ) };

SKIP: {
    skip "Network issue",14 if ( $@ =~ /IO::Socket::INET/ );

    ok !$@, qq{Client performs queries without dying $@};
    isa_ok $mntner, 'Net::Whois::Object::Mntner::APNIC';

    my @o;
    eval { @o = $c->query('101.0.0.0/8') };
    ok !$@, qq{Client performs queries without dying $@};
    for my $o (@o) {
        my $type = ref $o;
        ok( $type =~ /(APNIC|Information)/, "Object " . $o->class . " returned" );
    }
}
