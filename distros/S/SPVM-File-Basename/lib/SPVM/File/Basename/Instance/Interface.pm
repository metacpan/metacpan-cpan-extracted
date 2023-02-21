package SPVM::File::Basename::Instance::Interface;



1;

=head1 Name

SPVM::File::Basename::Instance::Interface - File::Basename::Instance Interface

=head1 Description

C<SPVM::File::Basename::Instance::Interface> is the C<File::Basename::Instance::Interface> class in L<SPVM> language.

This class is the L<File::Basename::Instance|SPVM::File::Basename::Instance> interface.

=head1 Usage

  use File::Basename::Instance::Interface;

=head1 Interface Methods

=head2 fileparse

  method fileparse : string[] ($path : string);

=head2 basename

  method basename : string ($path : string);

=head2 dirname

  method dirname : string ($path : string);

=head2 has_interfaces

  required method has_interfaces : int ();

=head1 Well Known Implementation Classes

=over 2

=item * L<File::Basename::Instance|SPVM::File::Basename::Instance>

=back

=head1 Copyright & License

Copyright 2023-2023 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
