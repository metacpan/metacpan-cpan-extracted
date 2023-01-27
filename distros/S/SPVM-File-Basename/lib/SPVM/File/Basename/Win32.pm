package SPVM::File::Basename::Win32;



1;

=head1 Name

SPVM::File::Basename::Win32 - File::Basename Implementation for Windows.

=head1 Description

C<SPVM::File::Basename::Win32> is the C<File::Basename::Win32> class in L<SPVM> language.

This class is a child class of the L<File::Basename|SPVM::File::Basename> class for Windows.

=head1 Usage

  use File::Basename::Win32;
  
  my $fb = File::Basename::Win32->new;

=head1 Inheritance

=over 2

=item * L<File::Basename::Unix|SPVM::File::Basename::Unix>

=back

=head1 Class Methods

=head2 new

  static method new : File::Basename::Win32 ();

=head1 Instance Methods

=head2 fileparse

  method fileparse : string[] ($path : string);

=head1 Copyright & License

Copyright 2023-2023 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
