package SPVM::File::Basename::Instance::Win32;



1;

=head1 Name

SPVM::File::Basename::Instance::Win32 - File::Basename::Instance Implementation for Windows.

=head1 Description

C<SPVM::File::Basename::Instance::Win32> is the C<File::Basename::Instance::Win32> class in L<SPVM> language.

This class is a child class of the L<File::Basename::Instance|SPVM::File::Basename::Instance> class for Windows.

=head1 Usage

  use File::Basename::Instance::Win32;
  
  my $fb = File::Basename::Instance::Win32->new;

=head1 Inheritance

=over 2

=item * L<File::Basename::Instance::Unix|SPVM::File::Basename::Instance::Unix>

=back

=head1 Class Methods

=head2 new

  static method new : File::Basename::Instance::Win32 ();

=head1 Instance Methods

=head2 fileparse

  method fileparse : string[] ($path : string);

=head1 Copyright & License

Copyright 2023-2023 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
