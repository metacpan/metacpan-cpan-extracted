#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );

BEGIN {
    use_ok( 'Pod::LOL' ) || print "Bail out!\n";
}

diag( "Testing Pod::LOL $Pod::LOL::VERSION, Perl $], $^X" );

my @cases = (
    {
        name          => "Module - Mojo::UserAgent",
        expected_root => [
            [ "head1", "NAME" ],
            [ "Para",  "ojo - Fun one-liners with Mojo" ],
            [ "head1", "SYNOPSIS" ],
            [
                "Verbatim",
"  \$ perl -Mojo -E 'say g(\"mojolicious.org\")->dom->at(\"title\")->text'"
            ],
            [ "head1", "DESCRIPTION" ],
            [
                "Para",
"A collection of automatically exported functions for fun Perl one-liners. Ten redirects will be followed by default, you can change this behavior with the MOJO_MAX_REDIRECTS environment variable."
            ],
            [
                "Verbatim",
"  \$ MOJO_MAX_REDIRECTS=0 perl -Mojo -E 'say g(\"example.com\")->code'"
            ],
            [
                "Para",
"Proxy detection is enabled by default, but you can disable it with the MOJO_PROXY environment variable."
            ],
            [
                "Verbatim",
                "  \$ MOJO_PROXY=0 perl -Mojo -E 'say g(\"example.com\")->body'"
            ],
            [
                "Para",
"TLS certificate verification can be disabled with the MOJO_INSECURE environment variable."
            ],
            [
                "Verbatim",
"  \$ MOJO_INSECURE=1 perl -Mojo -E 'say g(\"https://127.0.0.1:3000\")->body'"
            ],
            [
                "Para",
                "Every ojo one-liner is also a Mojolicious::Lite application."
            ],
            [
                "Verbatim",
"  \$ perl -Mojo -E 'get \"/\" => {inline => \"%= time\"}; app->start' get /"
            ],
            [
                "Para",
"On Perl 5.20+ subroutine signatures will be enabled automatically."
            ],
            [
                "Verbatim",
"  \$ perl -Mojo -E 'a(sub (\$c) { \$c->render(text => \"Hello!\") })->start' get /"
            ],
            [
                "Para",
"If it is not already defined, the MOJO_LOG_LEVEL environment variable will be set to fatal."
            ],
            [ "head1", "FUNCTIONS" ],
            [
                "Para",
"ojo implements the following functions, which are automatically exported."
            ],
            [ "head2", "a" ],
            [
                "Verbatim",
"  my \$app = a('/hello' => sub { \$_->render(json => {hello => 'world'}) });"
            ],
            [
                "Para",
"Create a route with \"any\" in Mojolicious::Lite and return the current Mojolicious::Lite object. The current controller object is also available to actions as \$_. See also Mojolicious::Guides::Tutorial for more argument variations."
            ],
            [
                "Verbatim",
"  \$ perl -Mojo -E 'a(\"/hello\" => {text => \"Hello Mojo!\"})->start' daemon"
            ],
            [ "head2",    "b" ],
            [ "Verbatim", "  my \$stream = b('lalala');" ],
            [ "Para",     "Turn string into a Mojo::ByteStream object." ],
            [
                "Verbatim",
"  \$ perl -Mojo -E 'b(g(\"mojolicious.org\")->body)->html_unescape->say'"
            ],
            [ "head2",    "c" ],
            [ "Verbatim", "  my \$collection = c(1, 2, 3);" ],
            [ "Para",     "Turn list into a Mojo::Collection object." ],
            [ "head2",    "d" ],
            [
                "Verbatim",
"  my \$res = d('example.com');\n  my \$res = d('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = d('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = d('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
            ],
            [
                "Para",
"Perform DELETE request with \"delete\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
            ],
            [ "head2",    "f" ],
            [ "Verbatim", "  my \$path = f('/home/sri/foo.txt');" ],
            [ "Para",     "Turn string into a Mojo::File object." ],
            [
                "Verbatim",
                "  \$ perl -Mojo -E 'say r j f(\"hello.json\")->slurp'"
            ],
            [ "head2", "g" ],
            [
                "Verbatim",
"  my \$res = g('example.com');\n  my \$res = g('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = g('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = g('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
            ],
            [
                "Para",
"Perform GET request with \"get\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
            ],
            [
                "Verbatim",
"  \$ perl -Mojo -E 'say g(\"mojolicious.org\")->dom(\"h1\")->map(\"text\")->join(\"\\n\")'"
            ],
            [ "head2", "h" ],
            [
                "Verbatim",
"  my \$res = h('example.com');\n  my \$res = h('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = h('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = h('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
            ],
            [
                "Para",
"Perform HEAD request with \"head\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
            ],
            [ "head2", "j" ],
            [
                "Verbatim",
"  my \$bytes = j([1, 2, 3]);\n  my \$bytes = j({foo => 'bar'});\n  my \$value = j(\$bytes);"
            ],
            [
                "Para",
"Encode Perl data structure or decode JSON with \"j\" in Mojo::JSON."
            ],
            [
                "Verbatim",
"  \$ perl -Mojo -E 'f(\"hello.json\")->spurt(j {hello => \"world!\"})'"
            ],
            [ "head2",    "l" ],
            [ "Verbatim", "  my \$url = l('https://mojolicious.org');" ],
            [ "Para",     "Turn a string into a Mojo::URL object." ],
            [
                "Verbatim",
"  \$ perl -Mojo -E 'say l(\"/perldoc\")->to_abs(l(\"https://mojolicious.org\"))'"
            ],
            [ "head2",    "n" ],
            [ "Verbatim", "  n {...};\n  n {...} 100;" ],
            [
                "Para",
"Benchmark block and print the results to STDERR, with an optional number of iterations, which defaults to 1."
            ],
            [
                "Verbatim",
                "  \$ perl -Mojo -E 'n { say g(\"mojolicious.org\")->code }'"
            ],
            [ "head2", "o" ],
            [
                "Verbatim",
"  my \$res = o('example.com');\n  my \$res = o('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = o('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = o('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
            ],
            [
                "Para",
"Perform OPTIONS request with \"options\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
            ],
            [ "head2", "p" ],
            [
                "Verbatim",
"  my \$res = p('example.com');\n  my \$res = p('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = p('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = p('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
            ],
            [
                "Para",
"Perform POST request with \"post\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
            ],
            [ "head2",    "r" ],
            [ "Verbatim", "  my \$perl = r({data => 'structure'});" ],
            [
                "Para",
                "Dump a Perl data structure with \"dumper\" in Mojo::Util."
            ],
            [
                "Verbatim",
                "  perl -Mojo -E 'say r g(\"example.com\")->headers->to_hash'"
            ],
            [ "head2", "t" ],
            [
                "Verbatim",
"  my \$res = t('example.com');\n  my \$res = t('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = t('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = t('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
            ],
            [
                "Para",
"Perform PATCH request with \"patch\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
            ],
            [ "head2", "u" ],
            [
                "Verbatim",
"  my \$res = u('example.com');\n  my \$res = u('http://example.com' => {Accept => '*/*'} => 'Hi!');\n  my \$res = u('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});\n  my \$res = u('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});"
            ],
            [
                "Para",
"Perform PUT request with \"put\" in Mojo::UserAgent and return resulting Mojo::Message::Response object."
            ],
            [ "head2",    "x" ],
            [ "Verbatim", "  my \$dom = x('<div>Hello!</div>');" ],
            [ "Para",     "Turn HTML/XML input into Mojo::DOM object." ],
            [
                "Verbatim",
"  \$ perl -Mojo -E 'say x(f(\"test.html\")->slurp)->at(\"title\")->text'"
            ],
            [ "head1", "SEE ALSO" ],
            [
                "Para",
                "Mojolicious, Mojolicious::Guides, https://mojolicious.org."
            ]
        ],
        pod => <<'POD',
=encoding utf8

=head1 NAME

ojo - Fun one-liners with Mojo

=head1 SYNOPSIS

  $ perl -Mojo -E 'say g("mojolicious.org")->dom->at("title")->text'

=head1 DESCRIPTION

A collection of automatically exported functions for fun Perl one-liners. Ten redirects will be followed by default,
you can change this behavior with the C<MOJO_MAX_REDIRECTS> environment variable.

  $ MOJO_MAX_REDIRECTS=0 perl -Mojo -E 'say g("example.com")->code'

Proxy detection is enabled by default, but you can disable it with the C<MOJO_PROXY> environment variable.

  $ MOJO_PROXY=0 perl -Mojo -E 'say g("example.com")->body'

TLS certificate verification can be disabled with the C<MOJO_INSECURE> environment variable.

  $ MOJO_INSECURE=1 perl -Mojo -E 'say g("https://127.0.0.1:3000")->body'

Every L<ojo> one-liner is also a L<Mojolicious::Lite> application.

  $ perl -Mojo -E 'get "/" => {inline => "%= time"}; app->start' get /

On Perl 5.20+ L<subroutine signatures|perlsub/"Signatures"> will be enabled automatically.

  $ perl -Mojo -E 'a(sub ($c) { $c->render(text => "Hello!") })->start' get /

If it is not already defined, the C<MOJO_LOG_LEVEL> environment variable will be set to C<fatal>.

=head1 FUNCTIONS

L<ojo> implements the following functions, which are automatically exported.

=head2 a

  my $app = a('/hello' => sub { $_->render(json => {hello => 'world'}) });

Create a route with L<Mojolicious::Lite/"any"> and return the current L<Mojolicious::Lite> object. The current
controller object is also available to actions as C<$_>. See also L<Mojolicious::Guides::Tutorial> for more argument
variations.

  $ perl -Mojo -E 'a("/hello" => {text => "Hello Mojo!"})->start' daemon

=head2 b

  my $stream = b('lalala');

Turn string into a L<Mojo::ByteStream> object.

  $ perl -Mojo -E 'b(g("mojolicious.org")->body)->html_unescape->say'

=head2 c

  my $collection = c(1, 2, 3);

Turn list into a L<Mojo::Collection> object.

=head2 d

  my $res = d('example.com');
  my $res = d('http://example.com' => {Accept => '*/*'} => 'Hi!');
  my $res = d('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
  my $res = d('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});

Perform C<DELETE> request with L<Mojo::UserAgent/"delete"> and return resulting L<Mojo::Message::Response> object.

=head2 f

  my $path = f('/home/sri/foo.txt');

Turn string into a L<Mojo::File> object.

  $ perl -Mojo -E 'say r j f("hello.json")->slurp'

=head2 g

  my $res = g('example.com');
  my $res = g('http://example.com' => {Accept => '*/*'} => 'Hi!');
  my $res = g('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
  my $res = g('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});

Perform C<GET> request with L<Mojo::UserAgent/"get"> and return resulting L<Mojo::Message::Response> object.

  $ perl -Mojo -E 'say g("mojolicious.org")->dom("h1")->map("text")->join("\n")'

=head2 h

  my $res = h('example.com');
  my $res = h('http://example.com' => {Accept => '*/*'} => 'Hi!');
  my $res = h('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
  my $res = h('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});

Perform C<HEAD> request with L<Mojo::UserAgent/"head"> and return resulting L<Mojo::Message::Response> object.

=head2 j

  my $bytes = j([1, 2, 3]);
  my $bytes = j({foo => 'bar'});
  my $value = j($bytes);

Encode Perl data structure or decode JSON with L<Mojo::JSON/"j">.

  $ perl -Mojo -E 'f("hello.json")->spurt(j {hello => "world!"})'

=head2 l

  my $url = l('https://mojolicious.org');

Turn a string into a L<Mojo::URL> object.

  $ perl -Mojo -E 'say l("/perldoc")->to_abs(l("https://mojolicious.org"))'

=head2 n

  n {...};
  n {...} 100;

Benchmark block and print the results to C<STDERR>, with an optional number of iterations, which defaults to C<1>.

  $ perl -Mojo -E 'n { say g("mojolicious.org")->code }'

=head2 o

  my $res = o('example.com');
  my $res = o('http://example.com' => {Accept => '*/*'} => 'Hi!');
  my $res = o('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
  my $res = o('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});

Perform C<OPTIONS> request with L<Mojo::UserAgent/"options"> and return resulting L<Mojo::Message::Response> object.

=head2 p

  my $res = p('example.com');
  my $res = p('http://example.com' => {Accept => '*/*'} => 'Hi!');
  my $res = p('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
  my $res = p('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});

Perform C<POST> request with L<Mojo::UserAgent/"post"> and return resulting L<Mojo::Message::Response> object.

=head2 r

  my $perl = r({data => 'structure'});

Dump a Perl data structure with L<Mojo::Util/"dumper">.

  perl -Mojo -E 'say r g("example.com")->headers->to_hash'

=head2 t

  my $res = t('example.com');
  my $res = t('http://example.com' => {Accept => '*/*'} => 'Hi!');
  my $res = t('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
  my $res = t('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});

Perform C<PATCH> request with L<Mojo::UserAgent/"patch"> and return resulting L<Mojo::Message::Response> object.

=head2 u

  my $res = u('example.com');
  my $res = u('http://example.com' => {Accept => '*/*'} => 'Hi!');
  my $res = u('http://example.com' => {Accept => '*/*'} => form => {a => 'b'});
  my $res = u('http://example.com' => {Accept => '*/*'} => json => {a => 'b'});

Perform C<PUT> request with L<Mojo::UserAgent/"put"> and return resulting L<Mojo::Message::Response> object.

=head2 x

  my $dom = x('<div>Hello!</div>');

Turn HTML/XML input into L<Mojo::DOM> object.

  $ perl -Mojo -E 'say x(f("test.html")->slurp)->at("title")->text'

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.


=cut

POD
    },
);

my ( $fh, $file ) = tempfile( SUFFIX => ".pm" );

for my $case ( @cases ) {

    # Empty the tempfile.
    truncate $fh, 0;
    $fh->seek( 0, 0 );

    # Add some pod.
    print $fh $case->{pod};

    # Make at the beginning of the file.
    $fh->seek( 0, 0 );

    # Parse and compare
    is_deeply(
        Pod::LOL->new_root( $file ),
        $case->{expected_root},
        $case->{name},
    );
}

done_testing();

