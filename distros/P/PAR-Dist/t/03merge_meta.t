#!/usr/bin/perl -w

use strict;
use Test::More;
use vars '$loaded';

BEGIN { $loaded = eval { require PAR::Dist; 1 } };
BEGIN {
  my $tests = 29;
  if ($loaded) {  
    # skip these tests without YAML loader or without (A::Zip or zipo/unzip)
    $PAR::Dist::DEBUG = 1;
    my $tools = PAR::Dist::_check_tools();
    $PAR::Dist::DEBUG = 0;
    if (not defined $tools->{DumpFile}) {
      plan skip_all => "Skip because no YAML loader/dumper could be found";
      exit();
    }
    elsif (not defined $tools->{zip}) {
      plan skip_all => "Skip because neither Archive::Zip nor zip/unzip could be found";
      exit();
    }
    else {
      plan tests => $tests;
      ok(1);
    }
  }
  else {
    plan tests => $tests;
    ok(0, "Could not load PAR::Dist: $@");
    exit();
  }
}

ok (eval { require PAR::Dist; 1 });

chdir('t') if -d 't';

my @dist = (
  'data/dist1.par',
  'data/dist2.par',
);

my @tmp = map {my $f = $_; $f =~ s/^data\///; $f} @dist;

require File::Copy;
for (0..$#dist) {
  ok(-f $dist[$_]);
  ok(File::Copy::copy($dist[$_], $tmp[$_]));
}

sub cleanup {
  unlink($_) for @tmp;
}
$SIG{INT} = \&cleanup;
$SIG{TERM} = \&cleanup;
END { cleanup(); }

my %provides_expect = (
  "Math::Symbolic::Custom::Transformation" => {
    file => "lib/Math/Symbolic/Custom/Transformation.pm",
    version => "2.01",
  },
  "Math::Symbolic::Custom::Transformation::Group" => {
    file => "lib/Math/Symbolic/Custom/Transformation/Group.pm",
    version => "1.25",
  },
  "Test::Kit" => {
    file => "lib/Test/Kit.pm",
    version => "0.02",
  },
  "Test::Kit::Features" => {
    file => "lib/Test/Kit/Features.pm",
    version => "0.02",
  },
  "Test::Kit::Result" => {
    file => "lib/Test/Kit/Features.pm",
  },
);

my %requires_expect = (
  "Math::Symbolic" => '0.507',
  "Math::Symbolic::Custom::Pattern" => '1.20',
  "base" =>  '2.11',
  "namespace::clean" =>  '0.08',
  "Test::More" => '0',
);

my %build_requires_expect = (
  "Test::More" => '0.1',
  "Test::Differences" => undef,
);

my %recommends_expect = (
  "Test::Pod" => '1.0',
  "Test::Pod::Coverage" => '1.0',
);


PAR::Dist::merge_par(@tmp);

ok(1); # got to this point

my ($y_func) = PAR::Dist::_get_yaml_functions();

my $meta = PAR::Dist::get_meta($tmp[0]);
ok(defined($meta));

my $result = $y_func->{Load}->( $meta );
ok(defined $result);
$result = $result->[0] if ref($result) eq 'ARRAY';

my $provides = $result->{provides};
ok(ref($provides) eq 'HASH');

foreach my $module (keys %provides_expect) {
  ok(ref($provides->{$module}) eq 'HASH');
  my $modhash = $provides->{$module};
  my $exphash = $provides_expect{$module};

  ok($exphash->{file} eq $modhash->{file});
  if (exists $exphash->{version}) {
    ok($exphash->{version} eq $modhash->{version});
  }
  else {
    ok(!exists($modhash->{version}));
  }
}

is_deeply($result->{requires}, \%requires_expect, "requires merged as expected");
is_deeply($result->{build_requires}, \%build_requires_expect, "build_requires merged as expected");
is_deeply($result->{configure_requires}, undef, "configure_requires merged as expected");
is_deeply($result->{recommends}, \%recommends_expect, "recommends merged as expected");

__END__
