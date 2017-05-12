#!/usr/bin/env perl

# Copyright (c) 2005 - 2009 George Nistorica
# All rights reserved.
# This file is part of POE::Component::Client::SMTP
# POE::Component::Client::SMTP is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# 	$Id: 045-messagefile-filehandle.t,v 1.5 2009/09/02 08:23:37 UltraDM Exp $

use strict;
use warnings;

# check that MessageFile slurps the file
# check that FileHandle slurps the file
# TODO:
# check that MessageFile to a file that can't be read returns error event
# check that Body parameter is disabled when one of the above is set

use lib q{../lib};
use Test::More tests => 7;    # including use_ok
use Data::Dumper;
use Carp;
use Symbol qw( gensym );

BEGIN { use_ok(q{IO::Socket::INET}); }
BEGIN { use_ok(q{POE}); }
BEGIN { use_ok(q{POE::Wheel::ListenAccept}); }
BEGIN { use_ok(q{POE::Component::Server::TCP}); }
BEGIN { use_ok(q{POE::Component::Client::SMTP}); }

my $message_file = q{t/email_message.txt};

# the tests we're running
my %test = (
    q{filehandle}  => 0,
    q{messagefile} => 0,
);

my $debug = 0;

my @recipients =
  ( q{george@localhost}, q{root@localhost}, q{george.nistorica@localhost}, );
my $from = q{george@localhost};

##### SMTP server vars
my $port                  = 25252;
my $EOL                   = qq{\015\012};
my @smtp_server_responses = (
    qq{220 localhost ESMTP POE::Component::Client::SMTP Test Server},
    qq{250-localhost$EOL}
      . qq{250-PIPELINING$EOL}
      . qq{250-SIZE 250000000$EOL}
      . qq{250-VRFY$EOL}
      . qq{250-ETRN$EOL}
      . qq{250 8BITMIME},
    qq{250 Ok},                                 # mail from
    qq{250 Ok},                                 # rcpt to:
    qq{250 Ok},                                 # rcpt to:, cc
    qq{250 Ok},                                 # rctp to:, bcc
    qq{354 End data with <CR><LF>.<CR><LF>},    # data
    qq{250 Ok: queued as 549B14484F},           # end data
    qq{221 Bye},                                # quit
);

# create the SMTP server session
POE::Component::Server::TCP->new(
    q{Port}               => $port,
    q{Address}            => q{localhost},
    q{Domain}             => AF_INET,
    q{Alias}              => q{smtp_server},
    q{Error}              => \&error_handler,               # Optional.
    q{ClientInput}        => \&handle_client_input,         # Required.
    q{ClientConnected}    => \&handle_client_connect,       # Optional.
    q{ClientDisconnected} => \&handle_client_disconnect,    # Optional.
    q{ClientError}        => \&handle_client_error,         # Optional.
    q{ClientFlushed}      => \&handle_client_flush,         # Optional.
    q{ClientFilter} => POE::Filter::Line->new( q{Literal} => $EOL ),
    q{ClientInputFilter}     => POE::Filter::Line->new( q{Literal} => $EOL ),
    q{ClientOutputFilter}    => POE::Filter::Line->new( q{Literal} => $EOL ),
    q{ClientShutdownOnError} => 1,                                 #
);

# create the pococlsmtp master session
# 4 of them :)

foreach my $key ( keys %test ) {
    if ( $key eq q{filehandle} ) {
        my $handle = open_file($message_file);
        POE::Session->create(
            q{inline_states} => {
                q{_start}             => \&start_session,
                q{_stop}              => \&stop_session,
                q{send_mail}          => \&spawn_pococlsmt,
                q{pococlsmtp_success} => \&smtp_send_success,
                q{pococlsmtp_failure} => \&smtp_send_failure,
            },
            q{heap} => {
                q{test}   => $key,
                q{handle} => $handle,
              }    # store the test name for each session

        );
    }
    else {
        POE::Session->create(
            q{inline_states} => {
                q{_start}             => \&start_session,
                q{_stop}              => \&stop_session,
                q{send_mail}          => \&spawn_pococlsmt,
                q{pococlsmtp_success} => \&smtp_send_success,
                q{pococlsmtp_failure} => \&smtp_send_failure,
            },
            q{heap} =>
              { q{test} => $key, }    # store the test name for each session
        );

    }
}

