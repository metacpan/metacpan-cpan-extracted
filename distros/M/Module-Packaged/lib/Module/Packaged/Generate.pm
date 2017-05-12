package Module::Packaged::Generate;
use strict;
use App::Cache;
use IO::File;
use Compress::Zlib;
use IO::String;
use IO::Zlib;
use File::Spec::Functions qw(catdir catfile tmpdir);
use LWP::Simple qw(mirror);
use Parse::CPAN::Packages;
use Parse::Debian::Packages;
use Sort::Versions;
use Storable qw(store retrieve);
use base 'Class::Accessor::Chained::Fast';
__PACKAGE__->mk_accessors(qw(cache data));

sub new {
  my $class = shift;
  my $self  = {};
  bless $self, $class;

  $self->cache(App::Cache->new({ ttl => 60 * 60 }));

  $self->{data} = $self->cache->get_code(
    "data",
    sub {
      $self->_fetch_cpan;
      $self->_fetch_debian;
      $self->_fetch_fedora;
      $self->_fetch_freebsd;
      $self->_fetch_gentoo;
      $self->_fetch_mandrake;
      $self->_fetch_openbsd;
      $self->_fetch_suse;
      $self->{data};
    }
  );

  return $self;
}

sub _fetch_cpan {
  my $self    = shift;
  my $details =
    $self->cache->get_url(
    "http://www.cpan.org/modules/02packages.details.txt.gz",
    "02packages.gz");

  $details = Compress::Zlib::memGunzip($details);

  my $p = Parse::CPAN::Packages->new($details);

  foreach my $dist ($p->latest_distributions) {
    $self->{data}->{ $dist->dist }->{cpan} = $dist->version;
  }
}

sub _fetch_gentoo {
  my $self = shift;

  my $file =
    $self->cache->get_url("http://www.gentoo.org/dyn/gentoo_pkglist_x86.txt",
    "gentoo.html");
  $file =~ s{</a></td>\n}{</a></td>}g;

  my @dists = keys %{ $self->{data} };

  foreach my $line (split "\n", $file) {
    next unless ($line =~ m/dev-perl/);
    my $dist;
    $line =~ s/\.ebuild//g;
    my ($package, $version, $trash) = split(' ', $line);
    next unless $package;

    # Let's try to find a cpan dist that matches the package name
    if (exists $self->{data}->{$package}) {
      $dist = $package;
    } else {
      foreach my $d (@dists) {
        if (lc $d eq lc $package) {
          $dist = $d;
          last;
        }
      }
    }

    if ($dist) {
      $self->{data}->{$dist}->{gentoo} = $version;
    } else {

      # I should probably care about these and fix them
      # warn "Could not find $package: $version\n";
    }
  }
}

sub _fetch_fedora {
  my $self = shift;
  my $file =
    $self->cache->get_url("http://fedora.redhat.com/docs/package-list/fc2/",
    "fedora.html");
  foreach my $line (split "\n", $file) {
    next unless $line =~ /^perl-/;
    my ($dist, $version) =
      $line =~ m{perl-(.*?)</td><td class="column-2">(.*?)</td>};

    # only populate if CPAN already has
    $self->{data}{$dist}{fedora} = $version
      if $self->{data}{$dist};
  }
}

sub _fetch_suse {
  my $self = shift;
  my $file = $self->cache->get_url(
    "http://www.novell.com/products/linuxpackages/suselinux/index_all.html",
    "suse.html"
  );

  foreach my $line (split "\n", $file) {

   #    <a href="perl-dbi.html">perl-DBI 1.43 </a> (The Perl Database Interface)
    my ($dist, $version) = $line =~ m{">perl-(.*?) (.*?) </a>};
    next unless $dist;

    # only populate if CPAN already has
    $self->{data}{$dist}{suse} = $version
      if $self->{data}{$dist};
  }
}

sub _fetch_mandrake {
  my $self  = shift;
  my $file1 = $self->cache->get_url(
"http://distro.ibiblio.org/pub/linux/distributions/mandriva/MandrivaLinux/official/10.2/i586/media/media_info/synthesis.hdlist_main.cz",
    "mandrake1.html"
  );
  my $file2 = $self->cache->get_url(
"http://distro.ibiblio.org/pub/linux/distributions/mandriva/MandrivaLinux/official/10.2/i586/media/media_info/synthesis.hdlist_contrib.cz",
    "mandrake2.html"
  );

  foreach my $file ($file1, $file2) {
    $file = Compress::Zlib::memGunzip($file);
    foreach my $line (split / /, $file) {

      # @info@perl-DBI-1.43-2mdk.i586@0@1371700@Development/Perl
      next
        unless my ($dist, $version) =
        $line =~ m{\@info\@perl-(.*)-(.*?)-\d+mdk};

      # only populate if CPAN already has
      $self->{data}{$dist}{mandrake} = $version
        if $self->{data}{$dist};
    }
  }
}

sub _fetch_freebsd {
  my $self = shift;
  my $file = $self->cache->get_url("http://www.freebsd.org/ports/perl5.html",
    "freebsd.html");

#<DT><B><A NAME="p5-DBI-1.37"></A><A HREF="http://www.FreeBSD.org/cgi/cvsweb.cgi/ports/databases/p5-DBI-137">p5-DBI-1.37</A></B> </DT>
  for my $package ($file =~ m/A NAME="p5-(.*?)"/g) {
    my ($dist, $version) = $package =~ /^(.*?)-(\d.*)$/ or next;

    # tidy up the oddness FreeBSD versions
    $version =~ s/_\d$//;

    # only populate if CPAN already has
    $self->{data}{$dist}{freebsd} = $version
      if $self->{data}{$dist};
  }
}

sub _fetch_debian {
  my $self = shift;

  my %dists = map { lc $_ => $_ } keys %{ $self->{data} };
  for my $dist (qw( stable testing unstable )) {
    my $data =
      $self->cache->get_url(
      "http://ftp.debian.org/dists/$dist/main/binary-i386/Packages.gz",
      "debian-$dist-Packages.gz");
    $data = Compress::Zlib::memGunzip($data);

    my $fh       = IO::String->new($data);
    my $debthing = Parse::Debian::Packages->new($fh);
    while (my %package = $debthing->next) {
      next
        unless $package{Package} =~ /^lib(.*?)-perl$/
        || $package{Package}     =~ /^perl-(tk)$/;
      my $dist = $dists{$1} or next;

      # don't care about the debian version
      my ($version) = $package{Version} =~ /^(.*?)-/;
      $self->{data}{$dist}{debian} = $version
        if $self->{data}{$dist};
    }
  }
}

sub _fetch_openbsd {
  my $self = shift;
  my $file =
    $self->cache->get_url("http://www.openbsd.org/3.6_packages/i386.html",
    "openbsd.html");

  for my $package ($file =~ m/href=i386\/p5-(.*?)\.tgz-long/g) {
    my ($dist, $version) = $package =~ /^(.*?)-(\d.*)$/ or next;

    # only populate if CPAN already has
    $self->{data}{$dist}{openbsd} = $version
      if $self->{data}{$dist};
  }
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

Note: only CPAN, Debian, Fedora (Core 2), FreeBSD, Gentoo, Mandriva
(10.1), OpenBSD (3.6) and SUSE (9.2) are currently supported. I want to
support everything else. Patches are welcome.

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

