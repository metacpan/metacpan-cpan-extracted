package Sisimai::Reason::Filtered;
use v5.26;
use strict;
use warnings;
use Sisimai::SMTP::Command;

sub text  { 'filtered' }
sub description { 'Email rejected due to a header content after SMTP DATA command' }
sub match {
    # Try to match that the given text and regular expressions
    # @param    [String] argv1  String to be matched with regular expressions
    # @return   [Integer]       0: Did not match
    #                           1: Matched
    # @since v4.0.0
    my $class = shift;
    my $argv1 = shift // return 0;

    state $index = [
        'because the recipient is only accepting mail from specific email addresses',   # AOL Phoenix
        'bounced address',  # SendGrid|a message to an address has previously been Bounced.
        'due to extended inactivity new mail is not currently being accepted for this mailbox',
        'has restricted sms e-mail',    # AT&T
        'is not accepting any mail',
        "message filtered",
        'message rejected due to user rules',
        'not found recipient account',
        'refused due to recipient preferences', # Facebook
        'resolver.rst.notauthorized',   # Microsoft Exchange
        'this account is protected by',
        'user not found',   # Filter on MAIL.RU
        'user refuses to receive this mail',
        'user reject',
        'we failed to deliver mail because the following address recipient id refuse to receive mail',  # Willcom
        'you have been blocked by the recipient',
    ];
    return 1 if grep { rindex($argv1, $_) > -1 } @$index;
    return 0;
}

sub true {
    # Rejected by domain or address filter ?
    # @param    [Sisimai::Fact] argvs   Object to be detected the reason
    # @return   [Integer]               1: is filtered
    #                                   0: is not filtered
    # @since v4.0.0
    # @see http://www.ietf.org/rfc/rfc2822.txt
    my $class = shift;
    my $argvs = shift // return 0; return 1 if $argvs->{'reason'} eq 'filtered';

    my $tempreason = Sisimai::SMTP::Status->name($argvs->{'deliverystatus'}) || '';
    return 0 if $tempreason eq 'suspend';

    require Sisimai::Reason::UserUnknown;
    my $issuedcode = lc $argvs->{'diagnosticcode'};
    my $thecommand = $argvs->{'command'} || '';
    if( $tempreason eq 'filtered' ) {
        # Delivery status code points "filtered".
        return 1 if Sisimai::Reason::UserUnknown->match($issuedcode);
        return __PACKAGE__->match($issuedcode);

    } else {
        # The value of "reason" isn't "filtered" when the value of "command" is an SMTP command to
        # be sent before the SMTP DATA command because all the MTAs read the headers and the entire
        # message body after the DATA command.
        return 0 if grep { $argvs->{'command'} eq $_ } Sisimai::SMTP::Command->ExceptDATA->@*;
        return 1 if __PACKAGE__->match($issuedcode);
        return Sisimai::Reason::UserUnknown->match($issuedcode);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Reason::Filtered - Bounce reason is C<filtered> or not.

=head1 SYNOPSIS

    use Sisimai::Reason::Filtered;
    print Sisimai::Reason::Filtered->match('550 5.1.2 User reject');   # 1

=head1 DESCRIPTION

C<Sisimai::Reason::Filtered> checks the bounce reason is C<filtered> or not. This class is called
only C<Sisimai::Reason> class.

This is the error that an email has been rejected by a header content after SMTP C<DATA> command.
In Japanese cellular phones, the error will incur that the sender's email address or the domain is
rejected by recipient's email configuration. Sisimai will set C<filtered> to the reason of email
bounce if the value of C<Status:> field in the bounce email is C<5.2.0> or C<5.2.1>.

This error reason is almost the same as C<UserUnknown>.

    ... while talking to mfsmax.ntt.example.ne.jp.:
    >>> DATA
    <<< 550 Unknown user kijitora@ntt.example.ne.jp
    554 5.0.0 Service unavailable

=head1 CLASS METHODS

=head2 C<B<text()>>

C<text()> method returns the fixed string C<filtered>.

    print Sisimai::Reason::Filtered->text;  # filtered

=head2 C<B<match(I<string>)>>

C<match()> method returns C<1> if the argument matched with patterns defined in this class.

    print Sisimai::Reason::Filtered->match('550 5.1.2 User reject');   # 1

=head2 C<B<true(I<Sisimai::Fact>)>>

C<true()> method returns C<1> if the bounce reason is C<filtered>. The argument must be C<Sisimai::Fact>
object and this method is called only from Sisimai::Reason class.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2018,2020-2025 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut
