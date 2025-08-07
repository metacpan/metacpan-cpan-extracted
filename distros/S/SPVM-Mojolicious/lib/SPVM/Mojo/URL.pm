package SPVM::Mojo::URL;



1;

=encoding utf8

=head1 Name

SPVM::Mojo::URL - Uniform Resource Locator

=head1 Description

Mojo::URL class in L<SPVM> implements a subset of L<RFC 3986|https://tools.ietf.org/html/rfc3986>, L<RFC
3987|https://tools.ietf.org/html/rfc3987> and the L<URL Living Standard|https://url.spec.whatwg.org> for Uniform
Resource Locators with support for IDNA and IRIs.

=head1 Usage

  use Mojo::URL;

  # Parse
  my $url = Mojo::URL->new("http://sri:foo@example.com:3000/foo?foo=bar#23");
  say $url->scheme;
  say $url->userinfo;
  say $url->host;
  say $url->port;
  say $url->path;
  say $url->query;
  say $url->fragment;
  
  # Build
  my $url = Mojo::URL->new;
  $url->set_scheme("http");
  $url->set_host("example.com");
  $url->set_port(3000);
  $url->set_path("/foo/bar");
  $url->set_query(Mojo::Parameters->new({foo => "bar"}));
  $url->set_fragment(23);
  say $url->to_string;

=head1 Fields

=head2 base

C<has base : rw L<Mojo::URL|SPVM::Mojo::URL>;>

Base of this URL, defaults to a L<Mojo::URL|SPVM::Mojo::URL> object.

  # "http://example.com/a/b?c"
  my $url = Mojo::URL->new("/a/b?c");
  $url->set_base(Mojo::URL->new("http://example.com"))
  $url->to_abs;

=head2 fragment

C<has fragment : rw string;>

Fragment part of this URL.

Examples:

  # "yada"
  Mojo::URL->new("http://example.com/foo?bar=baz#yada")->fragment;

=head2 host

C<has host : rw string;>

Host part of this URL.

  # "example.com"
  Mojo::URL->new("http://sri:t3st@example.com:8080/foo")->host;

=head2 port

C<has port : rw int;>

Port part of this URL.

  # "8080"
  Mojo::URL->new("http://sri:t3st@example.com:8080/foo")->port;

=head2 scheme

C<has scheme : rw string;>

Scheme part of this URL.

  # "http"
  Mojo::URL->new("http://example.com/foo")->scheme;

=head2 userinfo

C<has userinfo : rw string;>

Userinfo part of this URL.

  # "sri:t3st"
  Mojo::URL->new("https://sri:t3st@example.com/foo")->userinfo;

=head2 path

C<has path : rw L<Mojo::Path|SPVM::Mojo::Path>;>

Path part of this URL, relative paths will be merged with L<Mojo::Path#merge|SPVM::Mojo::Path/"merge"> method, defaults to a L<Mojo::Path|SPVM::Mojo::Path> object.

The setter also receives a string.

Examples:

  # "test"
  Mojo::URL->new("http://example.com/test/Mojo")->path->parts_list->get(0);

  # "/test/DOM/HTML"
  Mojo::URL->new("http://example.com/test/Mojo")->path->merge("DOM/HTML");

  # "http://example.com/DOM/HTML"
  Mojo::URL->new("http://example.com/test/Mojo")->set_path("/DOM/HTML");

  # "http://example.com/test/DOM/HTML"
  Mojo::URL->new("http://example.com/test/Mojo")->set_path("DOM/HTML");

  # "http://example.com/test/Mojo/DOM/HTML"
  Mojo::URL->new("http://example.com/test/Mojo/")->set_path("DOM/HTML");

=head2 query

C<has query : rw L<Mojo::Parameters|SPVM::Mojo::Parameters>;>

Query part of this URL, key/value pairs in an array reference will be appended with L<Mojo::Parameters#append|SPVM::Mojo::Parameters/"append"> method, and
key/value pairs in a hash reference merged with L<Mojo::Parameters#merge|SPVM::Mojo::Parameters/"merge"> method, defaults to a L<Mojo::Parameters|SPVM::Mojo::Parameters> object.

The setter also receives an object of object[] type. If the object is options, the merge operation is performed. Otherwise the append operation is performed.

