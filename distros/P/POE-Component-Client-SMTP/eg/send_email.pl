#!/usr/bin/env perl
use strict;
use warnings;

# Copyright (c) 2005 - 2008 George Nistorica
# All rights reserved.
# This file is part of POE::Component::Client::SMTP
# POE::Component::Client::SMTP is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.  See the LICENSE
# file that comes with this distribution for more details.

# 	$Id: send_email.pl,v 1.3 2008/05/12 12:23:45 UltraDM Exp $

my $sender      = q{replace@with.email.address.net};
my $recipient   = q{replace@with.email.address.net};
my $smtp_server = q{your.relay.mail.server.net};
my $smtp_port   = 25;

# use the library from the kit
# remove the line below if you're using the system wide installed
# PoCoClSMTP
use lib q{../lib};

use Data::Dumper;    # I always include this ;-)
use Email::MIME::Creator;
use IO::All;

use POE;
use POE::Component::Client::SMTP;

# main()
POE::Session->create(
    q{inline_states} => {
        q{_start}            => \&start_main_session,
        q{send_mail}         => \&send_mail_from_main_session,
        q{send_mail_success} => \&send_mail_success,
        q{send_mail_failure} => \&send_mail_failure,
        q{_stop}             => \&stop_main_session,
    }
);

POE::Kernel->run();

# done

sub start_main_session {

    #fire the things up
    $_[KERNEL]->yield(q{send_mail});
}

sub send_mail_from_main_session {
    my $email = create_message();

    # Note that you are prohibited by RFC to send bare LF characters in e-mail
    # messages; consult:
    # http://cr.yp.to/docs/smtplf.html
    $email =~ s/\n/\r\n/g;

    POE::Component::Client::SMTP->send(
        q{From}         => $sender,
        q{To}           => $recipient,
        q{Server}       => $smtp_server,
        q{Port}         => $smtp_port,
        q{Body}         => $email,
        q{SMTP_Success} => q{send_mail_success},
        q{SMTP_Failure} => q{send_mail_failure},
    );
}

sub send_mail_success {
    print qq{Success\n};
}

sub send_mail_failure {
    my $fail = $_[ARG1];
    print Dumper($fail);
    print qq{Failure\n};
}

sub stop_main_session {
    print qq{End ...\n};
}

# Email Creation Part
# rather lame email creation.
# You may use any method that suits you (I usually create the messages by hand
# ;-) )
sub create_message {
    my $attachment_file = qq{text_mail_attachment.txt};

    my $email;
    my @parts;

    @parts = (
        Email::MIME->create(
            q{attributes} => {
                q{filename}     => q{text.txt},
                q{content_type} => q{text/plain},
                q{encoding}     => q{quoted-printable},
                q{name}         => q{Example attachment},
            },
            q{body} => io($attachment_file)->all,
        ),
        Email::MIME->create(
            q{attributes} => {
                q{content_type} => q{text/plain},
                q{disposition}  => q{attachment},
                q{charser}      => q{US-ASCII},
            },
            q{body} => q{Howdy!},
        ),
    );

    $email = Email::MIME->create(
        q{header} => [
            q{From} => $sender,
            q{To}   => $recipient,
        ],
        q{parts} => [@parts],
    );

    # return the message
    return $email->as_string;
}

