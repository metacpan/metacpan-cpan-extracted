#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

BEGIN {
    # use the lib directory relative to ourself
    use FindBin;
    use lib "$FindBin::Bin/../lib";

    # for building email(s)
    use MIME::Lite;

    # since we're going to be a daemon ...
    use Proc::Daemon;
    use Proc::PID::File;

    # somewhere to send stuff
    use Sys::Syslog qw( :DEFAULT :standard :macros );

    # our in to the database ...
    use Parley::Schema;
}

use version; our $VERSION = qv('0.0.1');

# whether we should be exiting
our $exit = 0;

# prepare syslog for use
openlog(
    q{parley_email_engine},
    q{ndelay,pid},
    LOG_USER
)
    or die $!;
syslog( LOG_INFO, q{script started} )
    or die $!;

# have we been asked to stop running?
if (@ARGV && $ARGV[0] eq q{stop}) {
    # we need to quit!

    # get the pid file ...
    my $pid = Proc::PID::File->running(
        debug   => 0,
        name    => q{parley_email_engine},
        dir     => q{/tmp},
    );
    if (not $pid) {
        syslog( LOG_INFO, qq{daemon not running!} );
        exit;
    }

    # send a kill signal
    kill( 2, $pid );
    syslog( LOG_INFO, qq{STOP signal sent!\n} );
    exit;
}

# connect to the schema
my $schema = schema_connect();

# daemon
my $pid;
if ($pid = Proc::Daemon::Fork) { # parent
    # nothing here
}
else { # child
    Proc::Daemon::Init;

    openlog(
        q{parley_email_engine},
        q{ndelay,pid},
        LOG_USER
    )
        or die $!;
    syslog( LOG_INFO, q{child process created} );

    # how to deal with given signals
    $SIG{TERM}  = sub { $exit = 1 };
    $SIG{INT}   = sub { $exit = 1 };
    $SIG{CHLD}  = q{IGNORE};
    $SIG{HUP}   = q{IGNORE};

    my $status_ok;
    $status_ok = open(STDOUT, '>>', '/tmp/parley_email_engine.log');
    if (not $status_ok) {
        syslog( LOG_ERR, "failed to reopen STDOUT: $!" );
        exit;
    }
    $status_ok = open(STDERR, '>&STDOUT');
    if (not $status_ok) {
        syslog( LOG_ERR, "failed to re-open STDERR to STDOUT: $!" );
        exit;
    }

    # make sure we aren't already running
    if (Proc::PID::File->running(
            debug   => 0,
            name    => q{parley_email_engine},
            dir     => q{/tmp},
        )
    ) {
        syslog( LOG_INFO, qq{Already Running!} );
        exit;
    }

    while (1) {
        child_process($schema);
        sleep(5);
    }
}

sub child_process {
    my $schema = shift;

    # get the oldest unsent email in the queue
    my $rs = $schema->resultset('EmailQueue')->search(
        {
            attempted_delivery => 0,
        },
        {
            # oldest first
            order_by    => 'queued ASC',
            # one result
            rows        => 1,

            # some prefetching to make things a little easier on the database
            prefetch => [
                'recipient',
                'cc',
                'bcc'
            ],
        }
    );

    # if we have anything waiting to be sent ...
    if ($rs->count()) {
        my $queue_item = $rs->first();
        send_email( $queue_item );
    }

    # have we been asked to stop?
    if ($exit) {
        syslog(
            LOG_INFO,
            q{STOP signal recieved}
        );
        exit;
    }
}

sub schema_connect {
    my $schema;
    eval {
        $schema = Parley::Schema->connect(
            q{dbi:Pg:dbname=parley},
            q{parley},
            undef,
            { RaiseError => 0, PrintError => 0 },
        );
    };
    if ($@) {
        syslog( LOG_INFO, $@ );
        exit;
    }
    if (not defined $schema) {
        syslog( LOG_INFO, $! );
        exit;
    }

    return $schema;
}

sub send_email {
    my $queue_item = shift;
    my ($email);

    # are we text/plain or multipart/alternative?
    if (defined $queue_item->html_content()) {
        $email = build_multipart_email( $queue_item );
    }
    else {
        $email = build_text_email( $queue_item );
    }

    # print the email out for now, no need to send anything
    $email->send();
    syslog( LOG_INFO, $email->as_string() );
    # update the table to say we've attempted delivery
    $queue_item->attempted_delivery(1);
    $queue_item->update();

    return;
}

sub _common_mail_options {
    my $queue_item = shift;

    my %options = (
        From            => $queue_item->sender(),
        To              => nice_to_header( $queue_item->recipient() ),
        Subject         => $queue_item->subject(),
        'X-Application' => qq{parley_email_engine ($VERSION)},
    );

    return \%options;
}


sub build_text_email {
    my $queue_item = shift;
    my ($msg);

    # create a straight-forward text email
    $msg = MIME::Lite->new(
        %{ _common_mail_options($queue_item) },

        Type        => 'TEXT',
        Data        => $queue_item->text_content(),
        Encoding    => 'quoted-printable',
    )
        or die $!;

    return $msg;
}

sub build_multipart_email {
    my $queue_item = shift;
    my ($msg);

    # create the multipart container
    $msg = MIME::Lite->new(
        %{ _common_mail_options($queue_item) },

        Type    => 'multipart/alternative',
    )
        or die $!;

    # add the text part
    $msg->attach(
        Type    => 'text/plain',
        Data    => $queue_item->text_content(),
    );
    # add the html part
    $msg->attach(
        Type    => 'text/html',
        Data    => $queue_item->html_content(),
    );

    return $msg;
}



sub nice_to_header {
    my $recipient = shift;

    my $string =
          $recipient->first_name()
        . q{ }
        . $recipient->last_name()
        . q{ <}
        . $recipient->email()
        . q{>}
    ;

    return $string;
}
