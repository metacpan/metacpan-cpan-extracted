package SPVM::Resource::Utf8proc;

our $VERSION = "0.003";

1;

=head1 Name

SPVM::Resource::Utf8proc - Bundle of the utf8proc library

=head1 Description

Resource::Utf8proc class in L<SPVM> is a L<resouce|SPVM::Document::Resource> class for L<utf8proc|https://github.com/JuliaStrings/utf8proc> library.

=head1 Usage

MyClass.config:
  
  my $config = SPVM::Builder::Config->new_gnu99(file => __FILE__);
  
  $config->use_resource('Resource::Utf8proc');
  
  $config->add_ccflag('-DUTF8PROC_STATIC');
  
  $config;

MyClass.c:

  #include "spvm_native.h"
  
  #include "utf8proc.h"
  
  int32_t SPVM__MyClass__test(SPVM_ENV* env, SPVM_VALUE* stack) {
    
    const char* string = "あいう";
    
    char* string_ret_tmp = NULL;
    
    int32_t string_ret_length = utf8proc_map(string, 0, &string_ret_tmp, UTF8PROC_NULLTERM | UTF8PROC_STABLE |
    UTF8PROC_COMPOSE);
    
    return 0;
  }
  
=head1 Original Product

The L<utf8proc|https://github.com/JuliaStrings/utf8proc> library.

=head1 Original Product Version

v2.9.0

=head1 Language

The C language

=head1 Language Specification

GNU C99

=head1 Required Compiler Flags

=over 2

=item * -DUTF8PROC_STATIC

=back

=head1 Header Files

=over 2

=item * utf8proc.h

=item * utf8proc_data.c (This is an included C source file)

=back

=head1 Source Files

=over 2

=item * utf8proc.c

=back

=head1 Compiler Flags

=over 2

=item * -DUTF8PROC_STATIC

=back

=head1 How to Create Resource

=head2 Download
  
  mkdir -p .tmp
  git clone https://github.com/JuliaStrings/utf8proc.git .tmp/utf8proc
  git -C .tmp/utf8proc checkout tags/v2.9.0 -b branch_v2.9.0
  
  # Check the current branch
  git -C .tmp/utf8proc branch

=head2 Extracting Header Files

The header files of C<utf8proc> is copied into the C<include> directory by the following command.

  rsync -av --include='*.h' --exclude='*' .tmp/utf8proc/ lib/SPVM/Resource/Utf8proc.native/include/
  cp .tmp/utf8proc/utf8proc_data.c lib/SPVM/Resource/Utf8proc.native/include/utf8proc_data.c

=head2 Extracting Source Files

The source files of C<utf8proc> are copied into the C<src> directory by the following command.

  cp .tmp/utf8proc/utf8proc.c lib/SPVM/Resource/Utf8proc.native/src/utf8proc.c

=head1 Repository

L<SPVM::Resource::Utf8proc - Github|https://github.com/yuki-kimoto/SPVM-Resource-Utf8proc>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

