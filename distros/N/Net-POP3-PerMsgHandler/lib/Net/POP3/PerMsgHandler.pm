package Net::POP3::PerMsgHandler;

=head1 NAME

Net::POP3::PerMsgHandler - subroutine for per message from POP3 server

=cut

our $VERSION = '0.03';

use warnings;
use strict;

# fail on 5.8.0
#use Exporter 'import';
#our @EXPORT = qw/per_message/;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(per_message);  # symbols to export on request

use Params::Validate;
use Scalar::Defer;
use Net::POP3;
use Net::POP3::PerMsgHandler::Control;
use Net::POP3::PerMsgHandler::Message;

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Net::POP3::PerMsgHandler;
    use YAML::Syck;
    use Perl6::Say;

    my $cfg = LoadFile('config.yml');

    eval {
        my $count = per_message(
            username => $cfg->{username},
            password => $cfg->{password},
            host     => $cfg->{host},
            handler  => sub {
                my ($msg, $ctl) = @_;

                my $email   = $msg->email_mime; # Email::MIME object.
                say "Subject: ".$email->header('Subject');

                $ctl->delete(0) # default
                $ctl->quit(0)   # default
            },
        );
    };

    say $@ if $@; # connection failed etc...

    # Subject: Re: Spam collection
    # Subject: Congratulations, You're a finalist
    # Subject: Software Secret: WARNING Reading this could change your life
    # ...

=head1 EXPORT FUNCTIONS

=head2 per_message

=head1 OPTIONS

=over 4

=item username

required.

=item password

required.

=item host

required.

=item port

optional.

=item timeout

optional.

=item handler

code reference required.

The callback is given two arguments.
The first is a Net::POP3::PerMsgHandler::Message object.
The second is a Net::POP3::PerMsgHandler::Control object.

Executes the callback for each message.

=item debug

optional.

=back

=cut

sub per_message {
    my %p = validate(@_,
        {
            username => 1,
            password => 1,
            host     => 1,
            port     => 0,
            handler  => 1,
            timeout  => 0,
            debug    => 0,
        }
    );

    my @new_args = ($p{host});
    push @new_args, (Timeout  => $p{timeout}) if exists $p{timeout};
    push @new_args, (ResvPort => $p{port})    if exists $p{port};
    push @new_args, (Debug    => $p{debug})   if exists $p{debug};

    my $pop = Net::POP3->new(@new_args);
    die "connection failed." unless defined $pop;
    my $count = $pop->login($p{username}, $p{password});

    die "authentication failed." unless defined $count;
    return $count if $count == 0;

    my $msgnums = $pop->list;
    foreach my $msgnum (keys %$msgnums) {
        my $ctl     = Net::POP3::PerMsgHandler::Control->new({delete=>0, quit=>0});

        my $msg     = Net::POP3::PerMsgHandler::Message->new({});
        $msg->{size}       = lazy { $msgnums->{$msgnum} };
        $msg->{array_ref}  = lazy { $pop->get($msgnum) };
        $msg->{rfc2822}    = lazy { join("", @{ $msg->array_ref }) };
        $msg->{email_mime} = lazy { 
            require Email::MIME or die;
            Email::MIME->new($msg->rfc2822);
        };
        $msg->{email_mime_stripped} = lazy {
            require Email::MIME::Attachment::Stripper;
            Email::MIME::Attachment::Stripper->new($msg->rfc2822)->message;
        };
        $msg->{mail_message} = lazy { 
            require Mail::Message or die;
            Mail::Message->read($msg->array_ref);
        };
        $msg->{mail_message_stripped} = lazy {
            require Mail::Message::Attachment::Stripper or die;
            Mail::Message::Attachment::Stripper
                ->new($msg->mail_message)->message;
        };

        $p{handler}->($msg, $ctl);

        $pop->delete($msgnum) if $ctl->delete;
        last if $ctl->quit;
    }

    $pop->quit;

    return $count;
}

1;

=head1 EXAMPLES

=head2 ex1 - delete message subject starting with SPAM

    my $count = per_message(
        username => $cfg->{username},
        password => $cfg->{password},
        host     => $cfg->{host},
        handler  => sub {
            my ($msg, $ctl) = @_;

            my $email   = $msg->email_mime;
            my $is_spam = $email->header('Subject') =~ m/^SPAM/;

            $ctl->delete(1) if $is_spam;
        },
    );

=head2 ex2 - find specified message and save attached files and delete.

    my $count = per_message(
        username => $cfg->{username},
        password => $cfg->{password},
        host     => $cfg->{host},
        handler  => sub {
            my ($msg, $ctl) = @_;

            my $email = $msg->email_mime;
            return unless $email->body =~ m/\AUUID: 12345/sm;

            for my $part ($email->parts) {
                next unless defined $part->filename;
                $part->body > io( $part->filename );
            }

            $ctl->delete(1);
            $ctl->quit(1);
        },
    );

=head1 SEE ALSO

L<Net::POP3::PerMsgHandler>, L<Net::POP3>, L<Email::MIME>, L<Email::MIME::Attachment::Stripper>, L<Mail::Message>, L<Mail::Message::Attachment::Stripper>

=head1 AUTHOR

bokutin, C<< <bokutin at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 bokutin, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
