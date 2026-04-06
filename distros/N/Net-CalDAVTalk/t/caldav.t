#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;
use JSON::XS;
use Net::CalDAVTalk;

unless ($ENV{SERVERURL}) {
  plan skip_all => "need a server URL to test against CalDAV";
  exit 0;
}

my $testdir = "testdata";

opendir(DH, $testdir);
my @list;
while (my $item = readdir(DH)) {
  next unless $item =~ m/(.*).ics/;
  push @list, $1;
}
closedir(DH);

my $numtests = scalar(@list) * 2;
$numtests += 1;
plan tests => $numtests;

my $cdt = Net::CalDAVTalk->new(url => $ENV{SERVERURL});

foreach my $name (@list) {
  my $ical = slurp($name, 'ics');
  my $api = slurp($name, 'je');
  my @idata = $cdt->vcalendarToEvents($ical);
  die JSON::XS->new->pretty(1)->canonical(1)->encode(\@idata) unless $api;
  warn JSON::XS->new->pretty(1)->canonical(1)->encode(\@idata) if $ENV{NOISY};

  my $adata = JSON::XS::decode_json($api);

  is_deeply(\@idata, $adata, $name);

  # round trip it
  my $new = $cdt->_argsToVCalendar(\@idata);
  my $newical = $new->as_string();
  warn $newical if $ENV{NOISY};
  # and round trip it back again
  my @back = $cdt->vcalendarToEvents($newical);
  # and it's still the same
  is_deeply(\@back, $adata, "$name roundtrip");
}

sub slurp {
  my $name = shift;
  my $ext = shift;
  open(FH, "<$testdir/$name.$ext") || return;
  local $/ = undef;
  my $data = <FH>;
  close(FH);
  return $data;
}
