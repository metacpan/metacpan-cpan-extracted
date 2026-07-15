package Net::DNS::ErrorReporter;
# ABSTRACT: a DNS Error Reporting (RFC 9567) agent.
use Carp;
use Net::DNS;
# see https://www.iana.org/assignments/dns-parameters/dns-parameters.xhtml#extended-dns-error-codes
use constant {
    OTHER_ERROR                         =>  0,
    UNSUPPORTED_DNSKEY_ALGORITHM        =>  1,
    UNSUPPORTED_DS_DIGEST_TYPE          =>  2,
    STALE_ANSWER                        =>  3,
    FORGED_ANSWER                       =>  4,
    DNSSEC_INDETERMINATE                =>  5,
    DNSSEC_BOGUS                        =>  6,
    SIGNATURE_EXPIRED                   =>  7,
    SIGNATURE_NOT_YET_VALID             =>  8,
    DNSKEY_MISSING                      =>  9,
    RRSIGS_MISSING                      => 10,
    NO_ZONE_KEY_BIT_SET                 => 11,
    NSEC_MISSING                        => 12,
    CACHED_ERROR                        => 13,
    NOT_READY                           => 14,
    BLOCKED                             => 15,
    CENSORED                            => 16,
    FILTERED                            => 17,
    PROHIBITED                          => 18,
    STALE_NXDOMAIN_ANSWER               => 19,
    NOT_AUTHORITATIVE                   => 20,
    NOT_SUPPORTED                       => 21,
    NO_REACHABLE_AUTHORITY              => 22,
    NETWORK_ERROR                       => 23,
    INVALID_DATA                        => 24,
    SIGNATURE_EXPIRED_BEFORE_VALID      => 25,
    TOO_EARLY                           => 26,
    UNSUPPORTED_NSEC3_ITERATIONS_VALUE  => 27,
    UNABLE_TO_CONFORM_TO_POLICY         => 28,
    SYNTHESIZED                         => 29,
    INVALID_QUERY_TYPE                  => 30,
    RATE_LIMITED                        => 31,
    OVER_QUOTA                          => 32,
    NEGATIVE_TRUST_ANCHOR               => 33,
    NEW_DELEGATION_ONLY                 => 34,
};
use vars qw($VERSION);
use common::sense;

$VERSION = '0.01';


sub new {
    my $self = bless({}, shift);

    $self->{resolver} = Net::DNS::Resolver->new(
        persistent_tcp  => 1,
        retry           => 1,
    );

    return $self;
}


sub report {
    my $self    = shift;
    my $packet  = {@_}->{packet};
    my $error   = {@_}->{error};

    return unless (defined($error) && defined($packet) && defined($packet->edns));

    my ($structure) = $packet->edns->option(q{REPORT-CHANNEL});
    return unless (defined($structure) && exists $structure->{q{REPORT-CHANNEL}}->{q{AGENT-DOMAIN}});

    my @labels = grep { length > 0 } Net::DNS::Domain->new(($packet->question)[0]->name)->label;
    return unless (scalar(@labels) > 0);

    unshift(@labels, ($packet->question)[0]->type);
    unshift(@labels, q{_er});
    push(@labels, sprintf(q{%u}, $error));
    push(@labels, q{_er});
    push(@labels, Net::DNS::Domain->new($structure->{q{REPORT-CHANNEL}}->{q{AGENT-DOMAIN}})->label);

    return $self->resolver->send(join(q{.}, @labels), q{TXT});
}


sub resolver { shift->{resolver} }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DNS::ErrorReporter - a DNS Error Reporting (RFC 9567) agent.

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Net::DNS::ErrorReporter;

    my $resolver = Net::DNS::Resolver->new;

    my $reporter = Net::DNS::ErrorReporter->new;

    my $answer = $resolver->send('perl.org', 'HINFO');

    if (!do_some_checks_on($answer)) {
        $reporter->report(
            packet  => $answer,
            error   => Net::DNS::ErrorReporter::SOME_ERROR_CODE,
        );
    }

=head1 DESCRIPTION

L<RFC 9567: DNS Error Reporting|https://www.rfc-editor.org/info/rfc9567/>
describes a method for a resolver to automatically signal an error to a
monitoring agent specified by the authoritative server. This shortens the time
between an issue affecting a zone occurring and the operator of that zone being
aware of it.

