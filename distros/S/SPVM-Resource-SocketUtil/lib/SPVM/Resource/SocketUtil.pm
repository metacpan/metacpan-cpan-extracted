package SPVM::Resource::SocketUtil;

our $VERSION = '0.02';

1;

=head1 Name

SPVM::Resource::SocketUtil - The Resource for Socket Utilities

=head1 Description

C<SPVM::Resource::SocketUtil> is the L<SPVM>'s C<Resource::SocketUtil> L<resource|SPVM::Document::Resource> for socket utilities.

=head1 Usage

  # MyClass.config
  $config->use_resource('Resource::SocketUtil');

=head1 Library Dependencies

On Windows, the C<wsock32> and C<ws2_32> libraries are needed.

if ($^O eq 'MSWin32') {
  $config->add_libs('wsock32', 'ws2_32');
}

=head1 Headers

=head2 spvm_socket_util.h

  #include "spvm_socket_util.h"

=head1 Sources

=head2 spvm_socket_util.c

  cc spvm_socket_util.c

=head1 Functions

=head2 spvm_socket_util.h

=head3 spvm_socket_errno

  int32_t spvm_socket_errno (void);

=head3 spvm_socket_strerror_string

  void* spvm_socket_strerror_string (SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length);

=head3 spvm_socket_strerror

  const char* spvm_socket_strerror(SPVM_ENV* env, SPVM_VALUE* stack, int32_t error_number, int32_t length);

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

