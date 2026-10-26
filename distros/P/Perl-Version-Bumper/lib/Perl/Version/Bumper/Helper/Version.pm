use v5.10;

package Perl::Version::Bumper::Helper::Version;
$Perl::Version::Bumper::Helper::Version::VERSION = '0.277';
use strict;
use warnings;
use Carp qw( croak );

use version;

use Exporter 'import';

our @EXPORT_OK = qw(
  version_fmt
  version_use
  stable_version
  stable_version_inc
  stable_version_dec
);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

# return a normalized version of a plausible Perl version number (or die)
sub version_fmt {
    my $o = shift // $];
    $o = $] unless length $o;
    my $v = version::->parse($o)->numify;    # accept everything
    return $v < 5.010
      ? croak "Unsupported Perl version: $o"
      : sprintf "%.3f", $v;                  # Perl version bundle
}

# return a normalized version, suitable for "use VERSION"
sub version_use {
    my $o = shift // $];
    $o = $] unless length $o;
    my $v = version::->parse($o)->numify;    # accept everything
    return $v < 5.010
      ? croak "Unsupported Perl version: $o"
      : sprintf 'v5.%d', substr( $v, 2, 3 );    # Perl version bundle
}

# return the closest stable version number lower than the parameter
sub stable_version {
    my $v = version_fmt(shift);
    $v *= 1000;
    return sprintf "%.3f", ( int($v) - $v % 2 ) / 1000;
}

# increment the version number to the next stable version
sub stable_version_inc {
    my $v = stable_version(shift);              # closest previous stable
    return sprintf "%.3f", $v + 0.002;
}

# decrement the version number to the previous stable version
sub stable_version_dec {
    my $v = version_fmt(shift);    # format the version
    my $s = stable_version($v);    # get the closest previous stable
    return $v ne $s
      ? $s                            # dev -> previous stable
      : sprintf "%.3f", $s - 0.002    # previous stable
}

1;

__END__

=head1 NAME

=head1 SYNOPSIS

    use Perl::Version::Bumper::Helper::Version ':all';

    my $v;

    # all the following return '5.036'
    $v = version_fmt(5.036001);        # number
    $v = version_fmt('v5.036.001');    # string
    $v = version_fmt(v5.36.1);         # v-string

    # format for `use VERSION`
    $v = version_use('5.036002');      # v5.36

    # nearest stable version below
    $v = stable_version("v5.37.8");    # 5.036

    # decrement to the previous stable version
    $v = stable_version_inc("v5.37.8");    # 5.036

    # increment to the next stable version
    $v = stable_version_inc("v5.37.8");    # 5.038

=head1 DESCRIPTION

This module provides a collection of helper functions used by
L<Perl::Version::Bumper> to manipulate version numbers.

Be aware that they are mostly meant for internal use of the module and
helper scripts, and are not meant for general usage.

=head1 FUNCTIONS

The following I<functions> can be optionally exported.
The C<:all> export tag will export them all at once.

=head2 version_fmt

    my $v = version_fmt( $version );

Return the given version (in string, v-string or float format) as a number.

This function will die if the given version is not a plausible Perl
version number, i.e. is strictly lower than C<5.010>.

Note that all the following functions start by normalizing their
argument by calling L</version_fmt>, meaning they will die in the same
circumstances.

=head2 version_use

    my $v = version_use( $version );

Return the given version (in string, v-string or float format) as
a string suitable for a C<use VERSION> line.

=head2 stable_version

    my $s = stable_version( $version );

Return the closest stable version lower or equal to the given version,
as a number.

=head2 stable_version_inc

    my $n = stable_version_inc( $version );

Return the stable version following the given version, as a number.

=head2 stable_version_dec

    my $p = stable_version_dec( $version );

Return the stable version preceding the given version, as a number.

=head1 AUTHOR

Philippe Bruhat (BooK) <book@cpan.org>

=head1 COPYRIGHT

Copyright 2024-2026 Philippe Bruhat (BooK), all rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
