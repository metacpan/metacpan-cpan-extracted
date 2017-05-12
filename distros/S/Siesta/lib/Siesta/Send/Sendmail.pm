# $Id: Sendmail.pm 1429 2003-10-16 16:39:28Z richardc $
package Siesta::Send::Sendmail;
use strict;

sub description { "Sends a mail using sendmail" };

=head1 NAME

Siesta::Send::Sendmail - send a Siesta::Message using sendmail

=head1 DESCRIPTION

A extension to siesta that allows you to send mail using the local
sendmail executable.

=head1 USAGE

  # This module should not really
  # be used outside the siesta system

  my $sender = Siesta::Send::Sendmail->new();
  my $mail   = Siesta::Message->new(*\STDIN);
  $sender->send($mail);

=head1 SEE ALSO

L<Siesta>, L<Siesta::Message> , L<Siesta::Send>

=cut

sub new { bless {}, $_[0] }

sub send {
    my $self    = shift;
    my $message = shift;
    my %args    = @_;

    my $from = $args{'from'} || $message->from;
    my $to   = $args{'to'}   || ( $message->to )[0];
    my @to   = ref $to eq 'ARRAY' ? @$to : ( $to );
    return 1 unless @to;    # guard against no recipients

    # according to MBM one shouldn't try and give sendmail more than
    # about 80 recipients at the same time. And frankly, he should
    # know.
    my $sendmail_limit = 80;

    while (my @local = splice @to, 0, $sendmail_limit) {
        my $pid = open my $sendmail, '|-';
        die "couldn't fork $!" unless defined $pid;
        unless ($pid) {
            exec '/usr/sbin/sendmail', '-oi', '-f', $from, @local;
            die "exec failed $!";
        }
        print $sendmail $message->as_string;
        close $sendmail
          or die "problem closing sendmail $! $?";
    }

    return 1;
}

1;
