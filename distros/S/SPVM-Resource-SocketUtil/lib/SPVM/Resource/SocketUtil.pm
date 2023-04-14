package SPVM::Resource::SocketUtil;

our $VERSION = '0.03';

1;

=head1 Name

SPVM::Resource::SocketUtil - Resource for Socket Utilities

=head1 Description

SPVM::Resource::SocketUtil is a L<resource|SPVM::Document::Resource> of L<SPVM> for socket utilities.

=head1 Usage

MyClass.config:
  
  my $config = SPVM::Builder::Config->new_c99(file => __FILE__);
  
  $config->use_resource('Resource::SocketUtil');
  
  if ($^O eq 'MSWin32') {
    $config->add_lib('wsock32', 'ws2_32');
  }
  
  $config;

MyClass.c:
  
  # include "spvm_socket_util.h"
  
  int32_t socket_errno = spvm_socket_errno();

=head1 Language

The C language

=head1 Language Specification

C99

=head1 Required Libraries

=over 2

=item * C<wsock32> (Only on Windows)

=item * C<ws2_32> (Only on Windows)

=back

=head1 Header Files

=over 2

=item * C<spvm_socket_util.h>

=back

=head1 Source Files

=over 2

=item * C<spvm_socket_util.c>

=back

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License
