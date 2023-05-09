package SPVM::File::Basename::Instance::Win32;



1;

=head1 Name

SPVM::File::Basename::Instance::Win32 - Windows Implementation of File::Basename::Instance

=head1 Description

The File::Basename::Instance::Win32 class of L<SPVM> is the Windows implementation of L<File::Basename::Instance|SPVM::File::Basename::Instance>.

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

Copyright (c) 2023 Yuki Kimoto

MIT License

