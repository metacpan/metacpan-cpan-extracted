package Sisimai::Reason::TooManyConn;
use v5.26;
use strict;
use warnings;

sub text  { 'toomanyconn' }
sub description { 'SMTP connection rejected temporarily due to too many concurrency connections to the remote host' }
sub match {
    # Try to match that the given text and regular expressions
    # @param    [String] argv1  String to be matched with regular expressions
    # @return   [Integer]       0: Did not match
    #                           1: Matched
    # @since v4.1.26
    my $class = shift;
    my $argv1 = shift // return 0;

    state $index = [
        'all available ips are at maximum connection limit',    # SendGrid
        'connection rate limit exceeded',
        'exceeds per-domain connection limit for',
        'has exceeded the max emails per hour ',
        'throttling failure: daily message quota exceeded',
        'throttling failure: maximum sending rate exceeded',
        'too many connections',
        'too many connections from your host.', # Microsoft
        'too many concurrent smtp connections', # Microsoft
        'too many errors from your ip',         # Free.fr
        'too many recipients',                  # ntt docomo
        'too many smtp sessions for this host', # Sendmail(daemon.c)
        'trop de connexions, ',
        'we have already made numerous attempts to deliver this message',
    ];
    return 1 if grep { rindex($argv1, $_) > -1 } @$index;
    return 0;
}

sub true {
    # Blocked due to that connection rate limit exceeded
    # @param    [Sisimai::Fact] argvs   Object to be detected the reason
    # @return   [Integer]               1: Too many connections(blocked)
    #                                   0: Not many connections
    # @since v4.1.26
    # @see http://www.ietf.org/rfc/rfc2822.txt
    my $class = shift;
    my $argvs = shift // return 0;

    return 1 if $argvs->{'reason'} eq 'toomanyconn';
    return 1 if (Sisimai::SMTP::Status->name($argvs->{'deliverystatus'}) || '') eq 'toomanyconn';
    return __PACKAGE__->match(lc $argvs->{'diagnosticcode'});
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::Reason::TooManyConn - Bounced due to that too many connections.

=head1 SYNOPSIS

    use Sisimai::Reason::TooManyConn;
    print Sisimai::Reason::TooManyConn->match('Connection rate limit exceeded');    # 1

=head1 DESCRIPTION

C<Sisimai::Reason::TooManyConn> checks the bounce reason is C<toomanyconn> or not. This class is
called only C<Sisimai::Reason> class.

This is the error that the SMTP connection was rejected temporarily due to too many concurrency
connections to the remote server. This reason has added in Sisimai 4.1.26.

    <kijitora@example.ne.jp>: host mx02.example.ne.jp[192.0.1.20] said:
        452 4.3.2 Connection rate limit exceeded. (in reply to MAIL FROM command)

=head1 CLASS METHODS

=head2 C<B<text()>>

C<text()> method returns the fixed string C<toomanyconn>.

    print Sisimai::Reason::TooManyConn->text;  # toomanyconn

=head2 C<B<match(I<string>)>>

C<match()> method returns C<1> if the argument matched with patterns defined in this class.

    print Sisimai::Reason::TooManyConn->match('Connection rate limit exceeded');  # 1

=head2 C<B<true(I<Sisimai::Fact>)>>

C<true()> method returns C<1> if the bounce reason is C<toomanyconn>. The argument must be
C<Sisimai::Fact> object and this method is called only from C<Sisimai::Reason> class.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2021,2024,2025 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

