#!/usr/bin/false
# ABSTRACT: Authentication option (code 11) — protocol/algorithm/rdm/replay/auth-info
# PODNAME: Net::DHCPv6::Option::Auth
package Net::DHCPv6::Option::Auth;
$Net::DHCPv6::Option::Auth::VERSION = '0.001';
use strictures 2;
use Carp qw(croak);
use Net::DHCPv6::Constants;
use Net::DHCPv6::X::Truncated;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    for my $field ( qw(protocol algorithm rdm replay) ) {
        croak "Auth requires $field" unless defined $args{$field};
    }
    croak 'Auth replay must be exactly 8 bytes'
        if CORE::length( $args{replay} ) != 8;
    $args{code} = $OPTION_AUTH;
    $args{data} =
        pack( 'C C C a8 a*', $args{protocol}, $args{algorithm}, $args{rdm}, $args{replay}, $args{auth_info} // '' );
    my $self = $class->SUPER::new( %args );
    $self->{protocol}  = $args{protocol};
    $self->{algorithm} = $args{algorithm};
    $self->{rdm}       = $args{rdm};
    $self->{replay}    = $args{replay};
    $self->{auth_info} = $args{auth_info} // '';
    bless $self, $class;
}

sub protocol  { shift->{protocol} }
sub algorithm { shift->{algorithm} }
sub rdm       { shift->{rdm} }
sub replay    { shift->{replay} }
sub auth_info { shift->{auth_info} }

sub from_bytes_inner {
    my ( $class, $code, $data ) = @_;
    Net::DHCPv6::X::Truncated->throw( message => 'Truncated Auth option' )
        if CORE::length( $data ) < 11;
    my ( $proto, $alg, $rdm, $replay, $info ) = unpack( 'C C C a8 a*', $data );
    return $class->new(
        protocol  => $proto,
        algorithm => $alg,
        rdm       => $rdm,
        replay    => $replay,
        auth_info => $info,
    );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_AUTH} = __PACKAGE__;
1;

__END__

=pod

=encoding utf-8

=head1 NAME

Net::DHCPv6::Option::Auth - Authentication option (code 11) — protocol/algorithm/rdm/replay/auth-info

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Net::DHCPv6::Option::Auth;
  my $opt = Net::DHCPv6::Option::Auth->new(
      protocol  => 3,
      algorithm => 1,
      rdm       => 0,
      replay    => "\x00" x 8,
      auth_info => '...',
  );

=head1 DESCRIPTION

Carries authentication information for DHCPv6 messages, including
protocol, algorithm, replay detection method, replay counter, and
authentication data.  See RFC 8415 §21.11.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<protocol>, C<algorithm>, C<rdm>, and
C<replay> (exactly 8 bytes).  Optional C<auth_info>.

=head2 protocol

Returns the protocol field.

=head2 algorithm

Returns the algorithm field.

=head2 rdm

Returns the replay detection method field.

=head2 replay

Returns the 8-byte replay counter.

=head2 auth_info

Returns the authentication information bytes.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
