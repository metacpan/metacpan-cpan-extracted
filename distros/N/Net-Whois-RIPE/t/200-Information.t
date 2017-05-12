use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::Information'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( comment );

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');

# Test 'comment'
$tested{'comment'}++;
is_deeply( $object->comment(), [ 'This is the RIPE Database query service.', 'The objects are in RPSL format.' ], 'comment properly parsed' );

# Common tests
do 't/common.pl';
ok( $tested{common_loaded}, "t/common.pl properly loaded" );
ok( !$@, "Can evaluate t/common.pl ($@)" );

__DATA__
% This is the RIPE Database query service.
% The objects are in RPSL format.

