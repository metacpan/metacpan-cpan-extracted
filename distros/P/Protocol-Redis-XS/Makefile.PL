use strict;
use warnings;
use ExtUtils::MakeMaker 6.31;
use ExtUtils::Depends;

my $pkg = ExtUtils::Depends->new("Protocol::Redis::XS", "XS::Object::Magic");
$pkg->set_inc("-Ihiredis");
my %dep = $pkg->get_makefile_vars;

# Workaround bugs in the toolchain so we can actually build things in
# directories.
my $my_xs = q[XS$(OBJ_EXT)];
my @hiredis_files = map "$_\$(OBJ_EXT)", qw(hiredis sds net);
my $hiredis_obj = join " ", map 'hiredis/' . $_, @hiredis_files;

WriteMakefile(
  NAME          => 'Protocol::Redis::XS',
  AUTHOR        => 'David Leadbeater <dgl@dgl.cx>',
  LICENSE       => 'perl',
  ABSTRACT_FROM => 'lib/Protocol/Redis/XS.pm',
  VERSION_FROM  => 'lib/Protocol/Redis/XS.pm',

  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '6.31',
    'ExtUtils::Depends' => 0,
    'XS::Object::Magic' => 0,
  },

  BUILD_REQUIRES => {
    'Test::More' => '0.88',
    'Protocol::Redis' => '0.9001',
  },

  PREREQ_PM => {
    'XSLoader' => 0,
    'XS::Object::Magic' => 0,
    'Protocol::Redis' => '0.9001',
    'parent' => 0,
  },

  INC      => $dep{INC},
  TYPEMAPS => $dep{TYPEMAPS},
  OBJECT   => "$my_xs $hiredis_obj",
  LDFROM   => "$my_xs " . join(" ", @hiredis_files),

  META_MERGE => {
    resources        => {
      repository     => 'https://github.com/dgl/protocol-redis-xs',
    }
  }
);
