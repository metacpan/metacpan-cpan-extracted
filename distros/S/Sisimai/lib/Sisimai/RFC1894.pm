package Sisimai::RFC1894;
use v5.26;
use strict;
use warnings;

sub FIELDINDEX {
    return [qw|
        Action Arrival-Date Diagnostic-Code Final-Recipient Last-Attempt-Date Original-Recipient
        Received-From-MTA Remote-MTA Reporting-MTA Status X-Actual-Recipienet X-Original-Message-ID
    |];
}
sub FIELDTABLE {
    # Return pairs that a field name and key name defined in Sisimai::Lhost class
    return {
        'action'            => 'action',
        'arrival-date'      => 'date',
        'diagnostic-code'   => 'diagnosis',
        'final-recipient'   => 'recipient',
        'last-attempt-date' => 'date',
        'original-recipient'=> 'alias',
        'received-from-mta' => 'lhost',
        'remote-mta'        => 'rhost',
        'reporting-mta'     => 'rhost',
        'status'            => 'status',
        'x-actual-recipient'=> 'alias',
    };
}

sub match {
    # Check the argument matches with a field defined in RFC3464
    # @param    [String] argv0 A line including field and value defined in RFC3464
    # @return   [Integer]      0: did not matched, 1,2: matched
    # @since v4.25.0
    my $class = shift;
    my $argv0 = shift                      || return undef;
    my $label = __PACKAGE__->label($argv0) || return undef;

    state $fieldnames = {
        # https://tools.ietf.org/html/rfc3464#section-2.2
        #   Some fields of a DSN apply to all of the delivery attempts described by that DSN. At
        #   most, these fields may appear once in any DSN. These fields are used to correlate the
        #   DSN with the original message transaction and to provide additional information which
        #   may be useful to gateways.
        #
        #   The following fields (not defined in RFC 3464) are used in Sisimai
        #     - X-Original-Message-ID: <....> (GSuite)
        #
        #   The following fields are not used in Sisimai:
        #     - Original-Envelope-Id
        #     - DSN-Gateway
        'arrival-date'          => ':',
        'received-from-mta'     => ';',
        'reporting-mta'         => ';',
        'x-original-message-id' => '@',

        # https://tools.ietf.org/html/rfc3464#section-2.3
        #   A DSN contains information about attempts to deliver a message to one or more recipi-
        #   ents. The delivery information for any particular recipient is contained in a group of
        #   contiguous per-recipient fields. Each group of per-recipient fields is preceded by a
        #   blank line.
        #
        #   The following fields (not defined in RFC 3464) are used in Sisimai
        #     - X-Actual-Recipient: RFC822; ....
        #
        #   The following fields are not used in Sisimai:
        #     - Will-Retry-Until
        #     - Final-Log-ID
        'action'                => 'e',
        'diagnostic-code'       => ';',
        'final-recipient'       => ';',
        'last-attempt-date'     => ':',
        'original-recipient'    => ';',
        'remote-mta'            => ';',
        'status'                => '.',
        'x-actual-recipient'    => ';',
    };

    return 0 unless exists $fieldnames->{ $label };
    return 0 unless index($argv0, $fieldnames->{ $label }) > 0;
    return 1;
}

sub label {
    # Returns a field name as a lqbel from the given string
    # @param    [String] argv0 A line including field and value defined in RFC3464
    # @return   [String]       Field name as a label
    # @since v4.25.15
    my $class = shift;
    my $argv0 = shift || return undef;
    return lc((split(':', $argv0, 2))[0]) || undef;
}

