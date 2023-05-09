package SPVM::File::Basename::Instance::Unix;



1;

=head1 Name

SPVM::File::Basename::Instance::Unix - Unix/Linux/Mac Implementation of File::Basename::Instance

=head1 Description

The File::Basename::Instance::Unix class of L<SPVM> is the Unix/Linux/Mac implementation of L<File::Basename::Instance|SPVM::File::Basename::Instance>.

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

Copyright (c) 2023 Yuki Kimoto

MIT License

