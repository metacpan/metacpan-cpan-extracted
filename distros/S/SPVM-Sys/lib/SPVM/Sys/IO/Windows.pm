package SPVM::Sys::IO::Windows;



1;

=head1 Name

SPVM::Sys::IO::Windows - IO System Call on Windows

=head1 Description

C<SPVM::Sys::IO::Windows> is the C<Sys::IO::Windows> class in L<SPVM> language.

=head1 Usage

  use Sys::IO::Windows;

=head1 Class Methods

=head2 is_symlink

  native static method is_symlink : int ($path : string);

The same as Perl L<-l|https://perldoc.perl.org/functions/-X> on Windows.

=head2 unlink

  native static method unlink : int ($pathname : string);

The same as Perl L<rename|https://perldoc.perl.org/functions/unlink> on Windows.

=head2 rename

  static method rename : int ($oldpath : string, $newpath : string);

The same as Perl L<rename|https://perldoc.perl.org/functions/rename> on Windows.

=head2 readlink

  native static method readlink : int ($path : string, $buf : mutable string, $bufsiz : int);

The same as Perl L<readlink|https://perldoc.perl.org/functions/readlink> on Windows.

=head2 get_readlink_buffer_size

  native static method get_readlink_buffer_size : int ($path : string);

Gets the L</"readlink"> needed buffer size.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

