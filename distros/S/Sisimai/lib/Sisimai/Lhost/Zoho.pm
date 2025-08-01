package Sisimai::Lhost::Zoho;
use parent 'Sisimai::Lhost';
use v5.26;
use strict;
use warnings;

sub description { 'Zoho Mail: https://www.zoho.com/mail/' }
sub inquire {
    # Detect an error from Zoho Mail
    # @param    [Hash] mhead    Message headers of a bounce email
    # @param    [String] mbody  Message body of a bounce email
    # @return   [Hash]          Bounce data list and message/rfc822 part
    # @return   [undef]         failed to decode or the arguments are missing
    # @since v4.1.7
    my $class = shift;
    my $mhead = shift // return undef; return undef unless $mhead->{'x-zohomail'};
    my $mbody = shift // return undef;

    # X-ZohoMail: Si CHF_MF_NL SS_10 UW48 UB48 FMWL UW48 UB48 SGR3_1_09124_42
    # X-Zoho-Virus-Status: 2
    # X-Mailer: Zoho Mail
    state $indicators = __PACKAGE__->INDICATORS;
    state $boundaries = ['Received: from mail.zoho.com by mx.zohomail.com'];
    state $startingof = {'message' => ['This message was created automatically by mail delivery']};
    state $messagesof = {'expired' => ['Host not reachable']};

    my $dscontents = [__PACKAGE__->DELIVERYSTATUS]; my $v = undef;
    my $emailparts = Sisimai::RFC5322->part($mbody, $boundaries);
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my $qprintable = 0;

    for my $e ( split("\n", $emailparts->[0]) ) {
        # Read error messages and delivery status lines from the head of the email to the previous
        # line of the beginning of the original message.
        unless( $readcursor ) {
            # Beginning of the bounce message or message/delivery-status part
            $readcursor |= $indicators->{'deliverystatus'} if index($e, $startingof->{'message'}->[0]) == 0;
            next;
        }
        next if ($readcursor & $indicators->{'deliverystatus'}) == 0 || $e eq "";

        # This message was created automatically by mail delivery software.
        # A message that you sent could not be delivered to one or more of its recip=
        # ients. This is a permanent error.=20
        #
        # kijitora@example.co.jp Invalid Address, ERROR_CODE :550, ERROR_CODE :5.1.=
        # 1 <kijitora@example.co.jp>... User Unknown

        # This message was created automatically by mail delivery software.
        # A message that you sent could not be delivered to one or more of its recipients. This is a permanent error.
        #
        # shironeko@example.org Invalid Address, ERROR_CODE :550, ERROR_CODE :Requested action not taken: mailbox unavailable
        $v = $dscontents->[-1];

        if( Sisimai::String->aligned(\$e, ['@', ' ', 'ERROR_CODE :']) ) {
            # kijitora@example.co.jp Invalid Address, ERROR_CODE :550, ERROR_CODE :5.1.=
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            $v->{'recipient'} = substr($e, 0, index($e, ' '));
            $v->{'diagnosis'} = substr($e, index($e, ' ') + 1,);

            if( substr($v->{'diagnosis'}, -1, 1) eq '=' ) {
                # Quoted printable
                substr($v->{'diagnosis'}, -1, 1, '');
                $qprintable = 1;
            }
            $recipients++;

        } elsif( index($e, '[Status: ') == 0 ) {
            # Expired
            # [Status: Error, Address: <kijitora@6kaku.example.co.jp>, ResponseCode 421, , Host not reachable.]
            if( $v->{'recipient'} ) {
                # There are multiple recipient addresses in the message body.
                push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                $v = $dscontents->[-1];
            }
            my $p1 = index($e, '<');
            my $p2 = index($e, '>', $p1 + 2);
            $v->{'recipient'} = Sisimai::Address->s3s4(substr($e, $p1, $p2 - $p1));
            $v->{'diagnosis'} = $e;
            $recipients++;

        } else {
            # Continued line
            next unless $qprintable;
            $v->{'diagnosis'} .= $e;
        }
    }
    return undef unless $recipients;

    for my $e ( @$dscontents ) {
        $e->{'diagnosis'} =~ y/\n/ /;
        $e->{'diagnosis'} =  Sisimai::String->sweep($e->{'diagnosis'});

        SESSION: for my $r ( keys %$messagesof ) {
            # Verify each regular expression of session errors
            next unless grep { index($e->{'diagnosis'}, $_) > -1 } $messagesof->{ $r }->@*;
            $e->{'reason'} = $r;
            last;
        }
    }
    return {"ds" => $dscontents, "rfc822" => $emailparts->[1]};
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Lhost::Zoho - bounce mail decoder class for Zoho Mail L<https://www.zoho.com/mail/>.

=head1 SYNOPSIS

    use Sisimai::Lhost::Zoho;

=head1 DESCRIPTION

C<Sisimai::Lhost::Zoho> decodes a bounce email which created by Zoho Mail L<https://www.zoho.com/mail/>.
Methods in the module are called from only C<Sisimai::Message>.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::Lhost::Zoho->description;

=head2 C<B<inquire(I<header data>, I<reference to body string>)>>

C<inquire()> method decodes a bounced email and return results as a array reference.
See C<Sisimai::Message> for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2025 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

