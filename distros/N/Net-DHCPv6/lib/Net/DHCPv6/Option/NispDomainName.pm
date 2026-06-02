#!/bin/false
# ABSTRACT: NIS+ Domain Name option (code 30) -- NIS+ domain name string
# PODNAME: Net::DHCPv6::Option::NispDomainName
use strictures 2;

package Net::DHCPv6::Option::NispDomainName;
$Net::DHCPv6::Option::NispDomainName::VERSION = '0.002';
use Net::DHCPv6::OptionList;
use Carp qw( croak );
use Net::DHCPv6::Constants;
use parent 'Net::DHCPv6::Option';
use namespace::clean;

sub new {
    my ( $class, %args ) = @_;
    croak 'NispDomainName requires domain_name' unless defined $args{domain_name};
    $args{code} = $OPTION_NISP_DOMAIN_NAME;
    $args{data} = $args{domain_name};
    my $self = $class->SUPER::new( %args );
    $self->{domain_name} = $args{domain_name};
    return bless $self, $class;
}

sub domain_name { return shift->{domain_name} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    return $class->new( domain_name => $payload );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_NISP_DOMAIN_NAME} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::NispDomainName - NIS+ Domain Name option (code 30) -- NIS+ domain name string

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Net::DHCPv6::Option::NispDomainName;
  my $opt = Net::DHCPv6::Option::NispDomainName->new(
      domain_name => 'nis.example.com',
  );

=head1 DESCRIPTION

Carries the NIS+ domain name as an opaque string.  See RFC 3898.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Requires C<domain_name>.

=head2 domain_name

Returns the domain name string.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
