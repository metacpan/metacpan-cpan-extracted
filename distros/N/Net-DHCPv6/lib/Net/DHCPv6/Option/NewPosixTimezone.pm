#!/bin/false
# ABSTRACT: NEW_POSIX_TIMEZONE option (code 41) -- POSIX timezone string
# PODNAME: Net::DHCPv6::Option::NewPosixTimezone
use strictures 2;

package Net::DHCPv6::Option::NewPosixTimezone;
$Net::DHCPv6::Option::NewPosixTimezone::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Carp                    qw( croak );
use Net::DHCPv6::Constants  qw(
    $OPTION_NEW_POSIX_TIMEZONE
);
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'NewPosixTimezone requires tz_string' unless defined $args{tz_string};
    $args{code} = $OPTION_NEW_POSIX_TIMEZONE;
    $args{data} = $args{tz_string};
    my $self = $class->SUPER::new( %args );
    $self->{tz_string} = $args{tz_string};
    return bless $self, $class;
}

sub tz_string { return shift->{tz_string} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    return $class->new( tz_string => $payload );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_NEW_POSIX_TIMEZONE} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::NewPosixTimezone - NEW_POSIX_TIMEZONE option (code 41) -- POSIX timezone string

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Net::DHCPv6::Option::NewPosixTimezone;
  my $opt = Net::DHCPv6::Option::NewPosixTimezone->new(
      tz_string => 'EST5EDT',
  );

=head1 DESCRIPTION

Carries a POSIX timezone string (e.g. C<EST5EDT>).  See RFC 4833.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<tz_string>.

=head2 tz_string

Returns the POSIX timezone string.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
