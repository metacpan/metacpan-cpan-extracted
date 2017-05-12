package Socialtext::MailArchive;
use strict;
use warnings;
use Carp qw/croak/;

=head1 NAME

Socialtext::MailArchive - Archive mail into a workspace

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  use Socialtext::MailArchive;
  my $ma = Socialtext::MailArchive->new( rester => $r );
  $ma->archive_mail( $mail_message );

=head1 DESCRIPTION

Socialtext::MailArchive provides an easy way to archive mailing lists into a workspace.  Each message will be put on a separate page (and tagged 'message'), and messages will also be included from a thread page named after the message subject (tagged 'thread').

This module is at this point an experiment to see how email and wikis can integrate.  Whether it's a good idea or not is left up to the reader.

=head1 METHODS

=head2 new

Create a new mail archiver object.  Options are provided as a hash:

=over 4

=item * B<rester> - a Socialtext::Resting object

=back

=cut

sub new {
    my $class = shift;
    my $self = {
        @_,
    };
    croak "rester is mandatory\n" unless $self->{rester};

    bless $self, $class;
    return $self;
}

=head2 archive_mail

Archive a mail message.  A mail message should be passed as a scalar into this method.

=cut

sub archive_mail {
    my $self = shift;
    my $message = shift;
    my $r = $self->{rester};

    my ($msg_id, $subj, $lean_msg) = $self->_parse_message($message);

    $r->put_page($msg_id, $lean_msg);
    $r->put_pagetag($msg_id, 'message');
    $r->put_pagetag($msg_id, "Subject: $subj");

    $self->_update_thread($subj, $msg_id);
}

sub _update_thread {
    my $self = shift;
    my $subj = shift;
    my $msg_id = shift;
    my $r = $self->{rester};

    my $thread = $r->get_page($subj);
    $thread = '' if $r->response->code eq '404';
    $thread .= "----\n" if $thread;
    $thread .= "{include [$msg_id]}\n";

    $r->put_page( $subj, $thread );
    $r->put_pagetag( $subj, 'thread' );
}

sub _parse_message {
    my $self = shift;
    my $msg = shift;

    my $subj = 'No subject - ' . localtime;
    my ($from, $date) = ('Unknown', scalar localtime);

    my @lines = split /\n/, $msg;
    my @lean_message;
    my $in_headers = 1;
    for my $l (@lines) {
        if ($msg =~ /^Subject: (.+)$/m) {
            $subj = $1;
            $subj =~ s/^Re: //i;
            $subj =~ s/^\[[^\]]+\]\s+//;
            $subj =~ s/^Re: //i;
        }
        # eg: Luke Closs - Test Mail - Mon, 5 Feb 2007 13:14:19
        if ($msg =~ /^From: (.+)$/m) {
            $from = $1;
            $from =~ s/\s+<.+//;
        }
        if ($msg =~ /^Date: (.+)$/m) {
            $date = $1;
        }

        if ($in_headers) {
            for my $header (qw(Date To Subject From)) {
                next unless $l =~ /^$header: /m;
                $l =~ s/@/ at /;
                push @lean_message, $l;
            }
            if ($l eq '') {
                $in_headers = 0;
                push @lean_message, $l;
            }
        }
        else {
            push @lean_message, $l;
        }
    }

    return ( 
        "$from - $subj - $date", 
        $subj,
        join( "\n", @lean_message ) . "\n",
    );
}

=head1 AUTHOR

Luke Closs, C<< <luke.closs at socialtext.com> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Luke Closs, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