sub field {
    # Check the argument is including field defined in RFC3464 and return values
    # @param    [String] argv0 A line including field and value defined in RFC3464
    # @return   [Array]        ['field-name', 'value-type', 'Value', 'field-group']
    # @since v4.25.0
    my $class = shift;
    my $argv0 = shift || return undef;

    state $correction = {
        'action' => { 'deliverable' => 'delivered', 'expired' => 'delayed', 'failure' => 'failed' },
    };
    state $fieldgroup = {
        'original-recipient'    => 'addr',
        'final-recipient'       => 'addr',
        'x-actual-recipient'    => 'addr',
        'diagnostic-code'       => 'code',
        'arrival-date'          => 'date',
        'last-attempt-date'     => 'date',
        'received-from-mta'     => 'host',
        'remote-mta'            => 'host',
        'reporting-mta'         => 'host',
        'action'                => 'list',
        'status'                => 'stat',
        'x-original-message-id' => 'text',
    };
    state $captureson = {
        'addr' => qr/\A((?:Original|Final|X-Actual)-Recipient):[ ](.+?);[ ](.+)/,
        'code' => qr/\A(Diagnostic-Code):[ ](.+?);[ ](.*)/,
        'date' => qr/\A((?:Arrival|Last-Attempt)-Date):[ ](.+)/,
        'host' => qr/\A((?:Received-From|Remote|Reporting)-MTA):[ ](.+?);[ ](.+)/,
        'list' => qr/\A(Action):[ ](delayed|deliverable|delivered|expanded|expired|failed|failure|relayed)/i,
        'stat' => qr/\A(Status):[ ]([245][.]\d+[.]\d+)/,
        'text' => qr/\A(X-Original-Message-ID):[ ](.+)/,
       #'text' => qr/\A(Final-Log-ID|Original-Envelope-Id):[ ]*(.+)/,
    };

    my $label = __PACKAGE__->label($argv0) || return undef;
    my $group = $fieldgroup->{ $label }    || return undef;
    return undef unless exists $captureson->{ $group };

    my $table = ['', '', '', ''];
    my $match = 0;
    while( $argv0 =~ $captureson->{ $group } ) {
        # Try to match with each pattern of Per-Message field, Per-Recipient field
        # - 0: Field-Name
        # - 1: Sub Type: RFC822, DNS, X-Unix, and so on)
        # - 2: Value
        # - 3: Field Group(addr, code, date, host, stat, text)
        $match = 1;
        $table->[0] = lc $1;
        $table->[3] = $group;

        if( $group eq 'addr' || $group eq 'code' || $group eq 'host' ) {
            # - Final-Recipient: RFC822; kijitora@nyaan.jp
            # - Diagnostic-Code: SMTP; 550 5.1.1 <kijitora@example.jp>... User Unknown
            # - Remote-MTA: DNS; mx.example.jp
            $table->[1] = uc $2;
            $table->[2] = $group eq 'host' ? lc $3 : $3;
            $table->[2] = '' if $table->[2] =~ /\A\s+\z/;   # Remote-MTA: dns;

        } else {
            # - Action: failed
            # - Status: 5.2.2
            $table->[1] = '';
            $table->[2] = $group eq 'date' ? $2 : lc $2;

            # Correct invalid value in Action field:
            last unless $group eq 'list';
            last unless exists $correction->{'action'}->{ $table->[2] };
            $table->[2] = $correction->{'action'}->{ $table->[2] };
        }
        last;
    }

    return undef unless $match;
    return $table;
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::RFC1894 - DSN field defined in RFC3464 (obsoletes RFC1894)

=head1 SYNOPSIS

    use Sisimai::RFC1894;

    print Sisimai::RFC1894->match('From: Nyaan <kijitora@libsisimai.org>'); # 0
    print Sisimai::RFC1894->match('Reporting-MTA: DNS; mx.libsisimai.org'); # 1
    print Sisimai::RFC1894->match('Final-Recipient: RFC822; cat@nyaan.jp'); # 2

    my $v = Sisimai::RFC1894->field('Reporting-MTA: DNS; mx.nyaan.jp');
    my $r = Sisimai::RFC1894->field('Status: 5.1.1');
    print Data::Dumper::Dumper $v;  # ['reporting-mta', 'dns', 'mx.nyaan.org', 'host'];
    print Data::Dumper::Dumper $r;  # ['status', '', '5.1.1', 'stat'];

=head1 DESCRIPTION

C<Sisimai::RFC1894> provide methods for checking or getting DSN fields

=head1 CLASS METHODS

=head2 C<B<match(I<String>)>>

C<match()> method checks the argument includes the field defined in RFC3464 or not

    print Sisimai::RFC1894->match('From: Nyaan <kijitora@libsisimai.org>'); # 0
    print Sisimai::RFC1894->match('Reporting-MTA: DNS; mx.libsisimai.org'); # 1
    print Sisimai::RFC1894->match('Final-Recipient: RFC822; cat@nyaan.jp'); # 2

=head2 C<B<label(I<String>)>>

C<label()> method returns a lower cased field name such as C<"diagnostic-code"> from the given email
header or the delivery status field.

    print Sisimai::RFC1894->label('Remote-MTA: DNS; mx.nyaan.jp');  # remote-mta
    print Sisimai::RFC1894->field('Status: 5.1.1');                 # status
    print Sisimai::RFC1894->field('Subject: Nyaan');                # subject
    print Sisimai::RFC1894->field('');                              # undef

=head2 C<B<field(I<String>)>>

C<field()> method returns the splited values as an array reference from the given string including
DSN fields defined in RFC3464.

    my $v = Sisimai::RFC1894->field('Remote-MTA: DNS; mx.nyaan.jp');
    my $r = Sisimai::RFC1894->field('Status: 5.1.1');
    print Data::Dumper::Dumper $v;  # ['remote-mta', 'dns', 'mx.nyaan.org', 'host'];
    print Data::Dumper::Dumper $r;  # ['status', '', '5.1.1', 'stat'];

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2018-2024 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

