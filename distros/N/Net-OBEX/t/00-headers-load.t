#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 27;

BEGIN {
    use_ok('Carp');
    use_ok('Encode');
    use_ok('Net::OBEX::Packet::Headers::Unicode');
    use_ok('Net::OBEX::Packet::Headers::ByteSeq');
    use_ok('Net::OBEX::Packet::Headers::Byte1');
    use_ok('Net::OBEX::Packet::Headers::Byte4');
    use_ok( 'Net::OBEX::Packet::Headers' );

}

diag( "Testing Net::OBEX::Packet::Headers $Net::OBEX::Packet::Headers::VERSION, Perl $], $^X" );

my $header = pack 'H*', '4a0013f9ec7bc4953c11d2984e525400dc9e09cb00000001';

my $head = Net::OBEX::Packet::Headers->new;

my $parse_ref = $head->parse( $header );

ok( exists $parse_ref->{who}, '{who} header must exist in the parse' );
ok( exists $parse_ref->{connection_id},
    '{connection_id} header must exist in the parse');

my $target_value = 'F9EC7BC4953C11D2984E525400DC9E09';
my $headers
 = $head->make( 'target' => pack 'H*', $target_value );

my @headers = qw(
     count  length  timeb  connection_id
     type  time        http
     who   app_params  auth_challenge   auth_response
     body  end_of_body object_class
     name  description
);

for ( @headers ) {
    $headers .= $head->make( $_ => 'blah' );
}

$parse_ref = $head->parse( $headers );

use Data::Dumper;
print Dumper($parse_ref);
for ( @headers ) {
    ok( exists $parse_ref->{$_}, "{$_} header must exist in the parse");
}

is(
    (uc unpack 'H*', $parse_ref->{target}),
    $target_value,
    'parse must have proper OBEX FTP Target header'
);

is(
    $parse_ref->{type},
    'blah',
    '{type} header must be present in the parse',
);