Examples:

  # "2"
  Mojo::URL->new("http://example.com?a=1&b=2")->query->param("b");

  # "a=2&b=2&c=3"
  Mojo::URL->new("http://example.com?a=1&b=2")->query->merge({a => 2, c => 3});

  # "http://example.com?a=2&c=3"
  Mojo::URL->new("http://example.com?a=1&b=2")->set_query(Mojo::Parameters->new({a => 2, c => 3}));

  # "http://example.com?a=2&a=3"
  Mojo::URL->new("http://example.com?a=1&b=2")->set_query(Mojo::Parameters->new({a => [2, 3]});

  # "http://example.com?a=2&b=2&c=3"
  Mojo::URL->new("http://example.com?a=1&b=2")->set_query({a => 2, c => 3});

  # "http://example.com?b=2"
  Mojo::URL->new("http://example.com?a=1&b=2")->set_query({a => undef});

  # "http://example.com?a=1&b=2&a=2&c=3"
  Mojo::URL->new("http://example.com?a=1&b=2")->set_query([(object)a => 2, c => 3]);

=head1 Class Methods

=head2 new

C<static method new : L<Mojo::URL|SPVM::Mojo::URL> ($url : string = undef);>

Construct a new L<Mojo::URL|SPVM::Mojo::URL> object and L</"parse"> URL if necessary.

Examples:

  my $url = Mojo::URL->new;
  my $url = Mojo::URL->new("http://127.0.0.1:3000/foo?f=b&baz=2#foo");

=head1 Instance Methods

=head2 clone

C<method clone : L<Mojo::URL|SPVM::Mojo::URL> ();>

Return a new L<Mojo::URL|SPVM::Mojo::URL> object cloned from this URL.

=head2 host_port

C<method host_port : string ();>

Normalized version of L</"host"> and L</"port">.

Examples:

  # "xn--n3h.net:8080"
  Mojo::URL->new("http://☃.net:8080/test")->host_port;

  # "example.com"
  Mojo::URL->new("http://example.com/test")->host_port;

=head2 set_host_port

C<method set_host_port : void ($host_port : string);>

Set L</"host_port">.

=head2 ihost

C<method ihost : string ();>

Host part of this URL in punycode format.

  # "xn--n3h.net"
  Mojo::URL->new("http://☃.net")->ihost;

  # "example.com"
  Mojo::URL->new("http://example.com")->ihost;

=head2 set_ihost

C<method set_ihost : void ($ihost : string);>

Set L</"ihost">.

=head2 is_abs

C<method is_abs : int ();>

Check if URL is absolute.

  # True
  Mojo::URL->new("http://example.com")->is_abs;
  Mojo::URL->new("http://example.com/test/index.html")->is_abs;

  # False
  Mojo::URL->new("test/index.html")->is_abs;
  Mojo::URL->new("/test/index.html")->is_abs;
  Mojo::URL->new("//example.com/test/index.html")->is_abs;

=head2 parse

C<method parse : void ($url : string);>

Parse relative or absolute URL.

  # "/test/123"
  $url->parse("/test/123?foo=bar")->path;

  # "example.com"
  $url->parse("http://example.com/test/123?foo=bar")->host;

  # "sri@example.com"
  $url->parse("mailto:sri@example.com")->path;

=head2 password

C<method password : string ();>

Password part of L</"userinfo">.

  # "s3cret"
  Mojo::URL->new("http://isabel:s3cret@mojolicious.org")->password;

  # "s:3:c:r:e:t"
  Mojo::URL->new("http://isabel:s:3:c:r:e:t@mojolicious.org")->password;

=head2 path_query

C<method path_query : string ();>

Normalized version of L</"path"> and L</"query">.

  # "/test?a=1&b=2"
  Mojo::URL->new("http://example.com/test?a=1&b=2")->path_query;

  # "/"
  Mojo::URL->new("http://example.com/")->path_query;

=head2 set_path_query

C<method set_path_query : void ($pass_query : string);>

Set L</"path_query">

=head2 protocol

C<method protocol : string ();>

Normalized version of L</"scheme">.

  # "http"
  Mojo::URL->new("HtTp://example.com")->protocol;

=head2 to_abs

C<method to_abs : L<Mojo::URL|SPVM::Mojo::URL> ($base : L<Mojo::URL|SPVM::Mojo::URL> = undef);>

Return a new L<Mojo::URL|SPVM::Mojo::URL> object cloned from this relative URL and turn it into an absolute one using L</"base"> or
provided base URL.

  # "http://example.com/foo/baz.xml?test=123"
  Mojo::URL->new("baz.xml?test=123")
    ->to_abs(Mojo::URL->new("http://example.com/foo/bar.html"));

  # "http://example.com/baz.xml?test=123"
  Mojo::URL->new("/baz.xml?test=123")
    ->to_abs(Mojo::URL->new("http://example.com/foo/bar.html"));

  # "http://example.com/foo/baz.xml?test=123"
  Mojo::URL->new("//example.com/foo/baz.xml?test=123")
    ->to_abs(Mojo::URL->new("http://example.com/foo/bar.html"));

=head2 to_string

C<method to_string : string ();>

Turn URL into a string. Note that L</"userinfo"> will not be included for security reasons.

  # "http://mojolicious.org"
  Mojo::URL->new->scheme("http")->host("mojolicious.org")->to_string;

  # "http://mojolicious.org"
  Mojo::URL->new("http://daniel:s3cret@mojolicious.org")->to_string;

=head2 to_unsafe_string

C<method to_unsafe_string : string ();>

Same as L</"to_string">, but includes L</"userinfo">.

  # "http://daniel:s3cret@mojolicious.org"
  Mojo::URL->new("http://daniel:s3cret@mojolicious.org")->to_unsafe_string;

=head2 username

C<method username : string ();>

Username part of L</"userinfo">.

  # "isabel"
  Mojo::URL->new("http://isabel:s3cret@mojolicious.org")->username;

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

