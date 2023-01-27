package SPVM::File::Basename::Unix;



1;

=head1 Name

SPVM::File::Basename::Unix - File::Basename Implementation for Linux, UNIX, and Mac.

=head1 Description

C<SPVM::File::Basename::Unix> is the C<File::Basename::Unix> class in L<SPVM> language.

This class is a child class of the L<File::Basename|SPVM::File::Basename> class for Linux, UNIX, and Mac.

=head1 Usage

  use File::Basename::Unix;

  my $fb = File::Basename::Unix->new;

=head1 Inheritance

=over 2

=item * L<File::Basename|SPVM::File::Basename>

=back

=head1 Class Methods

=head2 new

  static method new : File::Basename::Unix ();

=head1 Instance Methods

=head2 fileparse

  method fileparse : string[] ($path : string);

=head2 basename

  method basename : string ($path : string);

=head2 dirname

  method dirname : string ($path : string);

=head1 Well Known Child Classes

=over 2

=item L<File::Basename::Win32|SPVM::File::Basename::Win32>

=back

=head1 Copyright & License

Copyright 2023-2023 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

