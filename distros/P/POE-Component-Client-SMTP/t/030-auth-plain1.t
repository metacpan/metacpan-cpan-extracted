#!/usr/bin/env perl

# Copyright (c) 2007-2009 George Nistorica
# All rights reserved.
# This file is part of POE::Component::Client::SMTP
# POE::Component::Client::SMTP is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# Test PLAIN AUTH

# 	$Id: 030-auth-plain1.t,v 1.4 2009/09/02 08:23:37 UltraDM Exp $	

use strict;
use warnings;
use lib q{../lib};
use Test::More tests => 13;    # including use_ok

# use Test::More qw(no_plan);
use Data::Dumper;
use Carp;

BEGIN { use_ok(q{IO::Socket::INET}); }
BEGIN { use_ok(q{POE}); }
BEGIN { use_ok(q{POE::Wheel::ListenAccept}); }
BEGIN { use_ok(q{POE::Component::Server::TCP}); }
BEGIN { use_ok(q{POE::Component::Client::SMTP}); }

my $smtp_message;
my @recipients;
my $from;
my $debug = 0;

$smtp_message = create_smtp_message();
@recipients   = qw(
  george@localhost
);
$from = q{george@localhost};
my $myhostname         = q{george};
my $poco_said_hostname = undef;
my $plain_auth_string  = q{AGdlb3JnZQBhYnJhY2FkYWJyYQ==};

##### SMTP server vars
my $port = 25252;
my $EOL  = qq{\015\012};

# tests:
my %test = (
    q{test_auth}                                            => 0,
    q{test_no_user}                                         => 0,
    q{test_no_pass}                                         => 0,
    q{test_mechanism_takes_precedence_over_wrong_host}      => 0,
    q{test_wrong_host}                                      => 0,
    q{test_no_user_takes_precedence_over_wrong_port}        => 0,
    q{test_invalid_mechanism_takes_precedence_over_no_user} => 0,
);

