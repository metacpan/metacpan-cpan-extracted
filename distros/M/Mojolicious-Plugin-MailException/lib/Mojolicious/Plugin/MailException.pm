=head1 NAME

Mojolicious::Plugin::MailException - Mojolicious plugin to send crash information by email

=head1 SYNOPSIS

    package MyServer;
    use Mojo::Base 'Mojolicious';

    sub startup {
        my ($self) = @_;

        $self->plugin(MailException => {
            from    => 'robot@my.site.com',
            to      => 'mail1@my.domain.com, mail2@his.domain.com',
            subject => 'My site crashed!',
            headers => {
                'X-MySite' => 'crashed'
            },

            stack   => 10
        });
    }

=head1 DESCRIPTION

The plugin catches all exceptions, packs them into email and sends
them to email.

There are some plugin options:

=over

=item from

From-address for email (default B<root@localhost>)

=item to

To-address(es) for email (default B<webmaster@localhost>)

=item subject

Subject for crash email

=item headers

Hash with headers that have to be added to mail

=item stack

Stack size for crash mail. Default is C<20>.

=item maildir

This option saves (stores) messages in the maildir instead of
sending them. If you catch too many crashes, then their sending
probably uses too much of the CPU, so by using this option you
may save your messages instead of sending them.

The option is ignored if C<send> option is defined.

=item send

Subroutine that can be used to send the mail, example:

    sub startup {
        my ($self) = @_;

        $self->plugin(MailException => {
            send => sub {
                my ($mail, $exception) = @_;

                $mail->send;    # prepared MIME::Lite object
            }
        });
    }

In the function You can send email by yourself and (or) prepare and
send Your own mail (sms, etc) message using B<$exception> object.
See L<Mojo::Exception>.

=back

The plugin provides additional method (helper) B<mail_exception>.

    $cx->mail_exception('my_error', { 'X-Add-Header' => 'value' });

You can use the helper to raise exception with additional mail headers.

=head1 VCS

The plugin is placed on
L<github|https://github.com/dr-co/libmojolicious-plugin-mail_exception>.

=head1 COPYRIGHT AND LICENCE

 Copyright (C) 2012 by Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2012 by Roman V. Nikolaev <rshadow@rambler.ru>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

package Mojolicious::Plugin::MailException;

our $VERSION = '0.24';
use 5.008008;
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';
use Data::Dumper;
use Mojo::Exception;
use Carp;
use MIME::Lite;
use MIME::Words ':all';
use File::Spec::Functions 'rel2abs', 'catfile';


my $mail_prepare = sub {
    my ($e, $conf, $self, $from, $to, $headers, $stack_depth) = @_;
    my $subject = $conf->{subject} || 'Caught exception';
    $subject .= ' (' . $self->req->method . ': ' .
        $self->req->url->to_abs->to_string . ')';
    utf8::encode($subject) if utf8::is_utf8 $subject;
    $subject = encode_mimeword $subject, 'B', 'utf-8';


    my $text = '';
    $text .= "Exception\n";
    $text .= "~~~~~~~~~\n";


    $text .= $e->message;
    $text .= "\n";

    my $maxl = eval { length $e->lines_after->[-1][0]; };
    $maxl ||= 5;
    $text .= sprintf "   %*d %s\n", $maxl, @{$_}[0,1] for @{ $e->lines_before };
    $text .= sprintf " * %*d %s\n", $maxl, @{ $e->line }[0,1] if $e->line->[0];
    $text .= sprintf "   %*d %s\n", $maxl, @{$_}[0,1] for @{ $e->lines_after };

    if (@{ $e->frames }) {
        my $no = 0;
        $text .= "\n";
        $text .= "Stack\n";
        $text .= "~~~~~\n";
        for (@{ $e->frames }) {
            $no++;
            if ($no > $stack_depth) {
                $text .= "    ...\n";
                last;
            }
            $text .= sprintf "    %s: %d\n", @{$_}[1,2];
        }
    }


    if (eval { $self->session; scalar keys %{ $self->session } }) {
        local $Data::Dumper::Indent = 1;
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Useqq = 1;
        local $Data::Dumper::Deepcopy = 1;
        local $Data::Dumper::Maxdepth = 0;

        $text .= "\n";
        $text .= "Session\n";
        $text .= "~~~~~~~\n";
        $text .= Dumper($self->session);
    }

    eval { utf8::encode($text) if utf8::is_utf8 $text };


    my $mail = MIME::Lite->new(
        From    => $from,
        To      => $to,
        Subject => $subject,
        Type    => 'multipart/mixed',
    );


    $mail->attach(
        Type    => 'text/plain; charset=utf-8',
        Data    => $text
    );

    $text  = "Request\n";
    $text .= "~~~~~~~\n";
    my $req = $self->req->to_string;
    $req =~ s/^/    /gm;
    $text .= $req;

    $mail->attach(
        Type        => 'text/plain; charset=utf-8',
        Filename    => 'request.txt',
        Disposition => 'inline',
        Data        => $text
    );

    $mail->add($_ => $headers->{$_}) for keys %$headers;
    return $mail;
};

