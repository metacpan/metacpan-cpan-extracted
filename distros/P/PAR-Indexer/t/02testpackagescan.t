#!/usr/bin/perl -w

use strict;
use Test::More tests => 13;

BEGIN { use_ok("PAR::Indexer") }

chdir('t') if -d 't';

my $dist = 'data/dist2.par';

ok(-f $dist, 'par distribution exists');

my %provides_expect = (
  "Test::Kit" => {
    file => "lib/Test/Kit.pm",
    version => "0.02",
  },
  "Test::Kit::Features" => {
    file => "lib/Test/Kit/Features.pm",
    version => "0.02",
  },
  # NOTE: This package is part of ::Features. It has no
  # separate version declaration, BUT the version is assumed
  # to be file-scoped by the indexer, so this is okay!
  "Test::Kit::Result" => {
    file => "lib/Test/Kit/Features.pm",
    version => '0.02',
  },
);

my $result = PAR::Indexer::scan_par_for_packages($dist);
ok(ref($result) eq 'HASH', 'returns a hash reference');

ok(keys %$result == keys %provides_expect, 'same number of entries');

foreach my $module (keys %provides_expect) {
  ok(ref($result->{$module}) eq 'HASH', 'key exists in result');
  my $modhash = $result->{$module};
  my $exphash = $provides_expect{$module};

  ok($exphash->{file} eq $modhash->{file}, 'file attribute okay');
  if (exists $exphash->{version}) {
    ok($exphash->{version} eq $modhash->{version}, 'version attribute okay');
  }
  else {
    ok(!exists($modhash->{version}), "version attribute doesn't exist -- as expected");
  }
}


__END__
