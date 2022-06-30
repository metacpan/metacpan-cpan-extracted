package SPVM::Resource::Re2::V2022_06_01;

our $VERSION = '0.02';

1;

=head1 Name

SPVM::Resource::Re2::V2022_06_01 - Resource of RE2 2022-06-01.

=head1 Synopsys

C<MyRe2.spvm>

  class MyRe2 {
    native static method match : int ();
  }

C<MyRe2.cpp>

  #include "spvm_native.h"
  
  #include "re2/re2.h"
  
  extern "C" {
  
  int32_t SPVM__MyRe2__match(SPVM_ENV* env, SPVM_VALUE* stack) {
    
    if (RE2::PartialMatch("abcde", "bcd")) {
      stack[0].ival = 1;
    }
    else {
      stack[0].ival = 0;
    }
    
    return 0;
  }
  
  }

C<MyRe2.config>

  use strict;
  use warnings;
  
  my $config = SPVM::Builder::Config->new_cpp11(file => __FILE__);
  
  $config->use_resource('Resource::Re2::V2022_06_01');
  
  $config;

C<myre2.pl>

  use FindBin;
  use lib "$FindBin::Bin";
  use SPVM 'MyRe2';
  
  my $match = SPVM::MyRe2->match;

=head1 Description

C<Resource::Re2::V2022_06_01> is a L<SPVM> module to provide the resource of L<RE2|https://github.com/google/re2> L<2022-06-01|https://github.com/google/re2/releases/tag/2022-06-01>.

L<RE2|https://github.com/google/re2> is a regular expression library written by C<C++>. Google created it.

See L<SPVM::Document::NativeModule> and L<SPVM::Document::Resource> to write native modules and use resources.

=head1 Caution

L<SPVM> is yet development status.

=head1 Config

The config of C<Resource::Re2::V2022_06_01>.

  use strict;
  use warnings;
  use SPVM::Builder::Config;

  my $config = SPVM::Builder::Config->new_cpp11(file => __FILE__);

  $config->ext('cc');

  my @source_files = qw(
    util/strutil.cc
    util/rune.cc
    util/pcre.cc
    re2/dfa.cc
    re2/prefilter_tree.cc
    re2/stringpiece.cc
    re2/bitstate.cc
    re2/unicode_casefold.cc
    re2/simplify.cc
    re2/filtered_re2.cc
    re2/onepass.cc
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
  );

  $config->add_source_files(@source_files);

  $config;

=head1 Source and Header Files

The source and header files are created by the following process.

=head2 src

All files of L<RE2 2022-06-01|https://github.com/google/re2/releases/tag/2022-06-01> are copiedinto C<SPVM/Resource/Re2/V2022_06_01.native/src>.

=head2 include

All header files of L<RE2 2022-06-01|https://github.com/google/re2/releases/tag/2022-06-01> are copied into C<SPVM/Resource/Re2/V2022_06_01.native/include> in the following command.

  rsync -av --include='*/' --include='*.h' --exclude='*' lib/SPVM/Resource/Re2/V2022_06_01.native/src/ lib/SPVM/Resource/Re2/V2022_06_01.native/include/

=head2 Extracting Source Filess

The source files that is used in the config are extracted by the following command.

  find * | grep -P '(util|re2)/\w+\.cc$' | grep -v -P 'util/(test|benchmark|fuzz)\.cc$' | grep -v blib

=head1 Repository

L<https://github.com/yuki-kimoto/SPVM-Resource-Re2-V2022_06_01>

=head1 Author

YuKi Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2022-2022 YuKi Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
