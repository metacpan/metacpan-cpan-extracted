#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use Net::IANA::Services (
    #  Import the regular expressions to test for services/ports
    ':regexes',

    #  Import the hashes to test for services/ports or get info for a service/protocol
    ':hashes',

    #  Import the subroutines to test for services/ports or get info for a service/protocol
    ':subs',

    #  Alternatively this loads everything
    #  ':all',
);


my @regex_tests = (
    [$IANA_REGEX_PORTS, 'port regex',
        [qw/ 22      53  8080  /],
        [qw/ 10006  -43  65536 /],
    ],
    [$IANA_REGEX_SERVICES, 'service regex',
        [qw/ http   htTPS   sSh   /],
        [qw/ blarg  zhttpz  80ssh  blarg-ap /],
    ],

    [$IANA_REGEX_PORTS_DCCP, 'dccp port regex',
        [qw/ 6514  1022  9  /],
        [qw/ 22    53    80 /],
    ],
    [$IANA_REGEX_SERVICES_DCCP, 'dccp service regex',
        [qw/ syslog-tls  exp2   discard /],
        [qw/ blargz      zexp2  http    /],
    ],

    [$IANA_REGEX_PORTS_SCTP, 'sctp port regex',
        [qw/ 21  9901  9 /],
        [qw/ 53  1310  5 /],
    ],
    [$IANA_REGEX_SERVICES_SCTP, 'sctp service regex',
        [qw/ ftp    enrp-sctp  discard  /],
        [qw/ blarg  husky      zdiscard /],
    ],

    [$IANA_REGEX_PORTS_TCP, 'tcp port regex',
        [qw/ 5196   53    9 /],
        [qw/ 5116 5105 5046 /],
    ],
    [$IANA_REGEX_SERVICES_TCP, 'tcp service regex',
        [qw/ ampl-tableproxy   domain     discard /],
        [qw/ emb-proj-cmd      hughes-ap  vpm-udp /],
    ],

    [$IANA_REGEX_PORTS_UDP, 'udp port regex',
        [qw/ 5116    53     9 /],
        [qw/ 5196  5157  5115 /],
    ],
    [$IANA_REGEX_SERVICES_UDP, 'udp service regex',
        [qw/ emb-proj-cmd     domain  discard   /],
        [qw/ ampl-tableproxy  mediat  autobuild /],
    ],
);


my $tests;

#  regex tests
for  my $test_ref  (@regex_tests) {
    $tests += @{$test_ref->[$_]}  for  2..3;
}
$tests +=  19;  # synopsis tests
$tests +=  8;  # hash tests
$tests +=  16;  # sub tests

plan tests => $tests;



####################
#  SYNOPSIS TESTS  #
####################

#  Declare some strings to test
my $service = 'https';
my $port    = 22;


#  How the regexes work
is $service =~ $IANA_REGEX_SERVICES,     1, 'Synopsis service regex tested okay';
is $service =~ $IANA_REGEX_SERVICES_UDP, 1, 'Synopsis udp service regex tested okay';
is $port    =~ $IANA_REGEX_PORTS,        1, 'Synopsis port regex tested okay';
is $port    =~ $IANA_REGEX_PORTS_TCP,    1, 'Synopsis tcp port regex tested okay';


is_deeply $IANA_HASH_INFO_FOR_SERVICE->{ $service }{ tcp }{ 443 },
    { name => 'https', desc => 'http protocol over TLS/SSL', note => '' },
    'Synopsis info hash is correctly';

is_deeply $IANA_HASH_PORTS_FOR_SERVICE->{ $service }, [qw/ 443 /], 'Synopsis ports for service hash is correct';

is_deeply $IANA_HASH_SERVICES_FOR_PORT->{ $port },              [qw/ ssh /], 'Synopsis services for port is correct';
is_deeply $IANA_HASH_SERVICES_FOR_PORT_PROTO->{ $port }{ tcp }, [qw/ ssh /], 'Synopsis services for port proto is correct';

is_deeply $IANA_HASH_SERVICES_FOR_PORT_PROTO->{ $port },
    {
        sctp => [qw/ ssh /],
        tcp  => [qw/ ssh /],
        udp  => [qw/ ssh /],
    },
    'Synopsis services for big port proto is correct';


is iana_has_service( $service        ), 1, 'Synopsis has_service is correct';
is iana_has_service( $service, 'tcp' ), 1, 'Synopsis has_service with protocol is correct';
is iana_has_service( $service, 'bla' ), 0, 'Synopsis has_service with bad protocol is correct';
is iana_has_port   ( $port           ), 1, 'Synopsis has_port is correct';
is iana_has_port   ( $port, 'tcp'    ), 1, 'Synopsis has_port with protocol is correct';
is iana_has_port   ( $port, 'bla'    ), 0, 'Synopsis has_port with bad protocol is correct';

is_deeply scalar iana_info_for_service( $service ),
    {
        sctp => {
            '443' => {
                desc => 'HTTPS',
                name => 'https',
                note => '',
            },
        },
        tcp => {
            '443' => {
                desc => 'http protocol over TLS/SSL',
                name => 'https',
                note => '',
            },
        },
        udp => {
            '443' => {
                desc => 'http protocol over TLS/SSL',
                name => 'https',
                note => '',
            },
        },
    },
    'Synopsis info_for_service is correct';

