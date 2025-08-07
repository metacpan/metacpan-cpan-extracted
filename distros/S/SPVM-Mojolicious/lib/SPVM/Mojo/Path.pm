package SPVM::Mojo::Path;



1;

=encoding utf8

=head1 Name

SPVM::Mojo::Path - Path

=head1 Description

Mojo::Path class in L<SPVM> is a container for paths used by L<Mojo::URL|SPVM::Mojo::URL>, based on L<RFC 3986|https://tools.ietf.org/html/rfc3986>.

=head1 Usage

  use Mojo::Path;
  
  # Parse
  my $path = Mojo::Path->new("/foo%2Fbar%3B/baz.html");
  my $parts_list = $path->parts_list;
  say $parts_list->get(0);
  
  # Build
  my $path = Mojo::Path->new("/i/♥");
  my $parts_list = $path->parts_list;
  $parts_list->push("mojolicious");
  say $path->to_string;

=head1 Fields

=head2 parts

C<has parts : virtual rw string[]>

The path parts.

This is a virtual field. The value is got from and stored to L</"parts_list">.

=head2 parts_list

C<has parts_list : rw L<StringList|SPVM::StringList>;>

The path parts. Note that this method will normalize the path and that C<%2F> will be treated as C</> for security
reasons.

Examples:

  # Part with slash
  $path->parts_list->push("foo/bar");

=head2 leading_slash

C<has leading_slash : rw byte;>

Path has a leading slash. Note that this method will normalize the path and that C<%2F> will be treated as C</> for
security reasons.

Examples:

  # "/foo/bar"
  Mojo::Path->new("foo/bar")->set_leading_slash(1);

  # "foo/bar"
  Mojo::Path->new("/foo/bar")->set_leading_slash(0);

=head2 trailing_slash

C<has trailing_slash : rw byte;>

Path has a trailing slash. Note that this method will normalize the path and that C<%2F> will be treated as C</> for
security reasons.

Examples:

  # "/foo/bar/"
  Mojo::Path->new("/foo/bar")->set_trailing_slash(1);

  # "/foo/bar"
  Mojo::Path->new("/foo/bar/")->set_trailing_slash(0);

=head1 Class Methods

=head2 new

C<static method new : Mojo::Path ($path_string : string = undef);>

Construct a new L<Mojo::Path|SPVM::Mojo::Path> object and L</"parse"> path if necessary.

Examples:

  my $path = Mojo::Path->new;
  my $path = Mojo::Path->new("/foo%2Fbar%3B/baz.html");

=head1 Instance Methods

=head2 canonicalize

C<method canonicalize : void ();>

Canonicalize path by resolving C<.> and C<..>, in addition C<...> will be treated as C<.> to protect from path
traversal attacks.

Examples:

  # "/foo/baz"
  Mojo::Path->new("/foo/./bar/../baz")->canonicalize;

  # "/../baz"
  Mojo::Path->new("/foo/../bar/../../baz")->canonicalize;

  # "/foo/bar"
  Mojo::Path->new("/foo/.../bar")->canonicalize;

=head2 clone

C<method clone : L<Mojo::Path|SPVM::Mojo::Path> ();>

Return a new L<Mojo::Path|SPVM::Mojo::Path> object cloned from this path.

=head2 contains

C<method contains : int ($string : string);>

Check if path contains given prefix.

Examples:

  # True
  Mojo::Path->new("/foo/bar")->contains("/");
  Mojo::Path->new("/foo/bar")->contains("/foo");
  Mojo::Path->new("/foo/bar")->contains("/foo/bar");
  
  # False
  Mojo::Path->new("/foo/bar")->contains("/f");
  Mojo::Path->new("/foo/bar")->contains("/bar");
  Mojo::Path->new("/foo/bar")->contains("/whatever");

=head2 merge

C<method merge : void ($path : object of string|L<Mojo::Path|SPVM::Mojo::Path>);>

Merge paths. Note that this method will normalize both paths if necessary and that C<%2F> will be treated as C</> for
security reasons.

  # "/baz/yada"
  Mojo::Path->new("/foo/bar")->merge("/baz/yada");

  # "/foo/baz/yada"
  Mojo::Path->new("/foo/bar")->merge("baz/yada");

  # "/foo/bar/baz/yada"
  Mojo::Path->new("/foo/bar/")->merge("baz/yada");

=head2 parse

C<method parse : void ($path : string);>

Parse path.

=head2 to_abs_string

C<method to_abs_string : string ();>

Turn path into an absolute string.

  # "/i/%E2%99%A5/mojolicious"
  Mojo::Path->new("/i/%E2%99%A5/mojolicious")->to_abs_string;
  Mojo::Path->new("i/%E2%99%A5/mojolicious")->to_abs_string;

=head2 to_dir

C<method to_dir : L<Mojo::Path|SPVM::Mojo::Path> ();>

Clone path and remove everything after the right-most slash.

  # "/i/%E2%99%A5/"
  Mojo::Path->new("/i/%E2%99%A5/mojolicious")->to_dir->to_abs_string;
  
  # "i/%E2%99%A5/"
  Mojo::Path->new("i/%E2%99%A5/mojolicious")->to_dir->to_abs_string;

=head2 to_route

C<method to_route : string ();>

Turn path into a route.

  # "/i/♥/mojolicious"
  Mojo::Path->new("/i/%E2%99%A5/mojolicious")->to_route;
  Mojo::Path->new("i/%E2%99%A5/mojolicious")->to_route;

=head2 to_string

C<method to_string : string ();>

Turn path into a string.

  # "/i/%E2%99%A5/mojolicious"
  Mojo::Path->new("/i/%E2%99%A5/mojolicious")->to_string;

  # "i/%E2%99%A5/mojolicious"
  Mojo::Path->new("i/%E2%99%A5/mojolicious")->to_string;

=head1 See Also

=over 2

=item * L<SPVM::Mojolicious>

=back

=head1 Copyright & License

Copyright (c) 2025 Yuki Kimoto

MIT License

