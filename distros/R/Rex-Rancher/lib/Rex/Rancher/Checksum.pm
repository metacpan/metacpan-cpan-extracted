# ABSTRACT: SHA-256 checks of downloaded release artifacts

package Rex::Rancher::Checksum;
our $VERSION = '0.003';
use v5.14.4;
use warnings;


sub expected_sha256 {
  my ( $self, $sums_text, $asset ) = @_;
  for my $line (split /\n/, $sums_text // '') {
    return lc $1 if $line =~ /\A\s*([0-9a-fA-F]{64})\s+\*?\Q$asset\E\s*\z/;
  }
  return;
}


sub sha256_of {
  my ( $self, $out ) = @_;
  return lc $1 if ($out // '') =~ /\A\s*([0-9a-fA-F]{64})\b/;
  return;
}


sub verify_sha256 {
  my ( $self, $expected, $actual, $asset ) = @_;
  die "No checksum for $asset in the release's sha256sum file\n"
    unless defined $expected;
  die "Could not compute sha256 of downloaded $asset\n"
    unless defined $actual;
  die "Checksum mismatch for $asset: expected $expected, got $actual\n"
    unless $expected eq $actual;
  return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Rex::Rancher::Checksum - SHA-256 checks of downloaded release artifacts

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Rex::Rancher::Checksum;

  my $C = 'Rex::Rancher::Checksum';
  $C->verify_sha256(
    scalar $C->expected_sha256($sums_text, 'rke2.linux-amd64.tar.gz'),
    scalar $C->sha256_of($sha256sum_output),
    'rke2.linux-amd64.tar.gz',
  );

=head1 DESCRIPTION

Pure parsing and comparison of SHA-256 checksums, the same for RKE2 and K3s:
the official C<sha256sum-ARCH.txt> of a release against the C<sha256sum>
output for the downloaded file. Nothing here reads the host; the commands
that produce both texts run in
L<Rex::Rancher::Distribution/fetch_artifacts>. Class methods; nothing is
exported. The same methods are still callable on
L<Rex::Rancher::Distribution>, which hands them on to this class.

=head2 expected_sha256

  Rex::Rancher::Checksum->expected_sha256($sums_text, $asset)

The checksum for exactly C<$asset> in an official C<sha256sum-ARCH.txt>, or
nothing. Exact name match: C<k3s> does not pick up
C<k3s-airgap-images-...>.

=head2 sha256_of

The first field of C<sha256sum FILE> output, or nothing.

=head2 verify_sha256

  Rex::Rancher::Checksum->verify_sha256($expected, $actual, $asset)

Returns C<1> when both are there and equal, dies otherwise.

=head1 SEE ALSO

L<Rex::Rancher::Distribution>

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
