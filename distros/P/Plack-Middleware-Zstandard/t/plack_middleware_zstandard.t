use Test2::V0 -no_srand => 1;
use experimental qw( signatures );
use Plack::Builder;
use Test2::Tools::HTTP qw( :short psgi_app_guard );
use HTTP::Request::Common;
use Compress::Stream::Zstd::Decompressor;

subtest 'basic' => sub {

  our @res;

  my $app = psgi_app_guard builder {
    enable 'Zstandard';
    sub { return \@res };
  };

  subtest 'short string' => sub {

    my $content = 'Hello World';
    local @res = ( 200, [ 'Content-Type' => 'text/plain', 'Content-Length' => length($content) ], [ $content ] );

    req(
      GET('/', 'Accept-Encoding' => 'zstd'),
      res {
        code 200;
        content_type 'text/plain';
        header 'Content-Length' => DNE();
        header 'Content-Encoding' => 'zstd';
        header 'Vary', 'Accept-Encoding';
      },
    );

    is(
      decompress(),
      'Hello World',
      'content',
    );

  };

  subtest 'short string as array' => sub {

    my @content = ('Hello', undef, ' ', 'World');
    local @res = ( 200, [ 'Content-Type' => 'text/plain', 'Content-Length' => length(join '', grep defined, @content) ], [ @content ] );

    req(
      GET('/', 'Accept-Encoding' => 'zstd'),
      res {
        code 200;
        content_type 'text/plain';
        header 'Content-Length' => DNE();
        header 'Content-Encoding' => 'zstd';
        header 'Vary', 'Accept-Encoding';
      },
    );

    is(
      decompress(),
      'Hello World',
      'content',
    );

  };

  subtest 'no content status' => sub {

    local @res = ( 304, [], [''] );

    req(
      GET('/', 'Accept-Encoding' => 'zstd'),
      res {
        code 304;
        header 'Content-Encoding' => DNE();
        header 'Vary', DNE();
        call content => '';
      },
    );

    note_debug();

  };

  subtest 'Cache-Control: no-transform' => sub {

    my $content = 'Hello World';
    local @res = (
      200, [
        'Content-Type' => 'text/plain',
        'Content-Length' => length($content),
        'Cache-Control' => 'no-transform',
      ], [
        $content
      ]
    );

    req(
      GET('/', 'Accept-Encoding' => 'zstd'),
      res {
        code 200;
        header 'Content-Encoding' => DNE();
        header 'Vary', DNE();
        header 'Content-Length' => length($content);
        call content => 'Hello World';
      },
    );

    note_debug();

  };

  subtest 'do not clobber' => sub {

    my $content = 'Hello World';
    local @res = (
      200, [
        'Content-Type' => 'text/plain',
        'Content-ENcoding' => 'foo',
      ], [
        $content
      ]
    );

    req(
      GET('/', 'Accept-Encoding' => 'zstd'),
      res {
        code 200;
        header 'Content-Encoding' => 'foo';
        header 'Vary', 'Accept-Encoding';
        call content => 'Hello World';
      },
    );

    note_debug();

  };

  subtest 'No accept' => sub {

    my $content = 'Hello World';
    local @res = (
      200, [
        'Content-Type' => 'text/plain',
        'Content-Length' => length($content),
      ], [
        $content
      ]
    );

    req(
      GET('/'),
      res {
        code 200;
        header 'Content-Encoding' => DNE();
        header 'Vary', 'Accept-Encoding';
        header 'Content-Length' => length($content);
        call content => 'Hello World';
      },
    );

    note_debug();

  };

  subtest 'stream' => sub {

    my $content = 'Hello World';
    open my $fh, '<', \$content;
    local @res = ( 200, [ 'Content-Type' => 'text/plain' ], $fh );

    req(
      GET('/', 'Accept-Encoding' => 'zstd'),
      res {
        code 200;
        content_type 'text/plain';
        header 'Content-Length' => DNE();
        header 'Content-Encoding' => 'zstd';
        header 'Vary', 'Accept-Encoding';
      },
    );

    is(
      decompress(),
      'Hello World',
      'content',
    );

  };

};

subtest 'level' => sub {

  my @last_new_args;
  my $mock = mock 'Compress::Stream::Zstd::Compressor' => (
    before => [
      new => sub ($class, @args) {
        @last_new_args = @args;
      },
    ],
  );

  subtest 'override level = 22' => sub {

    my $app = psgi_app_guard builder {
      enable 'Zstandard', level => 22;
      sub { return [ 200, ['Content-Type' => 'text/plain'], ['Hello World']] };
    };

    req(
      GET('/', 'Accept-Encoding' => 'zstd'),
      res {
        code 200;
        content_type 'text/plain';
        header 'Content-Length' => DNE();
        header 'Content-Encoding' => 'zstd';
        header 'Vary', 'Accept-Encoding';
      },
    );

    is(
      decompress(),
      'Hello World',
      'content',
    );

    is(
      \@last_new_args,
      [22],
      'expected args',
    );
  };

  subtest 'default' => sub {

    my $app = psgi_app_guard builder {
      enable 'Zstandard';
      sub { return [ 200, ['Content-Type' => 'text/plain'], ['Hello World']] };
    };

    req(
      GET('/', 'Accept-Encoding' => 'zstd'),
      res {
        code 200;
        content_type 'text/plain';
        header 'Content-Length' => DNE();
        header 'Content-Encoding' => 'zstd';
        header 'Vary', 'Accept-Encoding';
      },
    );

    is(
      decompress(),
      'Hello World',
      'content',
    );

    is(
      \@last_new_args,
      [],
      'expected args',
    );
  };
};

subtest 'vary' => sub {

  subtest 'do not vary' => sub {

    my $app = psgi_app_guard builder {
      enable 'Zstandard', vary => 0;
      sub { return [ 200, ['Content-Type' => 'text/plain'], ['Hello World']] };
    };

    req(
      GET('/', 'Accept-Encoding' => 'zstd'),
      res {
        code 200;
        content_type 'text/plain';
        header 'Content-Length' => DNE();
        header 'Content-Encoding' => 'zstd';
        header 'Vary', DNE();
      },
    );

    is(
      decompress(),
      'Hello World',
      'content',
    );

  };
};

sub note_debug {
  note $_ for map { $_->as_string} (tx->req, tx->res);
}

sub decompress {
  note $_ for map { $_->as_string} (tx->req, tx->res->headers);
  note '';
  my $decompressor = Compress::Stream::Zstd::Decompressor->new;
  my $decoded_content = $decompressor->decompress(tx->res->content);
  note $decoded_content;
  return $decoded_content;
}

done_testing;
