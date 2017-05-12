#!perl
use strict;
use warnings;
use Test::More tests => 4;

our $class;

BEGIN { $class = 'Net::Whois::RIPE'; use_ok $class }

can_ok $class, 'new';

my $whois;

eval { $whois = $class->new; };

SKIP: {
    skip "Network issue",2 if ( $@ =~ /IO::Socket::INET/ );
    
    ok(!$@, " $class can create default instance\n$@");
    isa_ok $whois, $class;
}
