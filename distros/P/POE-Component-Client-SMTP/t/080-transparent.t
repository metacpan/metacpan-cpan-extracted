#!/usr/bin/env perl

#################################################################################
# Copyright (c) 2005-2009 George Nistorica				        #
# All rights reserved.							        #
# This file is part of POE::Component::Client::SMTP			        #
# POE::Component::Client::SMTP is free software; you can redistribute it and/or #
# modify it under the same terms as Perl itself.  See the LICENSE	        #
# file that comes with this distribution for more details.		        #
#################################################################################

# 	$Id: 080-transparent.t,v 1.4 2009/09/02 08:23:37 UltraDM Exp $

use strict;
use warnings;

use lib q{./lib/};
use Test::More tests => 2;

diag(q{Testing SMTP Transparency});

use Socket;
use POE;
use POE::Component::Server::TCP;
use POE::Component::Client::SMTP;

my $EOL                   = qq{\015\012};
my @smtp_server_responses = (
    q{220 localhost ESMTP POE::Component::Client::SMTP Test Server},
    qq{250-localhost$EOL}
      . qq{250-PIPELINING$EOL}
      . qq{250-SIZE 250000000$EOL}
      . qq{250-VRFY$EOL}
      . qq{250-ETRN$EOL}
      . q{250 8BITMIME},
    q{250 Ok},                                 # mail from
    q{250 Ok},                                 # rcpt to:
    q{354 End data with <CR><LF>.<CR><LF>},    # data
    q{250 Ok: queued as 549B14484F},           # end data
    q{221 Bye},                                # quit
);
my $to_be_translated_line = qq{.Line to be translated$EOL};
my $email_body =
    qq{From: George$EOL}
  . qq{To: George$EOL}
  . qq{Subject: Test$EOL}
  . qq{$EOL}
  . qq{Test line$EOL}
  . $to_be_translated_line
  . qq{Third line$EOL};

my $tcp_srv_port    = 25252;
my $tcp_srv_address = q{localhost};
my $tcp_srv_alias   = q{TCP_SRV};

POE::Component::Server::TCP->new(
    q{Port}                  => $tcp_srv_port,
    q{Address}               => $tcp_srv_address,
    q{Domain}                => AF_INET,
    q{Alias}                 => $tcp_srv_alias,
    q{Error}                 => \&tcp_error_handler,
    q{ClientInput}           => \&handle_client_input,
    q{ClientConnected}       => \&handle_client_connect,
    q{ClientFilter}          => POE::Filter::Line->new(),
    q{ClientShutdownOnError} => 1,
);

POE::Session->create(
    q{package_states} => [
        q{main} => [
            q{_start},           q{_stop},
            q{start_pococlsmtp}, q{smtp_success},
            q{smtp_failure}
        ],
    ],
    q{heap} => {
        q{alias}       => q{Main_Session},
        q{tcp_port}    => $tcp_srv_port,
        q{tcp_address} => $tcp_srv_address,
        q{tcp_alias}   => $tcp_srv_alias,
    },
);

POE::Kernel->run();

sub _start {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    diag(   q{using POE::Component::Client::SMTP VERSION: }
          . qq{$POE::Component::Client::SMTP::VERSION} );
    $kernel->alias_set( $heap->{q{alias}} );
    $kernel->yield(q{start_pococlsmtp});

    return;
}

sub tcp_error_handler {
    my ( $syscall_name, $error_number, $error_string ) = @_[ ARG0, ARG1, ARG2 ];
    die qq{SYSCALL: $syscall_name, ERRNO: $error_number, ERRSTR: $error_string};
}

sub handle_client_input {
    my ( $heap, $input ) = @_[ HEAP, ARG0 ];
    my $test = 0;

    if ( $input =~ /^(helo|ehlo|mail from:|rcpt to:|data|\.|quit)/io ) {
        if ( $input =~ /^\.\.Line to be translated/io ) {
            $test = 1;
            test_transparent($test);
        }
        elsif ( $input =~ /^\.Line to be translated/io ) {
            $test = 0;
            test_transparent($test);
        }
        else {
        }
        $heap->{q{client}}->put( shift @smtp_server_responses );
    }
}

sub test_transparent {
    my $test = shift;
    is( $test, 1, q{Transparent SMTP} );
}

sub handle_client_connect {
    $_[HEAP]->{q{client}}->put( shift @smtp_server_responses );
}

sub start_pococlsmtp {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    POE::Component::Client::SMTP->send(
        q{From}         => q{charlie@localhost},
        q{To}           => q{root@localhost},
        q{Server}       => $heap->{q{tcp_address}},
        q{Port}         => $heap->{q{tcp_port}},
        q{Body}         => $email_body,
        q{SMTP_Success} => q{smtp_success},
        q{SMTP_Failure} => q{smtp_failure},
    );
    return;
}

sub smtp_success {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    pass(q{SMTP Success});
    $kernel->post( $heap->{q{tcp_alias}}, q{shutdown} );
    return;
}

sub smtp_failure {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    fail(q{SMTP Success});
    $kernel->post( $heap->{q{tcp_alias}}, q{shutdown} );
    return;
}

sub _stop {
    my ( $kernel, $heap ) = @_[ KERNEL, HEAP ];
    return;
}

