package Sisimai::Reason::NotAccept;
use v5.26;
use strict;
use warnings;

sub text  { 'notaccept' }
sub description { 'Delivery failed due to a destination mail server does not accept any email' }
sub match {
    # Try to match that the given text and regular expressions
    # @param    [String] argv1  String to be matched with regular expressions
    # @return   [Integer]       0: Did not match
    #                           1: Matched
    # @since v4.0.0
    my $class = shift;
    my $argv1 = shift // return 0;

    # Destination mail server does not accept any message
    state $index = [
        'does not accept mail (nullmx)',
        'host/domain does not accept mail', # iCloud
        'host does not accept mail',        # Sendmail
        'mail receiving disabled',
        'name server: .: host not found',   # Sendmail
        'no mx record found for domain=',   # Oath(Yahoo!)
        'no route for current request',
        'smtp protocol returned a permanent error',
    ];
    return 1 if grep { rindex($argv1, $_) > -1 } @$index;
    return 0;
}

sub true {
    # Remote host does not accept any message
    # @param    [Sisimai::Fact] argvs   Object to be detected the reason
    # @return   [Integer]               1: Not accept
    #                                   0: Accept
    # @since v4.0.0
    # @see http://www.ietf.org/rfc/rfc2822.txt
    my $class = shift;
    my $argvs = shift // return 0; my $reply = int $argvs->{'replycode'} || 0;

    # SMTP Reply Code is 521, 554 or 556
    return 1 if $argvs->{'reason'} eq 'notaccept' || $reply == 521 || $reply == 556;
    return 0 if $argvs->{'command'} ne 'MAIL';
    return __PACKAGE__->match(lc $argvs->{'diagnosticcode'});
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Reason::NotAccept - Bounce reason is C<notaccept> or not.

=head1 SYNOPSIS

    use Sisimai::Reason::NotAccept;
    print Sisimai::Reason::NotAccept->match('domain does not exist:');   # 1

=head1 DESCRIPTION

C<Sisimai::Reason::NotAccept> checks the bounce reason is C<notaccept> or not. This class is called
only C<Sisimai::Reason> class.

This is the error that the destination mail server does (or can) not accept any email. In many case,
the server is high load or under the maintenance. Sisimai will set C<notaccept> to the reason of the
email bounce if the value of C<Status:> field in the bounce email is C<5.3.2> or the value of SMTP
reply code is C<556>.

=head1 CLASS METHODS

=head2 C<B<text()>>

C<text()> method returns the fixed string C<notaccept>.

    print Sisimai::Reason::NotAccept->text;  # notaccept

=head2 C<B<match(I<string>)>>

C<match()> method returns C<1> if the argument matched with patterns defined in this class.

    print Sisimai::Reason::NotAccept->match('domain does not exist:');   # 1

=head2 C<B<true(I<Sisimai::Fact>)>>

C<true()> method returns C<1> if the bounce reason is C<notaccept>. The argument must be C<Sisimai::Fact>
object and this method is called only from C<Sisimai::Reason> class.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2016,2018,2020-2025 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

