#!/usr/bin/env perl

# Copyright (c) 2005 - 2009 George Nistorica
# All rights reserved.
# This file is part of POE::Component::Client::SMTP
# POE::Component::Client::SMTP is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# 	$Id: 040-transaction-log.t,v 1.4 2009/09/02 08:23:37 UltraDM Exp $

use strict;

# check that by default the transaction log is disabled when SMTP_Success - ARG1 undefined
# check that by default the transaction log is disabled when SMTP_Failure - ARG1 undefined
# check that when enabled, you really get the transaction log when SMTP_Success - ARG1
# check that when enabled, you really get the transaction log when SMTP_Failure - ARG2

use lib q{../lib};
use Test::More tests => 9;    # including use_ok
use Data::Dumper;
use Carp;

BEGIN { use_ok(q{IO::Socket::INET}); }
BEGIN { use_ok(q{POE}); }
BEGIN { use_ok(q{POE::Wheel::ListenAccept}); }
BEGIN { use_ok(q{POE::Component::Server::TCP}); }
BEGIN { use_ok(q{POE::Component::Client::SMTP}); }

# the tests we're running
my %test = (
    q{transaction_log_disabled_smtp_failure} => 0,
    q{transaction_log_disabled_smtp_success} => 0,
    q{transaction_log_enabled_smtp_failure}  => 0,
    q{transaction_log_enabled_smtp_success}  => 0,
);
my $smtp_message;
my @recipients;
my $from;
my $debug = 0;

$smtp_message = create_smtp_message();
@recipients   = qw(
  george@localhost,
  root@localhost,
  george.nistorica@localhost,
);
$from = q{george@localhost};

##### SMTP server vars
my $port                  = 25252;
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
    q{250 Ok},                                 # rcpt to:, cc
    q{250 Ok},                                 # rctp to:, bcc
    q{354 End data with <CR><LF>.<CR><LF>},    # data
    q{250 Ok: queued as 549B14484F},           # end data
    q{221 Bye},                                # quit
);

# create the SMTP server session
POE::Component::Server::TCP->new(
    q{Port}                  => $port,
    q{Address}               => q{localhost},
    q{Domain}                => AF_INET,
    q{Alias}                 => q{smtp_server},
    q{Error}                 => \&error_handler,               # Optional.
    q{ClientInput}           => \&handle_client_input,         # Required.
    q{ClientConnected}       => \&handle_client_connect,       # Optional.
    q{ClientDisconnected}    => \&handle_client_disconnect,    # Optional.
    q{ClientError}           => \&handle_client_error,         # Optional.
    q{ClientFlushed}         => \&handle_client_flush,         # Optional.
    q{ClientFilter}          => q{POE::Filter::Line},          # Optional.
    q{ClientInputFilter}     => q{POE::Filter::Line},          # Optional.
    q{ClientOutputFilter}    => q{POE::Filter::Line},          # Optional.
    q{ClientShutdownOnError} => 1,                             #
);

# create the pococlsmtp master session
# 4 of them :)

foreach my $key ( keys %test ) {
    POE::Session->create(
        q{inline_states} => {
            q{_start}             => \&start_session,
            q{_stop}              => \&stop_session,
            q{send_mail}          => \&spawn_pococlsmt,
            q{pococlsmtp_success} => \&smtp_send_success,
            q{pococlsmtp_failure} => \&smtp_send_failure,
        },
        q{heap} => { q{test} => $key, }   # store the test name for each session
    );
}

POE::Kernel->run();

# run tests
foreach my $key ( keys %test ) {
    my $name = $key;
    $name =~ s/_/ /g;
    is( $test{$key}, 1, $name );
}

sub start_session {
    carp q{start_session} if ( $debug == 2 );
    $_[KERNEL]->yield(q{send_mail});
}

sub spawn_pococlsmt {
    carp q{spawn_pococlsmt} if ( $debug == 2 );
    my $heap       = $_[HEAP];
    my %parameters = (
        q{From}         => $from,
        q{To}           => \@recipients,
        q{SMTP_Success} => q{pococlsmtp_success},
        q{SMTP_Failure} => q{pococlsmtp_failure},
        q{Server}       => q{localhost},
        q{Port}         => $port,
        q{Body}         => $smtp_message,
        q{Context}      => q{test context},
        q{Debug}        => 0,
    );

# depending on which test we're running there are some things to be
# modified as well. look also for the Server how it does handle client connection
    if ( $heap->{q{test}} eq q{transaction_log_enabled_smtp_success} ) {
        $parameters{q{TransactionLog}} = 1;
    }
    if ( $heap->{q{test}} eq q{transaction_log_enabled_smtp_failure} ) {
        $parameters{q{TransactionLog}} = 1;
        $parameters{q{MyHostname}}     = q{Fail};
    }
    elsif ( $heap->{q{test}} eq q{transaction_log_disabled_smtp_failure} ) {
        $parameters{q{MyHostname}} = q{Fail};
    }
    POE::Component::Client::SMTP->send(%parameters);
}

sub stop_session {

    # stop server
    carp q{stop_session} if ( $debug == 2 );
    $_[KERNEL]->call( q{smtp_server} => q{shutdown} );
}

sub smtp_send_success {
    my ( $arg0, $arg1, $heap ) = @_[ ARG0, ARG1, HEAP ];
    print q{SMTP_Success: ARG0, }, Dumper($arg0), qq{\nARG1, }, Dumper($arg1),
      qq{\n}
      if $debug;

    if ( $heap->{q{test}} eq q{transaction_log_disabled_smtp_success} ) {
        if ( not defined $arg1 ) {
            $test{ $heap->{q{test}} } = 1;
        }
    }
    elsif ( $heap->{q{test}} eq q{transaction_log_enabled_smtp_success} ) {

        # do we have a transaction log?
        if ( defined $arg1 ) {

            # this is how it should be
            if ( compare_transaction_logs( $arg1, return_transaction_log() ) ) {
                $test{ $heap->{q{test}} } = 1;
            }
        }
    }

}

