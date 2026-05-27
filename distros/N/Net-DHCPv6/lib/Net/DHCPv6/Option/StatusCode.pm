#!/usr/bin/false
# ABSTRACT: Status Code option (code 13)
# PODNAME: Net::DHCPv6::Option::StatusCode
package Net::DHCPv6::Option::StatusCode;
$Net::DHCPv6::Option::StatusCode::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'StatusCode requires status_code' unless defined $args{status_code};
    $args{code}    = $OPTION_STATUS_CODE;
    $args{message} = $args{message} // '';
    $args{data}    = pack( 'n', $args{status_code} ) . $args{message};
    my $self = $class->SUPER::new( %args );
    $self->{status_code} = $args{status_code};
    $self->{message}     = $args{message};
    bless $self, $class;
}

sub status_code { shift->{status_code} }
sub message     { shift->{message} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated StatusCode option' )
        if CORE::length( $data ) < 2;
    my $sc  = unpack( 'n', substr( $data, 0, 2 ) );
    my $msg = substr( $data, 2 );
    return $class->new( status_code => $sc, message => $msg );
}

sub as_bytes {
    my $self = shift;
    my $data = pack( 'n', $self->{status_code} ) . $self->{message};
    return pack( 'nn', $self->{code}, CORE::length( $data ) ) . $data;
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_STATUS_CODE} = __PACKAGE__;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::StatusCode - Status Code option (code 13)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  my $sc = Net::DHCPv6::Option::StatusCode->new(
      status_code => 0,
      message     => 'Success',
  );

=head1 DESCRIPTION

Implements the Status Code option (OPTION_STATUS_CODE, code 13) per
RFC 8415 §21.13. Contains a 16-bit status code and an optional
human-readable message string.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=over

=item B<new>(status_code => $num, message => $str)

Constructor. C<status_code> is required; C<message> defaults to empty.

=item B<status_code>

Returns the numeric status code.

=item B<message>

Returns the status message string.

=back

=head1 SEE ALSO

L<Net::DHCPv6::Constants> for C<$STATUS_*> constants

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
