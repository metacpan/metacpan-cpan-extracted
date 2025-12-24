use strict;
use warnings;
use Test::More;
use File::Find;

use lib 'lib';

my @files;

if (($ENV{HARNESS_PERL_SWITCHES} || '') =~ /Devel::Cover/) {
  plan skip_all => 'HARNESS_PERL_SWITCHES =~ /Devel::Cover/';
}
if (!eval 'use Test::Pod; 1') {
  *Test::Pod::pod_file_ok = sub {
  SKIP: { skip "pod_file_ok(@_) (Test::Pod is required)", 1 }
  };
}
if (!eval 'use Test::Pod::Coverage; 1') {
  *Test::Pod::Coverage::pod_coverage_ok = sub {
  SKIP: { skip "pod_coverage_ok(@_) (Test::Pod::Coverage is required)", 1 }
  };
}
if (!eval 'use Test::CPAN::Changes; 1') {
  *Test::CPAN::Changes::changes_file_ok = sub {
  SKIP: { skip "changes_ok(@_) (Test::CPAN::Changes is required)", 4 }
  };
}

my @search_dirs = grep { -d $_ } ('lib', 'blib');
find(
  {
    wanted => sub {
      return if $_                =~ /^[._]/;
      return if $File::Find::name =~ m{/(?:[._])};
      return unless /\.pm$/;
      push @files, $File::Find::name;
    },
    preprocess => sub {
      grep { $_ !~ /^[._]/ } @_;
    },
    no_chdir => 1
  },
  @search_dirs
);

plan tests => @files * 3 + 4;

for my $file (@files) {
  my $module = $file;
  $module =~ s,\.pm$,,;
  $module =~ s,.*/?lib/,,;
  $module =~ s,/,::,g;
  ok eval "use $module; 1", "use $module" or diag $@;
  Test::Pod::pod_file_ok($file);
  Test::Pod::Coverage::pod_coverage_ok($module,
    {also_private => [qr/^[A-Z_]+$/, 'puke'],});
}

Test::CPAN::Changes::changes_file_ok();

# This file from "Mojo::mysql" repository