POE::Kernel->run();

# run tests
foreach my $key ( keys %test ) {
    is( $test{$key}, 1, $key );
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

        # check that body is deleted
        q{Body}    => q{This message should not exist},
        q{Context} => q{test context},
        q{Debug}   => 0,
    );

    if ( $heap->{q{test}} eq q{filehandle} ) {
        $parameters{q{MyHostname}} = q{filehandle};
        $parameters{q{FileHandle}} = $heap->{q{handle}};
    }
    elsif ( $heap->{q{test}} eq q{messagefile} ) {
        $parameters{q{MyHostname}}  = q{messagefile};
        $parameters{q{MessageFile}} = $message_file;
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
}

sub smtp_send_failure {
    my ( $arg0, $arg1, $arg2, $heap ) = @_[ ARG0, ARG1, ARG2, HEAP ];
    print q{SMTP_Failure: ARG0, }, Dumper($arg0), qq{\nARG1, }, Dumper($arg1),
      qq{\n}
      if $debug;
    fail(q{Unexpectedly got SMTP failure!});
}

sub error_handler {
    my ( $syscall_name, $error_number, $error_string ) = @_[ ARG0, ARG1, ARG2 ];
    die qq{SYSCALL: $syscall_name, ERRNO: $error_number, ERRSTR: $error_string};
}

sub handle_client_input {
    my ( $heap, $input ) = @_[ HEAP, ARG0 ];
    carp q{handle_client_input} if ( $debug == 2 );
    my $client      = $heap->{q{client}};
    my $end_message = 0;

    if ( $input =~ /^(ehlo|helo|mail from:|rcpt to:|data|\.|quit)/io ) {
        if ( $input =~ /^(ehlo|helo)\s(\w+)/io ) {
            $heap->{q{test}}->{$client} = $2;
        }
        $heap->{q{client}}
          ->put( shift @{ $heap->{q{smtp_server_responses}}->{$client} } );
    }
    elsif ( $input =~ /^$/ ) {
        $heap->{q{client_message}}->{$client} .= qq{$input\n}
          if ( not $end_message );

        # there are "empty lines coming in ...
    }
    else {

        $heap->{q{client_message}}->{$client} .= qq{$input\n}
          if ( not $end_message );
        if ( $input =~ /ok/io ) {
            $end_message = 1;
        }
    }
}

sub handle_client_connect {
    my $heap   = $_[HEAP];
    my $client = $heap->{q{client}};
    @{ $heap->{q{smtp_server_responses}}->{$client} } = @smtp_server_responses;
    $heap->{q{client_message}}->{$client} = q{};
    $heap->{q{client}}
      ->put( shift @{ $heap->{q{smtp_server_responses}}->{$client} } );
}

sub handle_client_disconnect {
    my $heap   = $_[HEAP];
    my $client = $heap->{q{client}};
    delete $heap->{q{smtp_server_responses}}->{$client};
    delete $heap->{q{client_message}}->{$client};
    carp q{handle_client_disconnect} if ( $debug == 2 );
}

sub handle_client_error {
    my $heap   = $_[HEAP];
    my $client = $heap->{q{client}};
    delete $heap->{q{smtp_server_responses}}->{$client};
    chomp $heap->{q{client_message}}->{$client};
    if ( $heap->{q{client_message}}->{$client} eq message_file() ) {
        $test{ $heap->{q{test}}->{$client} } = 1;
    }
    else {
        $test{ $heap->{q{test}}->{$client} } = 0;
        print qq{Not the same!\n};
    }
    delete $heap->{q{client_message}}->{$client};
    carp q{handle_client_error} if ( $debug == 2 );
}

sub handle_client_flush {
    carp q{handle_client_flush} if ( $debug == 2 );
}

sub message_file {
    my $message_file = << "EOF";
To: George Nistorica <george\@localhost>
CC: Root <george\@localhost>
Bcc: Alter Ego <george.nistorica\@localhost>
From: Charlie Root <george\@localhost>
Subject: Email test

Ok ...
EOF

    return $message_file;
}

sub open_file {
    my $filename = shift;
    my $handle   = gensym();

    if ( -e $filename ) {
        open $handle, q{<}, qq{$filename} || die qq{$!};
    }
    else {
        die qq{$filename does not exist!\n};
    }

    return $handle;
}
