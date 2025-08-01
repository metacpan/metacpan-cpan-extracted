package Sisimai::Reason::SystemError;
use v5.26;
use strict;
use warnings;
use Sisimai::String;

sub text  { 'systemerror' }
sub description { 'Email returned due to system error on the remote host' }
sub match {
    # Try to match that the given text and regular expressions
    # @param    [String] argv1  String to be matched with regular expressions
    # @return   [Integer]       0: Did not match
    #                           1: Matched
    # @since v4.0.0
    my $class = shift;
    my $argv1 = shift // return 0;

    state $index = [
        'aliasing/forwarding loop broken',
        "can't create user output file",
        'could not load drd for domain',
        'internal error reading data',  # Microsoft
        'internal server error: operation now in progress', # Microsoft
        'interrupted system call',
        'it encountered an error while being processed',
        'it would create a mail loop',
        'local configuration error',
        'local error in processing',
        'loop was found in the mail exchanger',
        'loops back to myself',
        'mail system configuration error',
        'queue file write error',
        'recipient deferred because there is no mdb',
        'remote server is misconfigured',
        'server configuration error',
        'service currently unavailable',
        'system config error',
        'temporary local problem',
        'timeout waiting for input',
        'transaction failed ',
    ];
    state $pairs = [
        ['unable to connect ', 'daemon'],
    ];
    return 1 if grep { rindex($argv1, $_) > -1 } @$index;
    return 1 if grep { Sisimai::String->aligned(\$argv1, $_) } @$pairs;
    return 0;
}

sub true {
    # The bounce reason is system error or not
    # @param    [Sisimai::Fact] argvs   Object to be detected the reason
    # @return   [Integer]               1: is system error
    #                                   0: is not system error
    # @see http://www.ietf.org/rfc/rfc2822.txt
    return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Reason::SystemError - Bounce reason is C<systemerror> or not.

=head1 SYNOPSIS

    use Sisimai::Reason::SystemError;
    print Sisimai::Reason::SystemError->match('5.3.5 System config error'); # 1

=head1 DESCRIPTION

C<Sisimai::Reason::SystemError> checks the bounce reason is C<systemerror> or not. This class is
called only C<Sisimai::Reason> class. This is the error that the email has bounced due to system
error on the remote host such as LDAP connection failures or other internal system errors.

    <kijitora@example.net>:
    Unable to contact LDAP server. (#4.4.3)I'm not going to try again; this
    message has been in the queue too long.

=head1 CLASS METHODS

=head2 C<B<text()>>

C<text()> method returns the fixed string C<systemerror>.

    print Sisimai::Reason::SystemError->text;  # systemerror

=head2 C<B<match(I<string>)>>

C<match()> method returns C<1> if the argument matched with patterns defined in this class.

    print Sisimai::Reason::SystemError->match('5.3.5 System config error'); # 1

=head2 C<B<true(I<Sisimai::Fact>)>>

C<true()> method returns C<1> if the bounce reason is C<systemerror>. The argument must be
C<Sisimai::Fact> object and this method is called only from C<Sisimai::Reason> class.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2022,2024,2025 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

