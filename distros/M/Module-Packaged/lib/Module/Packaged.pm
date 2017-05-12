package Module::Packaged;
use strict;
use App::Cache;
use Compress::Zlib;
use LWP::Simple;
use Storable qw(thaw);
use vars qw($VERSION);
$VERSION = '0.86';

sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;

  my $cache = App::Cache->new({ ttl => 60 * 60 });
  my $data = $cache->get_url('http://www.astray.com/tmp/module_packaged.gz');
  $self->{data} = thaw(uncompress($data));
  return $self;
}

sub check {
  my ($self, $dist) = @_;
  return $self->{data}->{$dist};
}

1;

__END__

=head1 NAME

Module::Packaged - Report upon packages of CPAN distributions

=head1 SYNOPSIS

  use Module::Packaged;

  my $p = Module::Packaged->new();
  my $dists = $p->check('Archive-Tar');
  # $dists is now:
  # {
  # cpan    => '1.08',
  # debian  => '1.03',
  # fedora  => '0.22',
  # freebsd => '1.07',
  # gentoo  => '1.05',
  # openbsd => '0.22',
  # suse    => '0.23',
  # }

  # meaning that Archive-Tar is at version 1.08 on CPAN but only at
  # version 1.07 on FreeBSD, version 1.05 on Gentoo, version 1.03 on
  # Debian, version 0.23 on SUSE and version 0.22 on OpenBSD

=head1 DESCRIPTION

CPAN consists of distributions. However, CPAN is not an isolated
system - distributions are also packaged in other places, such as for
operating systems. This module reports whether CPAN distributions are
packaged for various operating systems, and which version they have.

Only CPAN, Debian, Fedora (Core 2), FreeBSD, Gentoo, Mandriva (10.1),
OpenBSD (3.6) and SUSE (9.2) are currently supported. I want to support
everything else. Patches are welcome.

The data is fetched from the net and cached for an hour.

=head1 METHODS

=head2 new()

The new() method is a constructor:

  my $p = Module::Packaged->new();

=head2 check()

The check() method returns a hash reference. The keys are various
distributions, the values the version number included:

  my $dists = $p->check('Archive-Tar');

=head1 COPYRIGHT

Copyright (c) 2003-5 Leon Brocard. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

=head1 AUTHOR

Leon Brocard, leon@astray.com

