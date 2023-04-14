package SPVM::Resource::Libpng;

our $VERSION = '0.01';

1;

=head1 Name

SPVM::Resource::Libpng - The Resource of The libpng Library

=head1 Description

SPVM::Resource::Libpng is a L<resource|SPVM::Document::Resource> of L<SPVM> for the L<libpng|https://github.com/glennrp/libpng> library.

=head1 Usage

MyClass.config:

  my $config = SPVM::Builder::Config->new_c99(file => __FILE__);
  
  $config->use_resource('Resource::Zlib');
  $config->use_resource('Resource::Libpng');
  
  $config;

MyClass.c:

  #include <png.h>
  
  int32_t SPVM__MyClass__test(SPVM_ENV* env, SPVM_VALUE* stack) {
    
    png_colorp palette;
    
    return 0;
  }

=head1 Original Product

L<libpng|https://github.com/glennrp/libpng>

=head1 Original Product Version

L<libpng v1.6.39|https://github.com/glennrp/libpng/releases/tag/v1.6.39>

=head1 Language

The C language

=head1 Language Specification

C99

=head1 Required Resources

=over 2

=item * L<SPVM::Resource::Zlib>

=back

=head1 Header Files

=over 2

=item * C<pngconf.h>

=item * C<pngdebug.h>

=item * C<png.h>

=item * C<pnginfo.h>

=item * C<pnglibconf.h>

=item * C<pngpriv.h>

=item * C<pngstruct.h>

=back

=head1 Source Files

=over 2

=item * C<png.c>

=item * C<pngerror.c>

=item * C<pngget.c>

=item * C<pngmem.c>

=item * C<pngpread.c>

=item * C<pngread.c>

=item * C<pngrio.c>

=item * C<pngrtran.c>

=item * C<pngrutil.c>

=item * C<pngset.c>

=item * C<pngtest.c>

=item * C<pngtrans.c>

=item * C<pngwio.c>

=item * C<pngwrite.c>

=item * C<pngwtran.c>

=item * C<pngwutil.c>

=back

=head1 How to Create Resource

=head2 Donwload

  mkdir -p original.tmp
  git clone https://github.com/glennrp/libpng.git original.tmp/libpng
  git -C original.tmp/libpng checkout tags/v1.6.39 -b branch_v1.6.39
  git -C original.tmp/libpng branch

=head1 Extracting Header Files

The header files of C<libpng> is copied into the C<include> directory by the following command.

  rsync -av --include='*.h' --exclude='*' original.tmp/libpng/ lib/SPVM/Resource/Libpng.native/include/
  
  cp lib/SPVM/Resource/Libpng.native/src/scripts/pnglibconf.h.prebuilt lib/SPVM/Resource/Libpng.native/include/pnglibconf.h

=head2 Extracting Source Files

The source files of C<libpng> are copied into the C<src> directory by the following command.

  rsync -av --exclude='*.h' original.tmp/libpng/ lib/SPVM/Resource/Libpng.native/src/

The used L<source files|/"Source Files"> are extracted by the following command.

  find lib/SPVM/Resource/Libpng.native/src/* | perl -p -e 's|^\Qlib/SPVM/Resource/Libpng.native/src/||' | grep -P '^\w+\.c$' | grep -v -P '^example\.c'

=head1 Repository

L<SPVM::Resource::Libpng - Github|https://github.com/yuki-kimoto/SPVM-Resource-Libpng>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