DNS Error Reporting is used by
L<RFC 9859: Generalized DNS Notifications|https://www.rfc-editor.org/info/rfc9859/>.
When a child operator sends a C<NOTIFY> message to the parent operator's endpoint,
they set the "agent domain" field in the "report channel" EDNS0 record, which
the parent can use to notify them of any issues found during CDS/CDNSKEY/CSYNC
scanning (see L<RFC 10026|https://www.rfc-editor.org/info/rfc10026/>).

=head1 USAGE

=head2 INSTANTIATION

    $reporter = Net::DNS::ErrorReporter->new;

This instantiates a new reporter object.

=head2 SENDING ERROR REPORTS

    $result = $reporter->report(
        packet  => $packet,
        error   => Net::DNS::ErrorReporter::SOME_ERROR_CODE,
    );

This sends an error report for the DNS message in C<$packet>, which must be a
L<Net::DNS::Packet> containing a query response. If C<$packet> is invalid in
some way, does not contain the required EDNS0 option, or the report query failed,
C<report()> will return C<undef>. Otherwise, it will return a L<Net::DNS::Packet>
containing the response (from the resolver) to the error report query.

The value of the C<error> parameter must be an integer taken from the
L<Extended DNS Error Codes|https://www.iana.org/assignments/dns-parameters/dns-parameters.xhtml#extended-dns-error-codes>
IANA registry. For readability, L<Net::DNS::ErrorReporter> provides the following
constants. The semantics of each code can be found by following the references
in the aforementioned IANA registry.

=over

=item * C<Net::DNS::ErrorReporter::OTHER_ERROR> (0)

=item * C<Net::DNS::ErrorReporter::UNSUPPORTED_DNSKEY_ALGORITHM> (1)

=item * C<Net::DNS::ErrorReporter::UNSUPPORTED_DS_DIGEST_TYPE> (2)

=item * C<Net::DNS::ErrorReporter::STALE_ANSWER> (3)

=item * C<Net::DNS::ErrorReporter::FORGED_ANSWER> (4)

=item * C<Net::DNS::ErrorReporter::DNSSEC_INDETERMINATE> (5)

=item * C<Net::DNS::ErrorReporter::DNSSEC_BOGUS> (6)

=item * C<Net::DNS::ErrorReporter::SIGNATURE_EXPIRED> (7)

=item * C<Net::DNS::ErrorReporter::SIGNATURE_NOT_YET_VALID> (8)

=item * C<Net::DNS::ErrorReporter::DNSKEY_MISSING> (9)

=item * C<Net::DNS::ErrorReporter::RRSIGS_MISSING> (10)

=item * C<Net::DNS::ErrorReporter::NO_ZONE_KEY_BIT_SET> (11)

=item * C<Net::DNS::ErrorReporter::NSEC_MISSING> (12)

=item * C<Net::DNS::ErrorReporter::CACHED_ERROR> (13)

=item * C<Net::DNS::ErrorReporter::NOT_READY> (14)

=item * C<Net::DNS::ErrorReporter::BLOCKED> (15)

=item * C<Net::DNS::ErrorReporter::CENSORED> (16)

=item * C<Net::DNS::ErrorReporter::FILTERED> (17)

=item * C<Net::DNS::ErrorReporter::PROHIBITED> (18)

=item * C<Net::DNS::ErrorReporter::STALE_NXDOMAIN_ANSWER> (19)

=item * C<Net::DNS::ErrorReporter::NOT_AUTHORITATIVE> (20)

=item * C<Net::DNS::ErrorReporter::NOT_SUPPORTED> (21)

=item * C<Net::DNS::ErrorReporter::NO_REACHABLE_AUTHORITY> (22)

=item * C<Net::DNS::ErrorReporter::NETWORK_ERROR> (23)

=item * C<Net::DNS::ErrorReporter::INVALID_DATA> (24)

=item * C<Net::DNS::ErrorReporter::SIGNATURE_EXPIRED_BEFORE_VALID> (25)

=item * C<Net::DNS::ErrorReporter::TOO_EARLY> (26)

=item * C<Net::DNS::ErrorReporter::UNSUPPORTED_NSEC3_ITERATIONS_VALUE> (27)

=item * C<Net::DNS::ErrorReporter::UNABLE_TO_CONFORM_TO_POLICY> (28)

=item * C<Net::DNS::ErrorReporter::SYNTHESIZED> (29)

=item * C<Net::DNS::ErrorReporter::INVALID_QUERY_TYPE> (30)

=item * C<Net::DNS::ErrorReporter::RATE_LIMITED> (31)

=item * C<Net::DNS::ErrorReporter::OVER_QUOTA> (32)

=item * C<Net::DNS::ErrorReporter::NEGATIVE_TRUST_ANCHOR> (33)

=item * C<Net::DNS::ErrorReporter::NEW_DELEGATION_ONLY> (34)

=back

=head2 OTHER METHODS

    $resolver = $reporter->resolver;

This returns the reporter's internal resolver object, in case you need to tweak
any of its settings.

=head1 AUTHOR

Gavin Brown <gavin.brown@fastmail.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Gavin Brown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
