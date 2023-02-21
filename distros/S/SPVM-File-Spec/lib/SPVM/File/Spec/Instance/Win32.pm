package SPVM::File::Spec::Instance::Win32;



1;

=head1 Name

SPVM::File::Spec::Instance::Win32 - An implementation class of File::Spec::Instance for Windows.

=head1 Description

C<SPVM::File::Spec::Instance::Win32> is the L<SPVM>'s C<File::Spec::Instance::Win32> class.

An implementation class of the L<File::Spec::Instance|SPVM::SPVM::File::Spec::Instance> for Windows.

=head1 Usage

  my $spec = File::Spec::Instance::Win32->new;
  my $file = $spec->catfile(["foo", "bar"], "a.txt"]);

=head1 Inheritance

=over 2

=item * L<File::Spec::Instance::Unix|SPVM::File::Spec::Instance::Unix>

=back

=head1 Class Methods

=head2 new

  static method new : File::Spec::Instance::Win32 ();

=head1 Instance Methods

=head2 devnull

  method devnull : string ();

=head2 rootdir

  method rootdir : string ();

=head2 tmpdir

  method tmpdir : string ();

=head2 file_name_is_absolute

  method file_name_is_absolute : int ($path : string);

=head2 path

  method path : string[] ();

=head2 splitpath

  method splitpath : string[] ($path : string, $nofile = 0 : int);

=head2 splitdir

  method splitdir : string[] ($path : string);

=head2 canonpath

  method canonpath : string ($path : string);

=head2 catdir

  method catdir : string ($dir_parts : string[]);

=head2 catfile

  method catfile : string ($dir_parts : string[], $file_base_name : string);

=head2 rel2abs

  method rel2abs : string ($path : string, $base = undef : string);

=head2 catpath

  method catpath : string ($volume : string, $directory : string, $file : string);

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright 2022-2022 Yuki Kimoto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

