package SPVM::File::Find::Handler;



1;

=head1 Name

SPVM::File::Find::Handler - Handler for File::Find

=head1 Description

C<SPVM::File::Find::Handler> is the C<File::Find::Handler> class in L<SPVM> language.

This class is the handler for L<find|SPVM::File::Find/"find"> method in the L<File::Find|SPVM::File::Find>.

=head1 Usage

  use File::Find::Handler;

=head1 Interface Methods

  required method : void ($dir : string, $file_base_name : string);

=head1 Copyright & License

Copyright 2023-2023 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
