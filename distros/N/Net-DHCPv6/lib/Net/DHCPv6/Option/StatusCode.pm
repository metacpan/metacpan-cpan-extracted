#!/bin/false
# ABSTRACT: Status Code option (code 13)
# PODNAME: Net::DHCPv6::Option::StatusCode
use strictures 2;

package Net::DHCPv6::Option::StatusCode;
$Net::DHCPv6::Option::StatusCode::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Carp                    qw( croak );
use Net::DHCPv6::Constants  qw(
    $OPTION_STATUS_CODE
);
use Net::DHCPv6::X::Truncated ();
use parent 'Net::DHCPv6::Option';
use namespace::clean;
my $EMPTY = q();

sub new {
    my ( $class, %args ) = @_;
    croak 'StatusCode requires status_code' unless defined $args{status_code};
    $args{code}    = $OPTION_STATUS_CODE;
    $args{message} = $args{message} // $EMPTY;
    $args{data}    = pack( 'n', $args{status_code} ) . $args{message};
    my $self = $class->SUPER::new( %args );
    $self->{status_code} = $args{status_code};
    $self->{message}     = $args{message};
    return bless $self, $class;
}

sub status_code { return shift->{status_code} }
sub message     { return shift->{message} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated StatusCode option' )
        if CORE::length( $payload ) < 2;
    my $sc  = unpack( 'n', substr( $payload, 0, 2 ) );
    my $msg = substr( $payload, 2 );
    return $class->new( status_code => $sc, message => $msg );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_STATUS_CODE} = __PACKAGE__;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::StatusCode - Status Code option (code 13)

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $sc = Net::DHCPv6::Option::StatusCode->new(
      status_code => 0,
      message     => 'Success',
  );

=head1 DESCRIPTION

Implements the Status Code option (OPTION_STATUS_CODE, code 13) per
RFC 8415 E<167>21.13. Contains a 16-bit status code and an optional
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
