# ABSTRACT: Pure checks of install options, before anything touches the host

package Rex::Rancher::Options;
our $VERSION = '0.003';
use v5.14.4;
use warnings;


sub resolve_install_method {
  my ( $self, $method, $version ) = @_;
  $method //= 'script';
  die "Unknown install_method: $method (expected 'script' or 'artifact')\n"
    unless $method eq 'script' || $method eq 'artifact';
  die "install_method 'artifact' requires a version (e.g. v1.30.4+rke2r1)\n"
    if $method eq 'artifact' && !$version;
  return $method;
}


sub check_cluster_cidr {
  my ( $self, $cidr ) = @_;
  return unless defined $cidr;
  my @part = $cidr =~ m{\A(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/(\d{1,2})\z};
  die "cluster_cidr must be one IPv4 CIDR such as 10.42.0.0/16, got '$cidr' "
    . "(dual-stack is not supported: Cilium's pool is IPv4 here)\n"
    unless @part && !grep({ $_ > 255 } @part[0 .. 3]) && $part[4] <= 32;
  return $cidr;
}


sub check_ipam_mode {
  my ( $self, $mode ) = @_;
  return unless defined $mode;
  die "ipam_mode must be 'kubernetes' or 'cluster-pool', got '$mode' (other "
    . "Cilium IPAM modes need more than a mode: set them in helm_values)\n"
    unless $mode eq 'kubernetes' || $mode eq 'cluster-pool';
  return $mode;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Rancher::Options - Pure checks of install options, before anything touches the host

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Rex::Rancher::Options;

  my $method = Rex::Rancher::Options->resolve_install_method($opts{install_method}, $opts{version});
  my $cidr   = Rex::Rancher::Options->check_cluster_cidr($opts{cluster_cidr});
  my $mode   = Rex::Rancher::Options->check_ipam_mode($opts{ipam_mode});

=head1 DESCRIPTION

Option checks that are the same for RKE2 and K3s and need no host: they
return the value to use or die with a message for the Rexfile author, before
L<Rex::Rancher::Server>, L<Rex::Rancher::Agent>, L<Rex::Rancher::Cilium> or
L<Rex::Rancher> touch anything. Class methods; nothing is exported.
L</resolve_install_method> and L</check_cluster_cidr> are still callable on
L<Rex::Rancher::Distribution>, which hands them on to this class.

=head2 resolve_install_method

  my $method = Rex::Rancher::Options->resolve_install_method($method, $version);

C<script> (default) or C<artifact>; anything else dies, and so does
C<artifact> without a version.

=head2 check_cluster_cidr

  Rex::Rancher::Options->check_cluster_cidr($cidr);

Returns C<$cidr> when it is one IPv4 CIDR, C<undef> for C<undef>, and dies
otherwise (Cilium's pool is IPv4 only here, so no dual-stack).

=head2 check_ipam_mode

  Rex::Rancher::Options->check_ipam_mode($mode);

Returns C<$mode> when it is C<kubernetes> or C<cluster-pool>, C<undef> for
C<undef>, and dies otherwise. These are the two Cilium IPAM modes that work
on RKE2 and K3s from nothing but a CIDR: C<kubernetes> takes the node
C<podCIDR>s the cluster cuts from its C<cluster-cidr>, C<cluster-pool>
cuts per-node ranges from Cilium's own pool. C<multi-pool> needs pools
defined in the Helm values, C<crd>, C<eni>, C<azure>, C<alibabacloud> and
C<delegated-plugin> an external allocator or cloud; those stay a matter of
C<helm_values>.

=head1 SEE ALSO

L<Rex::Rancher::Distribution>, L<Rex::Rancher::Server>,
L<Rex::Rancher::Agent>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/rex-rancher/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
