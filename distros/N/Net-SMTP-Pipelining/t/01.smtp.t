use Test::More tests => 74;

use strict;
use warnings;
use IO::Socket;
use POSIX qw( WNOHANG );
use Fatal qw(open close );

my (%hasnt);
my $gotfile;
my $lockfile = "t/lockmail";

BEGIN {
    use_ok( 'Net::SMTP::Pipelining' );
    eval 'use Net::Server::Mail::ESMTP';
    $hasnt{netservermail} = 1 if $@;
    eval 'use Test::Warn';
    $hasnt{testwarn} = 1 if $@;
    $gotfile = "t/gotmail";
    unlink $gotfile;
}


END {
    unlink $gotfile;
}

can_ok("Net::SMTP::Pipelining","pipeline",
       "pipe_flush",
       "pipe_codes",
       "pipe_messages",
       "pipe_recipients",
       "pipe_rcpts_succeeded",
       "pipe_rcpts_failed",
       "pipe_errors",
       "pipe_sent",
   );

# Find an unused port, starting at 2525;
my $smtp_port = 2525;
my $dbg = 0;

while (my $sock = IO::Socket::INET->new(
                                        PeerAddr => "127.0.0.1",
                                        PeerPort => $smtp_port,
                                        Proto => "TCP"
                                    )) {
    $sock->close();
    $smtp_port++;
}

my @address = ( undef, q(blackhole1@example.com), q(blackhole2@example.com), q(blackhole3@example.com) );

my $message = <<'END_OF_MESSAGE';
From: <blackhole>
Subject: This is a test for Net::SMTP::PIPELINING

test
END_OF_MESSAGE

my $fail_message = <<'END_OF_FAIL';
From: <blackhole>
Subject: This is a test for Net::SMTP::PIPELINING

reject me
END_OF_FAIL

