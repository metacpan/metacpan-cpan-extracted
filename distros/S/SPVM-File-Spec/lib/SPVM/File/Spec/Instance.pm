package SPVM::File::Spec::Instance;

1;

=head1 Name

SPVM::File::Spec::Instance - Portably Perform Operations on File Names

=head1 Description

C<SPVM::File::Spec::Instance> is the L<SPVM>'s C<File::Spec::Instance> class.

This module is designed to support operations commonly performed on file specifications

=head1 Usage

  use File::Spec::Instance;

  my $spec = File::Spec::Instance->new;
  my $file = $spec->catfile(["foo", "bar"], "a.txt"]);

=head1 Interfaces

=over 2

=item * L<File::Spec::Instance::Interface|SPVM::File::Spec::Instance::Interface>

=back

=head1 Class Methods

  static method new : File::Spec::Instance ();

=head1 Instance Methods

=head2 has_interfaces

  method has_interfaces : int ();

=head2 canonpath

  method canonpath : string ($path : string);

=head2 catdir

  method catdir : string ($directories : string[]);

=head2 catfile

  method catfile : string ($directories : string[], $filename : string);

=head2 curdir

  method curdir : string ();

=head2 devnull

  method devnull : string ();

=head2 rootdir

  method rootdir : string ();

=head2 tmpdir

  method tmpdir : string ();

=head2 updir

  method updir : string ();

=head2 no_upwards

  method no_upwards : string[] ($directories : string[]);

=head2 file_name_is_absolute

  method file_name_is_absolute : int ($path : string);

=head2 path

  method path : string[] ();

=head2 join

  method join : string ($directories : string[], $filename : string);

=head2 splitpath

  method splitpath : string[] ($path : string, $no_file = 0 : int);

=head2 splitdir

  method splitdir : string[] ($path : string);

=head2 catpath

  method catpath : string ($volume : string, $directory : string, $file : string);

=head2 abs2rel

  method abs2rel : string ($path : string, $base = undef : string);

=head2 rel2abs

  method rel2abs : string ($path : string, $base = undef : string);

=head1 Well Known Child Classes

=over 2

=item * L<File::Spec::Instance::Unix|SPVM::File::Spec::Instance::Unix>

=item * L<File::Spec::Instance::Win32|SPVM::File::Spec::Instance::Win32>

=back

=head1 Repository

L<SPVM::File::Spec::Instance - Github|https://github.com/yuki-kimoto/SPVM-File-Spec>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