use Fcntl;

my $store_maildir = sub {
    my ($dir, $mail) = @_;
            
    unless (-x $dir and -d $dir and -w $dir) {
        warn "Directory `$dir' does not exists or accessible\n";
        return;
    }

    my $now = time;
    for (my $i = 0; $i < 1000; $i++) {
        my $fname = catfile $dir, sprintf '%d.%05d', $now, $i;

        my $fh;

        if (sysopen $fh, $fname, O_CREAT | O_WRONLY) {
            binmode $fh => ':raw';

            my $str = $mail->as_string;
            if (utf8::is_utf8 $str) {
                utf8::encode $str;
            }
            print $fh $str;
            close $fh;
            last;
        }
    }
};


sub register {
    my ($self, $app, $conf) = @_;

    my $stack_depth = $conf->{stack} || 20;

    my $cb = $conf->{send};
    
    unless ('CODE' eq ref $cb) {
        $cb = sub { $_[0]->send };
        if (my $dir = $conf->{maildir}) {
            warn "Directory `$dir' does not exists or accessible"
                unless -x $dir and -d $dir and -w $dir;
            $dir = rel2abs $dir;
            $cb = sub { $store_maildir->($dir, shift)  };
        }
    }
    croak "Usage: app->plugin('ExceptionMail'[, send => sub { ... })'"
        unless 'CODE' eq ref $cb;

    my $headers = $conf->{headers} || {};
    my $from = $conf->{from} || 'root@localhost';
    my $to   = $conf->{to} || 'webmaster@localhost';

    croak "headers must be a HASHREF" unless 'HASH' eq ref $headers;

    $app->hook(around_dispatch => sub {
        my ($next, $c) = @_;

        my $e;
        {
            local $SIG{__DIE__} = sub {

                ($e) = @_;

                unless (ref $e and $e->isa('Mojo::Exception')) {
                    my @caller = caller;

                    $e =~ s/at\s+(.+?)\s+line\s+(\d+).*//s;

                    $e = Mojo::Exception->new(
                        sprintf "%s at %s line %d\n", "$e", @caller[1,2]
                    );
                    $e->trace(1);
                    $e->inspect if $e->can('inspect');
                }


                CORE::die $e;
            };

            eval { $next->() };
        }

        return unless $@;

        unless ($e) {
            $e = Mojo::Exception->new($@);
            $e->trace(1);
            $e->inspect if $e->can('inspect');
        }

        my $hdrs = $headers;

        $hdrs = { %$hdrs, %{ $e->{local_headers} } }
            if ref $e->{local_headers};

        my $mail = $mail_prepare->( $e, $conf, $c, $from, $to, $hdrs, $stack_depth );

        eval {
            local $SIG{CHLD} = 'IGNORE';
            local $SIG{__DIE__};
            $cb->($mail, $e);
            1;
        } or warn $@;

        # propagate Mojo::Exception
        die $e;
    });

    $app->helper(mail_exception => sub {
        my ($self, $et, $hdrs) = @_;
        my @caller = caller 1;
        $et ||= 'exception';
        my $e = Mojo::Exception->new(
            sprintf '%s at %s line %d', $et, @caller[1,2]
        );
        $e->trace(2);
        $e->inspect if $e->can('inspect');

        $e->{local_headers} = $hdrs;
        CORE::die $e;
    });
}

1;