SKIP: {
    skip "Net::Server::Mail not installed",72 if exists $hasnt{netservermail};
    # Fork and run the server as a child
    my $pid;
    if ($pid=fork()) {
        $SIG{CHLD} = sub { 1 while -1 != waitpid -1, WNOHANG; };
        sleep 1;
    } elsif (defined $pid) {
        ### Run mail server here
        _smtp_daemon();
        exit;
    } else {
        die("Cannot fork");
    }

    my $smtp;

    ok( $smtp = Net::SMTP::Pipelining->new("127.0.0.1",
                                           Port => $smtp_port,
                                           Debug => $dbg), "Successful SMTP connection to non-pipelining server made");

  SKIP: {
        skip "Test::Warn not installed",3 if exists $hasnt{testwarn};
        warning_like { ok(!$smtp->pipeline({ mail => $address[0],
                                             to => $address[0],
                                             data => $message,
                        }),"Failed if server does not advertise pipelining support"); }
        qr/^Server does not support PIPELINING/, "Gives correct warning for non-pipelining server";
        like ( $smtp->pipe_errors()->[0]{message},
               qr/^Server does not support PIPELINING, banner was/,
               "Correct error in pipe_errors");
    }
    ok($smtp->quit(), "Connection closed");

    ok( $smtp = Net::SMTP::Pipelining->new("127.0.0.1",
                                           Port => $smtp_port,
                                           Debug => $dbg), "Successful SMTP connection made");
    isa_ok($smtp,"Net::SMTP::Pipelining");

    # Successful pipelining sends
    for (1..3) {
        my $thismess = $message;
        $thismess =~ s/test/test message $_/g;
        ok($smtp->pipeline({ mail => $address[1],
                             to => $address[$_],
                             data => $thismess,
                        }), "Pipelined message $_");

        my $scodes = $_ == 1 ? [250,250,354] : [ 250,250,250,354];
        is_deeply( $smtp->pipe_codes(), $scodes, "Expected server return codes match");

        my $res = $smtp->pipe_messages();
        my @smgs;

        # Net::Server::Mail changed the handling of email addresses in version 0.18
        # The following is a fudge to work around this and avoid spurious test warnings
        if ($res->[0][0] =~ m/sender </ ||  $res->[1][0] =~ m/sender </  ) {
            @smgs = ( [ qq(message sent\n) ],
                      [ qq(sender <$address[1]> OK\n) ],
                      [ qq(recipient <$address[$_]> OK\n) ],
                      [ qq(Start mail input; end with <CRLF>.<CRLF>\n) ],
                  );
        } else {
            @smgs = ( [ qq(message sent\n) ],
                      [ qq(sender $address[1] OK\n) ],
                      [ qq(recipient $address[$_] OK\n) ],
                      [ qq(Start mail input; end with <CRLF>.<CRLF>\n) ],
                  );
        }
        shift @smgs if ($_ == 1);

        is_deeply( $res , \@smgs,
                   qq(Expected server return messages match)
              );

        is_deeply( $smtp->pipe_sent(),
                   [
                    qq(MAIL FROM: <$address[1]>),
                    qq(RCPT TO: <$address[$_]>),
                    qq(DATA),
                    $thismess,
                ], qq(Expected sent commands match)
              );

        my $srcpt = $_ == 1 ? [] : [$address[$_-1]];
        is_deeply ($smtp->pipe_recipients(),
                   {
                    accepted => [ $address[$_] ],
                    failed   => [],
                    succeeded => $srcpt ,
                },
                   "Recipients correctly reported");

        # This is somewhat convoluted, but seems the best way to reliably wait for Net::Server::Mail
        # to finish writing the received mail without always having to wait for an inordinate amount
        # of time.
        my $toolong = 5;
        my $totalwait = 0;
        while (-e $lockfile && $totalwait<$toolong) {
            sleep 1;
            $totalwait += 1;
        }

        ok (-e $gotfile,"mail has been received");
        open (my $gh,"<",$gotfile);
        my @cont = (<$gh>);
        like ($cont[-2],qr/test message $_/,"Correct message body retrieved");
        close $gh;
        unlink $gotfile or warn "Can't unlink $gotfile: $!";
    }

    # Testing correct state after pipe_flush
    ok($smtp->pipe_flush(), "pipe_flush successful");

    is_deeply ($smtp->pipe_codes,[250], "Correct codes after pipe flush");
    is_deeply ($smtp->pipe_messages(),[[qq(message sent\n)]], "Correct message after pipe flush");
    is_deeply ($smtp->pipe_sent(),[],"No sent lines after pipe flush");
    is_deeply ($smtp->pipe_recipients(),
               {
                accepted => [],
                failed => [],
                succeeded => [ $address[3] ],
            }, "Successful recipient after pipe_flush correctly reported");

    is_deeply ($smtp->pipe_sent(),[],"Sent queue empty after pipe_flush");

    is_deeply ($smtp->pipe_messages(),[ [ qq(message sent\n) ],],"Correct message seen after pipe_flush");

    # Test failing sends
    # Invalid sender
    ok(!-e $gotfile, "no mail received before fail");

    ok (!$smtp->pipeline({ mail => q(fail@example.com),
                           to => $address[2],
                           data => $message,
                           }), "Message with an invalid sender fails");

    is_deeply ($smtp->pipe_recipients(),
               {
                 accepted => [],
                 failed   => [  $address[2] ],
                 succeeded => [],
                 },
               "Recipients for invalid sender correctly reported");

    is_deeply ($smtp->pipe_errors(),
               [
                {
                 command  => q(MAIL FROM: <fail@example.com>),
                 code     => 550,
                 message => [ qq(Invalid from address\n) ],
                 },
                {
                 command  => qq(RCPT TO: <$address[2]>),
                 code     => 503,
                 message => [ qq(Bad sequence of commands\n) ],
                 },
                {
                 command  => qq(DATA),
                 code     => 503,
                 message => [ qq(Bad sequence of commands\n) ],
                 }
                ], "Reported MAIL FROM error correctly" );

    ok(!-e $gotfile, "no mail received");

    # Invalid recipient
    ok (!$smtp->pipeline({ mail => $address[1],
                           to => q(failit@example.com),
                           data => $message,
                           }), "Message with an invalid recipient fails");

    is_deeply ($smtp->pipe_recipients(),
               {
                 accepted => [],
                 failed   => [  q(failit@example.com) ],
                 succeeded => [],
                 },
               "Recipients correctly reported for invalid recipient");
    is_deeply ($smtp->pipe_errors(),
               [
                {
                 command => q(RCPT TO: <failit@example.com>),
                 code => 550,
                 message => [ "Invalid to address\n" ],
             },
               {
                command => q(DATA),
                code    => 503,
                message => [ qq(Bad sequence of commands\n) ],
                }
            ], "Reported single RCPT error correctly" );

    ok(!-e $gotfile,"no mail received");

    # One invalid recipient mixed with valid ones
    # This will return false but a send happen anyway
    ok (!$smtp->pipeline({ mail => $address[1],
                           to => [ $address[1], q(fail@example.com), $address[2], q(morefail@example.com), $address[3] ],
                           data => $message,
                      }), "Message with an invalid recipient amongst several working ones fails");

    is_deeply ($smtp->pipe_errors(),
               [
                {
                 command => q(RCPT TO: <fail@example.com>),
                 code => 550,
                 message => [ "Invalid to address\n" ],
             },
                {
                 command => q(RCPT TO: <morefail@example.com>),
                 code => 550,
                 message => [ "Invalid to address\n" ],
             },
            ], "Reported invalid recipients mixed with good ones correctly");

    is_deeply ($smtp->pipe_recipients(),
               {
                failed => [
                           q(fail@example.com),
                           q(morefail@example.com)
                       ],
                 accepted  => [ $address[1], $address[2], $address[3] ],
                 succeeded => [],
                 },
               "Recipients correctly reported");

    is_deeply ($smtp->pipe_rcpts_failed(),[
                                           q(fail@example.com),
                                           q(morefail@example.com)
                                       ],"Correct recipients reported with pipe_rcpts_failed");
    is_deeply ($smtp->pipe_rcpts_succeeded(),[],"Correctly reported no recipients as succeeded");

    ok ($smtp->pipe_flush(),"pipe flush returns true after some recipients failed");

    is_deeply ($smtp->pipe_recipients(),
               {
                failed => [],
                 accepted  => [],
                 succeeded => [ $address[1], $address[2], $address[3] ],
                 },
               "Recipients correctly reported after pipe_flush");

    is_deeply ($smtp->pipe_rcpts_failed(),[],"Correctly reported no recipients as failed");

    is_deeply ($smtp->pipe_rcpts_succeeded(),
               [ $address[1], $address[2], $address[3] ],
               "Correctly reported with pipe_rcpts_succeeded");

    ok(-e $gotfile,"Mail was received");
    unlink $gotfile or warn "Can't unlink $gotfile: $!";

    # Invalid message body
    ok($smtp->pipeline({ mail => $address[1],
                         to => $address[1],
                         data => $fail_message,
                         }), "Message with rejected body");

    is_deeply ($smtp->pipe_errors(),[],"No error messages before pipe_flush with rejected body");

    ok(!$smtp->pipe_flush(),"pipe_flush returns false on failed data send");

    is_deeply ($smtp->pipe_errors(),
               [
                {
                 command => q(DATA),
                 code => 550,
                 message => [ qq(Rejected\n), qq(With a multiline response\n) ],
                 },
                ], "Reported rejected message body correctly");

    ok(!-e $gotfile,"no mail received");

    # Another invalid message body, this time without flushing
    ok($smtp->pipeline({ mail => $address[1],
                         to => $address[1],
                         data => $fail_message,
                         }), "Message with rejected body");

    is_deeply ($smtp->pipe_errors(),[],"No error messages before next message with rejected body");

    # valid send which nevertheless reports false (because of previous rejected message body)
    ok(!$smtp->pipeline({ mail => $address[2],
                          to => $address[2],
                          data => $message,
                          }), "False because previous message failed");

    is_deeply ($smtp->pipe_recipients(),
               {
                accepted  => [ $address[2] ],
                failed    => [ $address[1] ],
                succeeded => [],
            },
               "Recipients correctly reported with previous message failed");

    # This means that a "DATA" in the errors means the previous message fails,
    # be sure to mention this in the docs!
    is_deeply ($smtp->pipe_errors(),
               [
                {
                 command => q(DATA),
                 code => 550,
                 message => [ qq(Rejected\n), qq(With a multiline response\n) ],
             },
            ], "Reported rejected message body of previous message correctly");

    ok ($smtp->pipe_flush(),"pipe_flush succeeds");

    # Working send with multiple recipients
    ok($smtp->pipeline({ mail => $address[1],
                         to => [ $address[1], $address[2] ],
                         data => $message,
                         }), "Message with multiple recipients");

    ok($smtp->pipe_flush(), "pipe_flush successful");

    # Mixing with normal Net::SMTP methods
    is_deeply ($smtp->message(),[ "message sent\n" ],"Correct last server message recorded");

    is ($smtp->code(),250,"Correct message code received");

    $smtp->mail($address[1]);
    $smtp->to($address[2]);
    $smtp->data();
    $smtp->datasend(q(From: <blackhole>\nmessage));

    ok($smtp->dataend(),"Manual message send successful");

    like ($smtp->message(),qr/message sent\n/,"Correct last server message recorded");

    is ($smtp->code(),250,"Correct message code received");

    $smtp->quit();
    kill 1, $pid;
    wait;

    # From here on it's the Net::Server::Mail setup required to deal with the above tests
    sub _smtp_daemon {
        my $server = IO::Socket::INET->new( Listen => 1, LocalPort => $smtp_port, ReuseAddr => 1 );
        my $conn;
        while($conn = $server->accept) {
            my $smtp = new Net::Server::Mail::ESMTP socket => $conn;
            $smtp->register('Net::Server::Mail::ESMTP::PIPELINING');
            $smtp->set_callback(EHLO => \&_daemon_ehlo);
            $smtp->set_callback(MAIL => \&_daemon_mailfrom);
            $smtp->set_callback(RCPT => \&_daemon_rcpt);
            $smtp->set_callback(DATA => \&_daemon_data);
            $smtp->process();
        }
    }

    my $con = 0;

    sub _daemon_ehlo {
        my ($session,$ehlo) = @_;

        if ($ehlo =~ m/localhost/) {
            if ($con++ > 0) {
                return (1,250,"mx.example.com Service ready\nPIPELINING");
            } else {
                return (1,250,"mx.example.com Service ready");
            }
        } else {
            return (undef,350,"don't like you");
        }
    }

    sub _daemon_mailfrom {
        my ($session,$from)=@_;
        return (0,550,"Invalid from address") if ($from !~ m/blackhole\d\@example.com/);
        open (my $fh,">",$lockfile);
        print {$fh} $lockfile;
        close $fh;
        return 1;
    }

    sub _daemon_rcpt {
        my ($session,$rcpt) = @_;
        return (0,550,"Invalid to address") if ($rcpt !~ m/blackhole\d\@example.com/);
        return 1;
    }

    sub _daemon_data {
        my ($session,$data) = @_;
        return (0,550,"Rejected\nWith a multiline response") if ($$data =~ m/reject me/);
        open (my $fh,">",$gotfile);
        print {$fh} $$data;
        close $fh;
        unlink $lockfile or die "Can't unlink $lockfile: $!";
        return 1;
    }
}

