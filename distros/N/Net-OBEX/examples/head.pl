#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw{../lib lib};
use Net::OBEX::Packet::Headers;
my $header = pack 'H*', '4a0013f9ec7bc4953c11d2984e525400dc9e09cb00000001';

my $head = Net::OBEX::Packet::Headers->new;

my $parse_ref = $head->parse( $header );

my @headers = keys %$parse_ref;

print "Your data containts " . @headers . " headers which are: \n",
     map { "[$_]\n" } @headers;

my $type_header
= $head->make( 'target' => pack 'H*', 'F9EC7BC4953C11D2984E525400DC9E09' );

printf "Type header for OBEX FTP (F9EC7BC4953C11D2984E525400DC9E09) "
        . "in hex is: \n%s\n",
            unpack 'H*', $type_header;

print "Let's see what the parse says... \n";

$parse_ref = $head->parse( $type_header );

print map { "$_ => " . uc unpack( 'H*', $parse_ref->{$_}) . "\n" }
        keys %$parse_ref;

print "Done\n";

