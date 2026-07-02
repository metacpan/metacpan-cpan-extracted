package SPVM::Resource::Coro;

our $VERSION = "0.001";

1;

=encoding utf8

=head1 Name

SPVM::Resource::Coro - libcoro Resources

=head1 Description

Resource::Coro class in L<SPVM> is a L<resource|SPVM::Document::Resource> class for libcoro.

=head1 Usage

MyClass.config:
  
  my $config = SPVM::Builder::Config->new_c99;
  
  $config->use_resource('Resource::Coro');
  
  $config->add_define(@{$config->get_resource('Resource::Coro')->config->defines});
  
  $config;

MyClass.c:

  #include "spvm_native.h"
  #include "coro.h"
  
  int32_t SPVM__MyClass__test(SPVM_ENV* env, SPVM_VALUE* stack) {
    
    coro_context ctx;
    
    return 0;
  }
  
=head1 Original Product

L<libcoro|http://software.schmorp.de/pkg/libcoro.html>

=head1 Original Product Version

Use the code bundled in L<Coro 6.57|https://metacpan.org/release/MLEHMANN/Coro-6.57> on CPAN.

=head1 Language

C language

=head1 Language Standard

C99

=head1 Header Files

=over 2

=item * C<coro.h>

=back

=head1 Source Files

=over 2

=item * C<coro.c>

=back

=head1 Compiler Flags

The compiler flags are automatically configured based on the OS and its environment to ensure the correct context switching mechanism (e.g., C, C<setjmp/longjmp>, or C).

Typical flags include:

=over 2

=item * C<-DCORO_UCONTEXT> (used when C<ucontext.h> is available)

=item * C<-DCORO_SJLJ> (used for C<setjmp/longjmp> based switching)

=item * C<-DCORO_ASM> (used for assembly-based switching)

=item * C<-DCORO_PTHREAD> (used when C are required)

=item * C<-D_FORTIFY_SOURCE=0> (often required for C<setjmp/longjmp> stability)

=back

The actual flags applied are determined at build-time by detecting the target platform and specific system requirements (such as thread support and stack alignment).

Flags starting with C<-D> can be retrieved from C<defines> field without the -D prefix.

=head1 How to Create Resource

=head2 Donwload

  mkdir -p .tmp
  curl -L https://cpan.metacpan.org/authors/id/M/ML/MLEHMANN/Coro-6.57.tar.gz | tar -xz -C .tmp

=head2 Extracting Source Files

  cp .tmp/Coro-6.57/Coro/libcoro/coro.h lib/SPVM/Resource/Coro.native/include/

=head2 Extracting Header Files

  cp .tmp/Coro-6.57/Coro/libcoro/coro.c lib/SPVM/Resource/Coro.native/src/

=head2 Apply Patch

  patch -p1 < coro_fix.patch

=head1 Repository

L<SPVM::Resource::Coro - Github|https://github.com/yuki-kimoto/SPVM-Resource-Coro>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2026 Yuki Kimoto

MIT License

