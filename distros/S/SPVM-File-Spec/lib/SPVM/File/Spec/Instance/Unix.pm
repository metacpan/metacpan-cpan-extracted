package SPVM::File::Spec::Instance::Unix;



1;

=head1 Name

SPVM::File::Spec::Instance::Unix - Implementation of File::Spec::Instance for Linux/Unix/Mac

=head1 Description

The File::Spec::Instance::Unix class of L<SPVM> is an implementation of L<File::Spec::Instance|SPVM::File::Spec::Instance> for Linux/Unix/Mac.

=head1 Usage

  use File::Spec::Instance::Unix;

  my $spec = File::Spec::Instance::Unix->new;
  my $file = $spec->catfile(["foo", "bar"], "a.txt"]);

=head1 Inheritance

=over 2

=item * L<File::Spec::Instance|SPVM::File::Spec::Instance>

=back

=head1 Class Methods

  static method new : File::Spec::Instance::Unix ();

=head1 Instance Methods

=head2 devnull

  method devnull : string ();

=head2 rootdir

  method rootdir : string ();

=head2 curdir

  method curdir : string ();

=head2 updir

  method updir : string ();

=head2 canonpath

  method canonpath : string ($path : string);

=head2 catdir

  method catdir : string ($dir_parts : string[]);

=head2 catfile

  method catfile : string ($dir_parts : string[], $file_base_name : string);

=head2 no_upwards

  method no_upwards : string[] ($dir_parts : string[]);

=head2 file_name_is_absolute

  method file_name_is_absolute : int ($path : string);

=head2 file_name_is_root

  method file_name_is_root : int ($path : string);

=head2 join

  method join : string ($dir_parts : string[], $file_base_name : string);

=head2 catpath

  method catpath : string ($volume : string, $directory : string, $file : string);

=head2 splitpath

  method splitpath : string[] ($path : string, $no_file = 0 : int);

=head2 rel2abs

  method rel2abs : string ($path : string, $base = undef : string);

=head2 splitdir

  method splitdir : string[] ($path : string);

=head2 abs2rel

  method abs2rel : string ($path : string, $base = undef : string);

=head2 path

  method path : string[] ();

=head2 tmpdir

  method tmpdir : string ();

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