is_deeply scalar iana_info_for_service( $service, 'tcp' ),
    {
        '443' => {
            desc => 'http protocol over TLS/SSL',
            name => 'https',
            note => '',
        },
    },
    'Synopsis info_for_service is correct';

is_deeply scalar iana_info_for_port   ( $port           ), [qw/ ssh /], 'Synopsis info_for_port is correct';
is_deeply scalar iana_info_for_port   ( $port, 'tcp'    ), [qw/ ssh /], 'Synopsis info_for_port proto is correct';



####################
#  REGEX EXAMPLES  #
####################
for  my $test_ref  (@regex_tests) {
    my ($regex, $name, $okay_ref, $bad_ref) = @$test_ref;

    for  my $okay_txt  (@$okay_ref) {
        my $msg = "$name matched $okay_txt correctly";
        is $okay_txt =~ $regex, 1, $msg;
    }
    for  my $bad_txt  (@$bad_ref) {
        my $msg = "$name did not match $bad_txt correctly";
        is $bad_txt =~ $regex, q{}, $msg;
    }
}



###################
#  HASH EXAMPLES  #
###################

#  Get info for ssh over tcp
is_deeply $IANA_HASH_INFO_FOR_SERVICE->{ ssh }{ tcp },
    {
        22 => {
            desc => 'The Secure Shell (SSH) Protocol',
            name => 'ssh',
            note => 'Defined TXT keys: u=<username> p=<password>',
        }
    },
    'info hash with proto example is okay';


#  Get info for http over any protocol
is_deeply $IANA_HASH_INFO_FOR_SERVICE->{ http },
    {
        sctp => {
            '80' => {
                desc => 'HTTP',
                name => 'http',
                note => 'Defined TXT keys: u=<username> p=<password> path=<path to document>',
            },
        },
        tcp => {
            '80' => {
                desc => 'World Wide Web HTTP',
                name => 'http',
                note => 'Defined TXT keys: u=<username> p=<password> path=<path to document>',
            },
        },
        udp => {
            '80' => {
                desc => 'World Wide Web HTTP',
                name => 'http',
                note => 'Defined TXT keys: u=<username> p=<password> path=<path to document>',
            },
        },
    },
    'info hash example is okay';

is_deeply $IANA_HASH_SERVICES_FOR_PORT->{   22 }, [qw/ ssh                         /], 'services for port example 1 is okay';
is_deeply $IANA_HASH_SERVICES_FOR_PORT->{ 1110 }, [qw/ nfsd-keepalive  webadmstart /], 'services for port example 2 is okay';

is_deeply $IANA_HASH_SERVICES_FOR_PORT_PROTO->{   22 }{ tcp }, [qw/ ssh             /], 'services for port proto example 1 is okay';
is_deeply $IANA_HASH_SERVICES_FOR_PORT_PROTO->{ 1110 }{ tcp }, [qw/ webadmstart     /], 'services for port proto example 2 is okay';
is_deeply $IANA_HASH_SERVICES_FOR_PORT_PROTO->{ 1110 }{ udp }, [qw/ nfsd-keepalive  /], 'services for port proto example 3 is okay';

is_deeply $IANA_HASH_PORTS_FOR_SERVICE->{ 'http-alt' }, [qw/ 591  8008  8080 /], 'ports for service example 1 is okay';



##################
#  SUB EXAMPLES  #
##################

is iana_has_port( 22 ),    1, 'sub has_port example 1 is correct';
is iana_has_port( 34221 ), 0, 'sub has_port example 2 is correct';

is iana_has_port( 271, 'tcp' ), 1, 'sub has_port proto example 1 is correct';
is iana_has_port( 271, 'udp' ), 0, 'sub has_port proto example 2 is correct';

is iana_has_service( 'ssh' ),    1, 'sub has_service example 1 is correct';
is iana_has_service( 'not-ss' ), 0, 'sub has_service example 2 is correct';

is iana_has_service( 'xmpp-server', 'tcp' ), 1, 'sub has_service proto example 1 is correct';
is iana_has_service( 'xmpp-server', 'udp' ), 0, 'sub has_service proto example 2 is correct';


is_deeply scalar iana_info_for_port( 22 )   ,  [qw/ ssh /], 'sub info_for_port example 1 is correct';
is        scalar iana_info_for_port( 34221 ),  undef      , 'sub info_for_port example 2 is correct';

is_deeply scalar iana_info_for_port( 271, 'tcp' ),  [qw/ pt-tls /], 'sub info_for_port proto example 1 is correct';
is        scalar iana_info_for_port( 271, 'udp' ),  undef         , 'sub info_for_port proto example 2 is correct';

is_deeply scalar iana_info_for_service( 'xribs'  ),  { udp => { 2025 => { desc => '', name => 'xribs', note => '' } } }, 'sub info_for_service example 1 is correct';
is        scalar iana_info_for_service( 'not-ss' ),  undef                                                             , 'sub info_for_service example 2 is correct';

is        scalar iana_info_for_service( 'xribs', 'tcp' ),  undef                                                  , 'sub info_for_service proto example 1 is correct';
is_deeply scalar iana_info_for_service( 'xribs', 'udp' ),  { 2025 => { desc => '', name => 'xribs', note => '' } }, 'sub info_for_service proto example 2 is correct';
