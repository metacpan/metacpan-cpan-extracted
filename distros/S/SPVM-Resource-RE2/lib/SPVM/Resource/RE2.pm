package SPVM::Resource::RE2;

our $VERSION = "0.043";

1;

=head1 Name

SPVM::Resource::RE2 - The Resource of Google/RE2

=head1 Description

SPVM::Resource::RE2 class in L<SPVM> is a L<resource|SPVM::Document::Resource> class for the L<Google/RE2|https://github.com/google/re2>.

=head1 Usage

MyClass.config:
  
  my $config = SPVM::Builder::Config->new_cpp17(file => __FILE__);
  my $resource = $config->use_resource('Resource::RE2');
  
  if ($^O eq 'MSWin32') {
    $config->add_static_lib('stdc++', 'winpthread', 'gcc');
  }
  else {
    $config->add_lib('stdc++');
  }
  
  $config->add_ldflag('-pthread');
  
  $config;

MyClass.cpp:

  #include "re2/re2.h"
  
  extern "C" {
  
  int32_t SPVM__MyClass__test(SPVM_ENV* env, SPVM_VALUE* stack) {
    
    int32_t match = RE2::PartialMatch("abcde", "bcd");
    
    return 0;
  }
  
  }

=head1 Original Product

L<Google/RE2|https://github.com/google/re2>

=head1 Original Product Version

L<Google/RE2 2023-02-01|https://github.com/google/re2/releases/tag/2023-02-01>

=head1 Language

C++

=head1 Language Specification

C++17

=head1 Required Libraries

Windows:

=over 2

=item * stdc++ (The static link is preffered)

=item * winpthread (The static link is preffered)

=item * gcc (The static link is preffered)

=back

Unix/Linux/Mac:

=over 2

=item * stdc++

=back

=head1 Required Linker Flags

=over 2

=item * -pthread

=back

=head1 Header Files

=over 2

=item * util/logging.h

=item * util/test.h

=item * util/mix.h

=item * util/util.h

=item * util/mutex.h

=item * util/strutil.h

=item * util/malloc_counter.h

=item * util/pcre.h

=item * util/flags.h

=item * util/utf.h

=item * util/benchmark.h

=item * re2/prefilter.h

=item * re2/re2.h

=item * re2/sparse_set.h

=item * re2/unicode_casefold.h

=item * re2/filtered_re2.h

=item * re2/pod_array.h

=item * re2/stringpiece.h

=item * re2/prefilter_tree.h

=item * re2/bitmap256.h

=item * re2/sparse_array.h

=item * re2/set.h

=item * re2/regexp.h

=item * re2/testing/regexp_generator.h

=item * re2/testing/tester.h

=item * re2/testing/exhaustive_tester.h

=item * re2/testing/string_generator.h

=item * re2/walker-inl.h

=item * re2/fuzzing/compiler-rt/include/fuzzer/FuzzedDataProvider.h

=item * re2/unicode_groups.h

=item * re2/prog.h

=back

=head1 Source Files

=over 2

=item * re2/dfa.cc

=item * re2/prefilter_tree.cc

=item * re2/stringpiece.cc

=item * re2/bitstate.cc

=item * re2/unicode_casefold.cc

=item * re2/simplify.cc

=item * re2/filtered_re2.cc

=item * re2/onepass.cc

=item * re2/bitmap256.cc

=item * re2/re2.cc

=item * re2/parse.cc

=item * re2/set.cc

=item * re2/prog.cc

=item * re2/prefilter.cc

=item * re2/mimics_pcre.cc

=item * re2/regexp.cc

=item * re2/nfa.cc

=item * re2/tostring.cc

=item * re2/perl_groups.cc

=item * re2/unicode_groups.cc

=item * re2/compile.cc

=item * util/strutil.cc

=item * util/rune.cc

=item * util/pcre.cc

=back

=head1 Compiler Flags

=over 2

=item * -pthread

=item * -Wno-unused-parameter

=item * -Wno-missing-field-initializers

=back

=head1 How to Create Resource

=head2 Download

  mkdir -p .tmp
  git clone https://github.com/google/re2.git .tmp/re2
  git -C .tmp/re2 checkout tags/2023-02-01 -b branch_2023-02-01
  git -C .tmp/re2 branch

=head2 Extracting Source Files

All files of C<Google/RE2> is copied by the following steps into the C<src> directory.

  rsync -av --exclude='*.h' .tmp/re2/ lib/SPVM/Resource/RE2.native/src/

The source files that is used in the config are extracted by the following command.

  find lib/SPVM/Resource/RE2.native/src/* | perl -p -e 's|^\Qlib/SPVM/Resource/RE2.native/src/||' | grep -P '(util|re2)/\w+\.cc$' | grep -v -P 'util/(test|benchmark|fuzz)\.cc$'

=head1 Extracting Header Files

Header files of C<Google/RE2> is copied into the C<include> directory by the following way.

  rsync -av --include='*/' --include='*.h' --exclude='*' .tmp/re2/ lib/SPVM/Resource/RE2.native/include/

=head1 Repository

L<SPVM::Resource::RE2 - Github|https://github.com/yuki-kimoto/SPVM-Resource-RE2>

=head1 Author

YuKi Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

