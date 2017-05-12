use 5.010001;

use strict;
use warnings;
use ExtUtils::MakeMaker;

use Config;

# Decide cpp compiler
my @cpp_compilers = ('c++', 'g++', 'CC');
my $found_cpp_compiler;
for my $cpp_compiler (@cpp_compilers) {
  # Check if command exists
  if (system($cpp_compiler) != -1) {
    $found_cpp_compiler = $cpp_compiler;
    last;
  }
}
unless ($found_cpp_compiler) {
  die "Can't find c++ compiler";
}
my $cc = $found_cpp_compiler;
my $ld = $found_cpp_compiler;

WriteMakefile(
    NAME                => 'Rstats',
    AUTHOR              => 'Yuki Kimoto <kimoto.yuki@gmail.com>',
    VERSION_FROM        => 'lib/Rstats.pm',
    ABSTRACT_FROM       => 'lib/Rstats.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    META_MERGE   => {
      requires  => {perl => '5.010001'},
      resources => {
        license    => 'http://www.opensource.org/licenses/artistic-license-2.0',
        bugtracker => 'https://github.com/yuki-kimoto/Rstats/issues',
        repository => 'https://github.com/yuki-kimoto/Rstats.git'
      }
    },
    PREREQ_PM => {
        'Object::Simple' => '3.10',
        'Math::Round' => '0.06',
        'Text::UnicodeTable::Simple' => '0.09'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Rstats-*' },
    CC => $cc,
    OPTIMIZE => '-O3',
    LD => $ld,
    LIBS              => [],
    DEFINE            => '',
    INC               => '-I. -I./Rstats_lib/include',
    H => ['ppport.h', glob('Rstats_lib/include/*.h')],
    C => ['Rstats.c', glob('Rstats_lib/src/*.cpp')],
    OBJECT            => '$(O_FILES)',
    DEFINE => '-o $@'
);
