package SPVM::Resource::Zlib;

our $VERSION = "1.001";

1;

=head1 Name

SPVM::Resource::Zlib - Resource of zlib Library

=head1 Description

SPVM::Resource::Zlib is a L<resource|SPVM::Document::Resource> of L<SPVM> for the L<zlib|https://github.com/madler/zlib> library.

=head1 Usage

MyClass.config:
  
  my $config = SPVM::Builder::Config->new_c99(file => __FILE__);

  $config->use_resource('Resource::Zlib');

  $config;

MyClass.c:
  
  #include <zlib.h>
  
  const char* file = "foo.gz";
  
  gzFile gz_fh = gzopen(file, "rb");

=head1 Original Product

L<zlib|https://github.com/madler/zlib>

=head1 Original Product Version

L<zlib v1.2.13|https://github.com/madler/zlib/releases/tag/v1.2.13>

=head1 Language

The C language

=head1 Language Specification

C99

=head1 Header Files

=over 2

=item * C<spvm_socket_util.h>

=item * C<crc32.h>

=item * C<deflate.h>

=item * C<gzguts.h>

=item * C<inffast.h>

=item * C<inffixed.h>

=item * C<inflate.h>

=item * C<inftrees.h>

=item * C<trees.h>

=item * C<zconf.h>

=item * C<zlib.h>

=item * C<zutil.h>

=back

=head1 Source Files

=over 2

=item * C<adler32.c>

=item * C<compress.c>

=item * C<crc32.c>

=item * C<deflate.c>

=item * C<gzclose.c>

=item * C<gzlib.c>

=item * C<gzread.c>

=item * C<gzwrite.c>

=item * C<infback.c>

=item * C<inffast.c>

=item * C<inflate.c>

=item * C<inftrees.c>

=item * C<trees.c>

=item * C<uncompr.c>

=item * C<zutil.c>

=back

=head1 Compiler Flags

=over 2

=item * -D_LARGEFILE64_SOURCE

=back

=head1 How to Create Resource

=head2 Download

  mkdir -p original.tmp
  git clone https://github.com/madler/zlib original.tmp/zlib
  git -C original.tmp/zlib checkout tags/v1.2.13 -b branch_v1.2.13
  git -C original.tmp/zlib branch

=head1 Extracting Header Files

The header files of C<zlib> is copied into the C<include> directory by the following command.

  rsync -av --include='*.h' --exclude='*' original.tmp/zlib/ lib/SPVM/Resource/Zlib.native/include/

=head2 Extracting Source Files

The source files of C<zlib> are copied into the C<src> directory by the following command.

  rsync -av --exclude='*.h' original.tmp/zlib/ lib/SPVM/Resource/Zlib.native/src/

The used L<source files|/"Source Files"> are extracted by the following command.

  find lib/SPVM/Resource/Zlib.native/src/* | perl -p -e 's|^\Qlib/SPVM/Resource/Zlib.native/src/||' | grep -P '^\w+\.c$'

=head1 Repository

L<SPVM::Resource::Zlib - Github|https://github.com/yuki-kimoto/SPVM-Resource-Zlib>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
