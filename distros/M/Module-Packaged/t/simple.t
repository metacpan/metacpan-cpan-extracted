#!/usr/bin/perl -w

use strict;
use Test::More tests => 4;
use_ok('Module::Packaged');

warn "\n# These tests take a while to run as we need to mirror a large\n";
warn "# file from the web. Please be patient.\n";

my $p = Module::Packaged->new();

my $dists = $p->check('Acme-Buffy');
is_deeply($dists, {
  cpan => '1.3',
}, 'Acme-Buffy');

$dists = $p->check('Archive-Tar');
is_deeply($dists, {
  cpan    => '1.30',
  debian  => '1.30',
  fedora  => '1.08',
  freebsd => '1.30',
  gentoo  => '1.29',
  mandrake => '1.23',
  openbsd => '1.08',
  suse    => '1.24',
}, 'Archive-Tar');

$dists = $p->check('DBI');
is_deeply($dists, {
  cpan     => '1.52',
  debian   => '1.52',
  fedora   => '1.40',
  freebsd  => '1.52',
  gentoo   => '1.50',
  mandrake => '1.47',
  openbsd  => '1.43',
  suse     => '1.50',
}, 'DBI');


