use strict;
use warnings;
use Test::More qw( no_plan );

# synchronizes the {error,standard} output of this test.
use IO::Handle;
STDOUT->autoflush(1);
STDERR->autoflush(1);

our $class;
BEGIN { $class = 'Net::Whois::Object::Response'; use_ok $class; }

our %tested;

my @lines  = <DATA>;
our $object = ( Net::Whois::Object->new(@lines) )[0];

isa_ok $object, $class;

# Non-inherited methods
can_ok $object, qw( response );

# Check if typed attributes are correct
can_ok $object, $object->attributes('mandatory');

# Test 'response'
$tested{'response'}++;
is( $object->response(), 'ERROR:101:', 'response properly parsed' );

# Test 'comment'
$tested{'comment'}++;
is_deeply( $object->comment(), [ '', 'No entries found in source TEST.' ], 'comment properly parsed' );

# Common tests
do 't/common.pl';
ok( $tested{common_loaded}, "t/common.pl properly loaded" );
ok( !$@, "Can evaluate t/common.pl ($@)" );

__DATA__
%ERROR:101: no entries found
% 
%  No entries found in source TEST.

