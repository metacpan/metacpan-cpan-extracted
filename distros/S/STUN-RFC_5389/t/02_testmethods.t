#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

use STUN::RFC_5389;



my $host = '123.123.123.123';
my $port = '4567';



# create STUN request
my $request = STUN::RFC_5389->Client( { request => 1 } );
ok( $request, "request was created" );

# create STUN indication
my $indication = STUN::RFC_5389::Client( { indication => 1 } );
ok( $indication, "indication was created" );



# process STUN request
my $request_answer = STUN::RFC_5389::Server( $request, $port, $host );
ok( $request_answer, "answer was created for the request" );

# process STUN indication
my $indication_answer = STUN::RFC_5389->Server( $indication, $port, $host );
ok( ! defined $indication_answer, "indication was received and dropped" );



# parse STUN request answer
my $answer_hashref = STUN::RFC_5389->Client( $request_answer );
ok( $answer_hashref && ref( $answer_hashref ), "answer was parsed into a hash reference" );
ok( $answer_hashref->{attributes}{'8022'}{software} eq $answer_hashref->{attributes}{SOFTWARE}{software}, "attributes are stored in two formats" );
ok( $answer_hashref->{attributes}{'0020'}{family} eq '01', "host was IPv4" );
ok( $answer_hashref->{attributes}{'0020'}{address} eq $host, "host was returned correct" );
ok( $answer_hashref->{attributes}{'0020'}{port} == $port, "port was returned correct" );
