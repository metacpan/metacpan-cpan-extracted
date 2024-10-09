package SPVM::IO;

our $VERSION = "0.220001";

1;

=head1 Name

SPVM::IO - File IO, Sockets, Select/Polling.

=head1 Description

Classes in IO distribution in L<SPVM> has methods to manipulate File IO, Sockets, Select/Polling.

=head1 Modules

=over 2 

=item * L<IO::Handle|SPVM::IO::Handle>

=item * L<IO::File|SPVM::IO::File>

=item * L<IO::Socket|SPVM::IO::Socket>

=item * L<IO::Socket::IP|SPVM::IO::Socket::IP>

=item * L<IO::Socket::INET|SPVM::IO::Socket::INET>

=item * L<IO::Socket::INET6|SPVM::IO::Socket::INET6>

=item * L<IO::Socket::UNIX|SPVM::IO::Socket::UNIX>

=item * L<IO::Select|SPVM::IO::Select>

=item * L<IO::Poll|SPVM::IO::Poll>

=item * L<IO::Dir|SPVM::IO::Dir>

=back

=head1 Class Methods

=head2 open

C<static method open : L<IO::File|SPVM::IO::File> ($open_mode : string, $file_name : string);>

Opens a file stream.

This method just calls L<IO::File#new|SPVM::IO::File/"new"> method given $file_name $open_mode, returns its return value.

Exceptions:

Exceptions thrown by L<IO::File#new|SPVM::IO::File/"new"> method could be thrown.

=head2 opendir

C<static method opendir : L<IO::Dir|SPVM::IO::Dir> ($dir_path : string);>

Opens a directory stream.

This method just calls L<IO::Dir#new|SPVM::IO::Dir/"new"> method given $dir_path and returns its return value.

Exceptions:

Exceptions thrown by L<IO::Dir#new|SPVM::IO::Dir/"new"> method could be thrown.

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