my @smtp_server_responses = (
    q{220 localhost ESMTP POE::Component::Client::SMTP Test Server},
    qq{250-localhost$EOL}
      . qq{250-STARTTLS$EOL}
      . qq{250-PIPELINING$EOL}
      . qq{250-8BITMIME$EOL}
      . qq{250-SIZE 32000000$EOL}
      . qq{250-AUTH=CRAM-MD5 DIGEST-MD5 LOGIN PLAIN NTLM$EOL}
      .    # support broken clients
      q{250 AUTH=CRAM-MD5 DIGEST-MD5 LOGIN PLAIN NTLM}
    ,      # don't want to break my unbroken client :D
    q{235 ok, go ahead (#2.0.0)},
    q{250 ok},
    q{250 ok},
    q{354 go ahead},
    q{250 ok 1173791708 qp 32453},
    q{221 localhost}
);

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

POE::Session->create(
    q{inline_states} => {
        q{_start}             => \&start_session,
        q{_stop}              => \&stop_session,
        q{send_mail}          => \&spawn_pococlsmt,
        q{pococlsmtp_success} => \&smtp_send_success,
        q{pococlsmtp_failure} => \&smtp_send_failure,
    },
);

POE::Kernel->run();

is( $test{test_auth},    1, q{Auth OK} );
is( $test{test_no_user}, 1, q{No User} );
is( $test{test_no_pass}, 1, q{No Pass} );
is( $test{test_mechanism_takes_precedence_over_wrong_host},
    1, q{Mech precedes wrong host} );
is( $test{test_wrong_host}, 1, q{Wrong host} );
is( $test{test_no_user_takes_precedence_over_wrong_port},
    1, q{No User precedes wrong port} );
is( $test{test_invalid_mechanism_takes_precedence_over_no_user},
    1, q{Invalid Mech precedes no User} );
is( $poco_said_hostname, $myhostname, q{MyHostname} );
diag(q{Test PLAIN AUTH});

sub start_session {
    $_[KERNEL]->yield(q{send_mail});
}

sub spawn_pococlsmt {

# $from, $recipients, $server, $port, $smtp_message, $myhostname, $alias_append, $mech, $user, $pass
# Auth OK
    pococlsmtp_create(
        $from,         \@recipients, q{localhost}, $port,
        $smtp_message, q{Auth OK},   $myhostname,  q{auth_ok},
        q{PLAIN},      q{george},    q{abracadabra},
    );

    # No User
    pococlsmtp_create(
        $from,         \@recipients, q{localhost}, $port,
        $smtp_message, q{No User},   $myhostname,  q{No_User},
        q{PLAIN},,     q{abracadabra},
    );

    # No Pass
    pococlsmtp_create(
        $from,         \@recipients, q{localhost}, $port,
        $smtp_message, q{No Pass},   $myhostname,  q{no_pass},
        q{PLAIN},      q{george},,
    );

    # Mech precedes wrong host
    pococlsmtp_create(
        $from,                       \@recipients,
        q{thereisnosuchserverthere}, $port,
        $smtp_message,               q{Mech precedes wrong host},
        $myhostname,                 q{Mech_precedes_wrong_host},
        q{PLAIN1},                   q{george},
        q{abracadabra},
    );

    # Wrong host
    pococlsmtp_create(
        $from,                       \@recipients,
        q{thereisnosuchserverthere}, $port,
        $smtp_message,               q{Wrong host},
        $myhostname,                 q{Wrong_host},
        q{PLAIN},                    q{george},
        q{abracadabra},
    );

    # No User precedes wrong port
    pococlsmtp_create(
        $from, \@recipients,
        q{localhost}, ( $port + 1 ),
        $smtp_message, q{No User precedes wrong port},
        $myhostname,   q{No_User_precedes_wrong_port},
        q{PLAIN},,
        q{abracadabra},
    );

    # Invalid Mech precedes no User
    pococlsmtp_create(
        $from,         \@recipients,
        q{localhost},  $port,
        $smtp_message, q{Invalid Mech precedes no User},
        $myhostname,   q{Invalid_Mech_precedes_no_User},
        q{PLAIN1},     '',
        q{abracadabra},
    );

}

sub stop_session {

    # stop server
    $_[KERNEL]->call( q{smtp_server} => q{shutdown} );
}

sub smtp_send_success {
    my ( $kernel, $arg0, $arg1 ) = @_[ KERNEL, ARG0, ARG1 ];
    print q{ARG0, }, Dumper($arg0), qq{\nARG1, }, Dumper($arg1), qq{\n}
      if $debug;

    if ( $arg0 eq q{Auth OK} ) {
        $test{test_auth} = 1;
    }
    elsif ( $arg0 eq q{No User}
        and $arg1->{q{Configure}} eq
        q{ERROR: You want AUTH but no USER/PASS given!} )
    {

        $test{test_no_user} = 0;
    }
    elsif ( $arg0 eq q{No Pass}
        and $arg1->{q{Configure}} eq
        q{ERROR: You want AUTH but no USER/PASS given!} )
    {
        $test{test_no_pass} = 0;

    }
    elsif ( $arg0 eq q{Mech precedes wrong host}
        and $arg1->{q{Configure}} eq
        q{ERROR: Method unsupported by Component version: }
        . $POE::Component::Client::SMTP::VERSION )
    {

        $test{test_mechanism_takes_precedence_over_wrong_host} = 0;

    }
    elsif ( $arg0 eq q{Wrong host}
        and exists( $arg1->{q{POE::Wheel::SocketFactory}} ) )
    {
        $test{test_wrong_host} = 0;

    }
    elsif ( $arg0 eq q{No User precedes wrong port}
        and $arg1->{q{Configure}} eq
        q{ERROR: You want AUTH but no USER/PASS given!} )
    {
        $test{test_no_user_takes_precedence_over_wrong_port} = 0;

    }
    elsif ( $arg0 eq q{Invalid Mech precedes no User}
        and $arg1->{q{Configure}} eq
        q{ERROR: Method unsupported by Component version: }
        . $POE::Component::Client::SMTP::VERSION )
    {

        $test{test_invalid_mechanism_takes_precedence_over_no_user} = 0;

    }
    else {
        warn qq{What the hell! $arg0\/$arg1};
    }

}

sub smtp_send_failure {
    my ( $kernel, $arg0, $arg1 ) = @_[ KERNEL, ARG0, ARG1 ];
    print qq{\nARG0, }, $arg0, q{\nARG1, }, Dumper($arg1) if $debug;
    if ( $arg0 eq q{Auth OK} ) {
        $test{test_auth} = 0;
    }
    elsif ( $arg0 eq q{No User}
        and $arg1->{q{Configure}} eq
        q{ERROR: You want AUTH but no USER/PASS given!} )
    {

        $test{test_no_user} = 1;
    }
    elsif ( $arg0 eq q{No Pass}
        and $arg1->{q{Configure}} eq
        q{ERROR: You want AUTH but no USER/PASS given!} )
    {
        $test{test_no_pass} = 1;

    }
    elsif ( $arg0 eq q{Mech precedes wrong host}
        and $arg1->{q{Configure}} eq
        q{ERROR: Method unsupported by Component version: }
        . $POE::Component::Client::SMTP::VERSION )
    {

        $test{test_mechanism_takes_precedence_over_wrong_host} = 1;

    }
    elsif ( $arg0 eq q{Wrong host}
        and exists( $arg1->{q{POE::Wheel::SocketFactory}} ) )
    {
        $test{test_wrong_host} = 1;

    }
    elsif ( $arg0 eq q{No User precedes wrong port}
        and $arg1->{q{Configure}} eq
        q{ERROR: You want AUTH but no USER/PASS given!} )
    {
        $test{test_no_user_takes_precedence_over_wrong_port} = 1;

    }
    elsif ( $arg0 eq q{Invalid Mech precedes no User}
        and $arg1->{q{Configure}} eq
        q{ERROR: Method unsupported by Component version: }
        . $POE::Component::Client::SMTP::VERSION )
    {

        $test{test_invalid_mechanism_takes_precedence_over_no_user} = 1;

    }
    else {
        warn qq{What the hell! $arg0\/$arg1};
    }

}

sub create_smtp_message {
    my $body = <<EOB;
To: George Nistorica <george\@localhost>
Bcc: George Nistorica <george\@localhost>
CC: Alter Ego <root\@localhost>
From: Charlie Root <root\@localhost>
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

    if ( $input =~ /^(helo|ehlo|mail from:|rcpt to:|data|\.|quit|auth)/io ) {
        if ( $input =~ /^(ehlo|helo)\s(.*)$/io ) {
            $poco_said_hostname = $2 if defined $2;
        }
        elsif ( $input eq q{PLAIN AGdlb3JnZQBhYnJhY2FkYWJyYQ==} ) {
            $test{test_auth} = 1;
        }
        print qq{CLIENT SAID: "$input"\n} if $debug;
        $heap->{'client'}->put( shift @smtp_server_responses );
    }
}

sub handle_client_connect {
    $_[HEAP]->{'client'}->put( shift @smtp_server_responses );
}

sub handle_client_disconnect {
}

sub handle_client_error {
}

sub handle_client_flush {
}

sub pococlsmtp_create {
    my (
        $from,         $recipients, $server,     $port,
        $smtp_message, $context,    $myhostname, $alias_append,
        $mech,         $user,       $pass
    ) = @_;

    POE::Component::Client::SMTP->send(
        From         => $from,
        To           => $recipients,
        SMTP_Success => 'pococlsmtp_success',
        SMTP_Failure => 'pococlsmtp_failure',
        Server       => $server,
        Port         => $port,
        Body         => $smtp_message,
        Context      => $context,
        Timeout      => 20,
        MyHostname   => $myhostname,                          # to test
        Alias        => 'poco_smtp_alias_' . $alias_append,

        #         Debug => 1,
        Auth => {
            mechanism => $mech,
            user      => $user,
            pass      => $pass,
        }
    );
}
