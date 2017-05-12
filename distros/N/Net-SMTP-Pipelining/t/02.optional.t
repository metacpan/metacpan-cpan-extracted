use Test::More;

use strict;
use warnings;
use Net::SMTP;
use Net::SMTP::Pipelining;
use Fatal qw(open close);

my $dbg = 0;
my $config = "t/optional.config";

SKIP: {
    plan skip_all => qq(Not running automatically, set NSPipeliningInteractive="yes" to enable interactive test (see README))
        unless ($ENV{NSPipeliningInteractive} && $ENV{NSPipeliningInteractive} eq "yes");
    plan tests => 10;
    my ($server,$from,$to);

    if (-e $config) {
        open (my $fh,"<",$config);
        ($server, $from,$to) = (<$fh>);
        close $fh;
        chomp ($server,$from,$to);
    } else {

        diag "\nThe following test will send a total of 7 emails through an email server you specify";
        diag "Please make sure to choose both the sender and recipient address in such a way that";
        diag "no third parties are inconvenienced. Ideally both of these will just be accepted by";
        diag "your mail server and the message then discarded.";
        diag "\nDo you want to run the test against a live SMTP server? [y/N]";

        my $runtest = "n";
        $runtest = (<STDIN>);
        chomp $runtest;
        if ($runtest !~ m/^y(?:es)?$/i) {
            skip qq(Skipping test as requested);
        }

        diag "Please enter a server name or IP address (or hit return to use the local host):";
        $server = (<STDIN>);
        chomp $server;
        $server ||= "localhost";

        diag "Please enter the email address the test mails are supposed to be sent FROM:";
        $from = (<STDIN>);
        chomp $from;

        diag "Please enter the email address the test mails are supposed to be sent TO:";
        $to = (<STDIN>);
        chomp $to;
    }

my $message = <<'END_OF_MESSAGE';
From: $from
To: $to
Subject: This is a test for Net::SMTP::PIPELINING, please ignore

test
END_OF_MESSAGE

    my $smtp;
    ok( $smtp = Net::SMTP::Pipelining->new($server,
                                           Debug => $dbg),
        "Successful SMTP connection to mail server $server made");

    # Send three pipelined messages
    for (1..3) {
        ok($smtp->pipeline({ mail => $from,
                             to => $to,
                             data => $message
                        }), "Pipelined message");
    }

    ok ($smtp->pipe_flush(),"Pipe flush successful");

    # Do a normal send to make sure we're still in sync
    $smtp->mail($from);
    $smtp->to($to);
    $smtp->data();
    $smtp->datasend($message);

    ok($smtp->dataend(),"Manual message send successful");

    # Send another three pipelined mails
    for (1..3) {
        ok($smtp->pipeline({ mail => $from,
                             to => $to,
                             data => $message
                        }), "Pipelined message");
    }

    ok ($smtp->pipe_flush(),"Pipe flush successful");
}
