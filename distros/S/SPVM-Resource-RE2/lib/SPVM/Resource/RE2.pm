package SPVM::Resource::RE2;

our $VERSION = '0.03';

1;

=head1 Name

SPVM::Resource::RE2 - Google/RE2 Resource

=head1 Description

C<SPVM::Resource::RE2> is the C<Resource::RE2> class in L<SPVM>. This is a L<SPVM resource|SPVM::Document::Resource> of L<Google/RE2|https://github.com/google/re2>.

L<Google/RE2|https://github.com/google/re2> is a regular expression library written by C<C++>.

=head1 Usage

MyRE2.config:
  
  my $config = SPVM::Builder::Config->new_cpp17(file => __FILE__);
  my $resource = $config->use_resource('Resource::RE2');
  
  if ($^O eq 'MSWin32') {
    $config->add_static_libs('stdc++', 'winpthread', 'gcc');
  }
  else {
    $config->add_libs('stdc++');
  }
  
  $config->add_ldflags('-pthread');
  
  $config;

MyRE2.spvm:

  class MyRE2 {
    native static method match : int ();
  }

MyRE2.cpp:

  #include "spvm_native.h"
  
  #include "re2/re2.h"
  
  extern "C" {
  
  int32_t SPVM__MyRE2__match(SPVM_ENV* env, SPVM_VALUE* stack) {
    
    if (RE2::PartialMatch("abcde", "bcd")) {
      stack[0].ival = 1;
    }
    else {
      stack[0].ival = 0;
    }
    
    return 0;
  }
  
  }

myre2.pl:

  use FindBin;
  use lib "$FindBin::Bin";
  use SPVM 'MyRE2';
  
  my $match = SPVM::MyRE2->match;

=head1 Library Version

L<Google/RE2 2023-02-01|https://github.com/google/re2/releases/tag/2023-02-01>.

If a new release exists, it will be upgraded.

=head1 User Config

Recommended user config:

  my $config = SPVM::Builder::Config->new_cpp17(file => __FILE__);
  my $resource = $config->use_resource('Resource::RE2');
  
  if ($^O eq 'MSWin32') {
    $config->add_static_libs('stdc++', 'winpthread', 'gcc');
  }
  else {
    $config->add_libs('stdc++');
  }
  
  $config->add_ldflags('-pthread');

=head1 Resource Config

  my $config = SPVM::Builder::Config->new_cpp17(file => __FILE__);
  
  $config->add_ccflags('-pthread', '-Wno-unused-parameter', '-Wno-missing-field-initializers');
  
  $config->ext('cc');
  
  my @source_files = qw(
    re2/dfa.cc
    re2/prefilter_tree.cc
    re2/stringpiece.cc
    re2/bitstate.cc
    re2/unicode_casefold.cc
    re2/simplify.cc
    re2/filtered_re2.cc
    re2/onepass.cc
    re2/bitmap256.cc
    re2/re2.cc
    re2/parse.cc
    re2/set.cc
    re2/prog.cc
    re2/prefilter.cc
    re2/mimics_pcre.cc
    re2/regexp.cc
    re2/nfa.cc
    re2/tostring.cc
    re2/perl_groups.cc
    re2/unicode_groups.cc
    re2/compile.cc
    util/strutil.cc
    util/rune.cc
    util/pcre.cc
  );
  
  $config->add_source_files(@source_files);

=head1 How to Create This Resource

=head2 Getting Product

  mkdir -p original.tmp
  git clone https://github.com/google/re2.git original.tmp/re2
  git -C original.tmp/re2 checkout tags/2023-02-01 -b 2023-02-01
  git -C original.tmp/re2 branch

=head2 Source Files

All files of C<Google/RE2> is copied by the following steps into the C<src> directory.

  rsync -av --exclude='*.h' original.tmp/re2/ lib/SPVM/Resource/RE2.native/src/

=head1 Header Files

Header files of C<Google/RE2> is copied into the C<include> directory by the following way.

  rsync -av --include='*/' --include='*.h' --exclude='*' original.tmp/re2/ lib/SPVM/Resource/RE2.native/include/

=head2 Extracting Source Files

The source files that is used in the config are extracted by the following command.

  find lib/SPVM/Resource/RE2.native/src/* | perl -p -e 's|^\Qlib/SPVM/Resource/RE2.native/src/||' | grep -P '(util|re2)/\w+\.cc$' | grep -v -P 'util/(test|benchmark|fuzz)\.cc$'

=head1 Repository

L<SPVM::Resource::RE2 - Github|https://github.com/yuki-kimoto/SPVM-Resource-RE2>

=head1 Author

YuKi Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2023-2023 YuKi Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
