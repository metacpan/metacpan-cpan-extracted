package SPVM::File::Spec;

our $VERSION = "0.081002";

1;

=head1 Name

SPVM::File::Spec - Performing Operations on File Names Portably

=head1 Description

The File::Spec class of L<SPVM> has methods to perform operations on file names portably.

=head1 Usage

  use File::Spec;
  
  my $file = File::Spec->catfile(["foo", "bar"], "a.txt"]);

=head1 Class Methods

=head2 canonpath

  static method canonpath : string ($path : string);

=head2 catdir

  static method catdir : string ($directories : string[]);

=head2 catfile

  static method catfile : string ($directories : string[], $filename : string);

=head2 curdir

  static method curdir : string ();

=head2 devnull

  static method devnull : string ();

=head2 rootdir

  static method rootdir : string ();

=head2 tmpdir

  static method tmpdir : string ();

=head2 updir

  static method updir : string ();

=head2 no_upwards

  static method no_upwards : string[] ($directories : string[]);

=head2 file_name_is_absolute

  static method file_name_is_absolute : int ($path : string);

=head2 file_name_is_root

  static method file_name_is_root : int ($path : string);

=head2 path

  static method path : string[] ();

=head2 join

  static method join : string ($directories : string[], $filename : string);

=head2 splitpath

  static method splitpath : string[] ($path : string, $no_file : int = 0);

=head2 splitdir

  static method splitdir : string[] ($path : string);

=head2 catpath

  static method catpath : string ($volume : string, $directory : string, $file : string);

=head2 abs2rel

  static method abs2rel : string ($path : string, $base : string = undef);

=head2 rel2abs

  static method rel2abs : string ($path : string, $base : string = undef);

=head1 Object Oriented Classes

The following classes are used to implement C<SPVM::File::Spec>.

=over 2

=item * L<File::Spec::Instance|SPVM::File::Spec::Instance>

=item * L<File::Spec::Instance::Unix|SPVM::File::Spec::Instance::Unix>

=item * L<File::Spec::Instance::Win32|SPVM::File::Spec::Instance::Win32>

=back

=head1 SPVM::Cwd

L<SPVM::Cwd> is included in this distribution.

=over 2

=item * L<SPVM::Cwd>

=back

=head1 See Also

=head2 File::Spec

C<SPVM::File::Spec> is Perl's L<File::Spec> porting to L<SPVM>.

=head1 Repository

L<SPVM::File::Spec - Github|https://github.com/yuki-kimoto/SPVM-File-Spec>

=head1 Author

Yuki Kimoto C<kimoto.yuki@gmail.com>

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

