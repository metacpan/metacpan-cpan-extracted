#!/bin/false
# ABSTRACT: Rapid Commit option (code 14) -- zero-length data
# PODNAME: Net::DHCPv6::Option::RapidCommit
use strictures 2;

package Net::DHCPv6::Option::RapidCommit;
$Net::DHCPv6::Option::RapidCommit::VERSION = '0.002';
use Net::DHCPv6::OptionList;
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::BadOption;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    $args{code} = $OPTION_RAPID_COMMIT;
    my $self = $class->SUPER::new( code => $args{code} );
    return bless $self, $class;
}

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::BadOption->throw( message => 'RapidCommit option must be empty' )
        if CORE::length( $payload ) > 0;
    return $class->new;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_RAPID_COMMIT} = __PACKAGE__;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::RapidCommit - Rapid Commit option (code 14) -- zero-length data

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $rc = Net::DHCPv6::Option::RapidCommit->new;

=head1 DESCRIPTION

Implements the Rapid Commit option (OPTION_RAPID_COMMIT, code 14) per
RFC 8415 E<167>21.14. A zero-length option that signals the server should
commit the assignment immediately (solicit-advertise-request-reply
short circuit).

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<new>

Constructor. No parameters required.

=back

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