sub smtp_send_failure {
    my ( $arg0, $arg1, $arg2, $heap ) = @_[ ARG0, ARG1, ARG2, HEAP ];
    print q{SMTP_Failure: ARG0, }, Dumper($arg0), qq{\nARG1, }, Dumper($arg1),
      qq{\n}
      if $debug;

    if ( $heap->{q{test}} eq q{transaction_log_disabled_smtp_failure} ) {
        if ( not defined $arg2 ) {
            $test{ $heap->{q{test}} } = 1;
        }
    }
    elsif ( $heap->{q{test}} eq q{transaction_log_enabled_smtp_failure} ) {
        if ( defined $arg2 ) {
            if (
                compare_transaction_logs(
                    $arg2, return_failed_transaction_log()
                )
              )
            {
                $test{ $heap->{q{test}} } = 1;
            }
        }
    }
}

sub create_smtp_message {
    my $body = <<EOB;
To: George Nistorica <george\@localhost>
CC: Root <george\@localhost>
Bcc: Alter Ego <george.nistorica\@localhost>
From: Charlie Root <george\@localhost>
Subject: Email test

Sent with $POE::Component::Client::SMTP::VERSION
EOB

    return $body;
}

sub error_handler {
    my ( $syscall_name, $error_number, $error_string ) = @_[ ARG0, ARG1, ARG2 ];
    die qq{SYSCALL: $syscall_name, ERRNO: $error_number, ERRSTR: $error_string};
}

sub handle_client_input {
    my ( $heap, $input ) = @_[ HEAP, ARG0 ];
    carp q{handle_client_input} if ( $debug == 2 );

    if ( $input =~ /^ehlo fail/io or $input =~ /^helo fail/io ) {

        # this is for the error part
        $heap->{q{client}}->put(q{500 error});
    }
    elsif ( $input =~ /^(ehlo|helo|mail from:|rcpt to:|data|\.|quit)/io ) {
        my $client = $heap->{q{client}};
        $heap->{q{client}}
          ->put( shift @{ $heap->{q{smtp_server_responses}}->{$client} } );
    }
}

sub handle_client_connect {
    my $heap   = $_[HEAP];
    my $client = $heap->{q{client}};
    @{ $heap->{q{smtp_server_responses}}->{$client} } = @smtp_server_responses;
    $heap->{q{client}}
      ->put( shift @{ $heap->{q{smtp_server_responses}}->{$client} } );
}

sub handle_client_disconnect {
    my $heap   = $_[HEAP];
    my $client = $heap->{q{client}};
    delete $heap->{q{smtp_server_responses}}->{$client};
    carp q{handle_client_disconnect} if ( $debug == 2 );
}

sub handle_client_error {
    my $heap   = $_[HEAP];
    my $client = $heap->{q{client}};
    delete $heap->{q{smtp_server_responses}}->{$client};
    carp q{handle_client_error} if ( $debug == 2 );
}

sub handle_client_flush {
    carp q{handle_client_flush} if ( $debug == 2 );
}

sub return_failed_transaction_log {
    my @transaction_log = (
        q{<- 220 localhost ESMTP POE::Component::Client::SMTP Test Server},
        q{-> HELO Fail},
        q{<- 500 error}
    );

    return \@transaction_log;
}

sub return_transaction_log {
    my @transaction_log = (
        q{<- 220 localhost ESMTP POE::Component::Client::SMTP Test Server},
        q{-> HELO localhost},
        q{<- 250-localhost},
        q{<- 250-PIPELINING},
        q{<- 250-SIZE 250000000},
        q{<- 250-VRFY},
        q{<- 250-ETRN},
        q{<- 250 8BITMIME},
        q{-> MAIL FROM: <george@localhost>},
        q{<- 250 Ok},
        q{-> RCPT TO: <george@localhost,>},
        q{<- 250 Ok},
        q{-> RCPT TO: <root@localhost,>},
        q{<- 250 Ok},
        q{-> RCPT TO: <george.nistorica@localhost,>},
        q{<- 250 Ok},
        q{-> DATA},
        q{<- 354 End data with <CR><LF>.<CR><LF>},
        q{-> To: George Nistorica <george@localhost>
CC: Root <george@localhost>
Bcc: Alter Ego <george.nistorica@localhost>
From: Charlie Root <george@localhost>
Subject: Email test

Sent with } . $POE::Component::Client::SMTP::VERSION . q{

} . qq{\r} . q{.},

        q{<- 250 Ok: queued as 549B14484F},
        q{-> QUIT},
        q{<- 221 Bye}
    );

    return \@transaction_log;
}

sub compare_transaction_logs {
    my $transaction_log          = shift;
    my $expected_transaction_log = shift;

    my $same = 1;

    my ( @actual, @expected );

    foreach my $line ( @{$transaction_log} ) {
        $line =~ s /(\r)|(\n)|(\r\n)//g;
    }
    foreach my $line ( @{$expected_transaction_log} ) {
        $line =~ s /(\r)|(\n)|(\r\n)//g;
    }

    if ( scalar @{$transaction_log} != scalar @{$expected_transaction_log} ) {
        warn q{Transaction logs differ!};
        $same = 0;
    }
    else {
        for ( my $i = 0 ; $i < scalar @{$transaction_log} ; $i++ ) {
            if ( $transaction_log->[$i] ne $expected_transaction_log->[$i] ) {
                $same = 0;
                last;
            }
        }
    }
    return $same;
}
