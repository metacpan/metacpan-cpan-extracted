package SPVM::Resource::Zlib;

our $VERSION = '0.01';

1;

=head1 NAME

SPVM::Resource::Zlib - zlib Resource

=head1 DESCRIPTION

C<SPVM::Resource::Zlib> is the document of the L<resource|SPVM::Document::Resource> of the L<zlib|https://zlib.net/"> library.

=head1 SYNOPSYS

B<MyZlib.pl>

  use strict;
  use warnings;
  use FindBin;

  use lib "$FindBin::Bin/lib";

  use SPVM 'MyZlib';

  my $gz_file = "$FindBin::Bin/minitest.txt.gz";

  SPVM::MyZlib->test_gzopen_gzread($gz_file);

B<lib/SPVM/MyZlib.spvm>

  class MyZlib {
    native static method test_gzopen_gzread : void ($file : string);
  }

B<lib/SPVM/MyZlib.config>

  use strict;
  use warnings;

  my $config = SPVM::Builder::Config->new_gnu99(file => __FILE__);

  $config->use_resource('Resource::Zlib::V1_2_11');

  $config;

B<lib/SPVM/MyZlib.c>

  #include "spvm_native.h"

  #include <zlib.h>

  int32_t SPVM__MyZlib__test_gzopen_gzread(SPVM_ENV* env, SPVM_VALUE* stack) {
    (void)env;
    
    void* sp_file = stack[0].oval;
    
    const char* file = env->get_chars(env, sp_file);
    
    z_stream z;

    gzFile gz_fh = gzopen(file, "rb");
    
    if (gz_fh == NULL){
      return env->die(env, "Can't open file \"%s\"\n", file);
    }
    
    char buffer[256] = {0};
    int32_t cnt;
    while((cnt = gzread(gz_fh, buffer, sizeof(buffer))) > 0){

    }

    printf("%s", buffer);
    
    return 0;
  }

=head1 RESOURCES

The list of C<zlib> resources.

=over 2

* L<SPVM::Resource::Zlib::V1_2_11> - zlib v1.2.11

=back

