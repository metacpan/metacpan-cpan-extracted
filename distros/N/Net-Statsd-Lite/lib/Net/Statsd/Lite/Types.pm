package Net::Statsd::Lite::Types;

# ABSTRACT: A type library for Net::Statsd::Lite

# RECOMMEND PREREQ: Type::Tiny::XS

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;

BEGIN { extends "Types::Standard" }

our $VERSION = 'v0.4.8';


# See also Types::Common::Numeric PositiveOrZeroInt

declare "PosInt", as Int,
  where { $_ >= 0 },
  inline_as { my $n = $_[1]; (undef, "$n >= 0") };

# See also Types::Common::Numeric PositiveOrZeroNum

declare "PosNum", as StrictNum,
  where { $_ >= 0 },
  inline_as { my $n = $_[1]; (undef, "$n >= 0") };

declare "Port", as "PosInt",
  where { $_ >= 0 && $_ <= 65535 },
  inline_as { my $port = $_[1]; (undef, "$port <= 65535") };

declare "Rate", as StrictNum,
  where { $_ >= 0 && $_ <= 1 },
  inline_as { my $n = $_[1]; (undef, "$n >= 0 && $n <= 1") };

declare "Gauge", as Str,
  where { $_ =~ /\A[\-\+]?\d+\z/ },
  inline_as { my $n = $_[1]; (undef, "$n =~ /\\A[\\-\\+]?\\d+\\z/") };


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Statsd::Lite::Types - A type library for Net::Statsd::Lite

=head1 VERSION

version v0.4.8

=head1 DESCRIPTION

This module provides types for L<Net::Statsd::Lite>.

The types declared here are intended for internal use, and subject to
change.

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/Net-Statsd-Lite>
and may be cloned from L<git://github.com/robrwo/Net-Statsd-Lite.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/Net-Statsd-Lite/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Robert Rothenberg.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
