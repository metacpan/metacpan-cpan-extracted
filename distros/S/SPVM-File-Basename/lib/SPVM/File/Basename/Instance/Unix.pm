package SPVM::File::Basename::Instance::Unix;



1;

=head1 Name

SPVM::File::Basename::Instance::Unix - File::Basename::Instance Implementation for Linux, UNIX, and Mac.

=head1 Description

C<SPVM::File::Basename::Instance::Unix> is the C<File::Basename::Instance::Unix> class in L<SPVM> language.

This class is a child class of the L<File::Basename::Instance|SPVM::File::Basename::Instance> class for Linux, UNIX, and Mac.

=head1 Usage

  use File::Basename::Instance::Unix;

  my $fb = File::Basename::Instance::Unix->new;

=head1 Inheritance

=over 2

=item * L<File::Basename::Instance|SPVM::File::Basename::Instance>

=back

=head1 Class Methods

=head2 new

  static method new : File::Basename::Instance::Unix ();

=head1 Instance Methods

=head2 fileparse

  method fileparse : string[] ($path : string);

=head2 basename

  method basename : string ($path : string);

=head2 dirname

  method dirname : string ($path : string);

=head1 Well Known Child Classes

=over 2

=item L<File::Basename::Instance::Win32|SPVM::File::Basename::Instance::Win32>

=back

=head1 Copyright & License

Copyright 2023-2023 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

