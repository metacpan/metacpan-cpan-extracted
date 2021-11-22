use strict;
use warnings;
use Test::More;
use Mojo::IOLoop;

subtest 'Basic line buffering' => sub {
  my @outputs;
  my $server = Mojo::IOLoop->server(address => '127.0.0.1', sub {
    my ($loop, $stream, $id) = @_;
    $stream->with_roles('+LineBuffer')->watch_lines;
    $stream->on(read_line => sub {
      my ($stream, $line, $sep) = @_;
      push @outputs, [$line, $sep];
    });
    $stream->on(read => sub { Mojo::IOLoop->stop });
  });
  my $port = Mojo::IOLoop->acceptor($server)->port;

  my $client = Mojo::IOLoop->client(address => '127.0.0.1', port => $port, sub {
    my ($loop, $err, $stream) = @_;
    $stream->write('foo');
  });

  my $timeout = Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timeout);

  is_deeply \@outputs, [], 'no lines received';
  @outputs = ();

  my $input_stream = Mojo::IOLoop->stream($client);
  $input_stream->write("bar\x0Abaz");

  $timeout = Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timeout);

  is_deeply \@outputs, [['foobar', "\x0A"]], 'one line received';
  @outputs = ();

  $input_stream->with_roles('+LineBuffer')->write_line('line?');

  $timeout = Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timeout);

  is_deeply \@outputs, [['bazline?', "\x0D\x0A"]], 'one line received';

  Mojo::IOLoop->reset;
};

subtest 'Custom line separators' => sub {
  my @outputs;
  my $server = Mojo::IOLoop->server(address => '127.0.0.1', sub {
    my ($loop, $stream, $id) = @_;
    $stream->with_roles('+LineBuffer')->watch_lines->read_line_separator('bar');
    $stream->on(read_line => sub {
      my ($stream, $line, $sep) = @_;
      push @outputs, [$line, $sep];
    });
    $stream->on(read => sub { Mojo::IOLoop->stop });
  });
  my $port = Mojo::IOLoop->acceptor($server)->port;

  my $client = Mojo::IOLoop->client(address => '127.0.0.1', port => $port, sub {
    my ($loop, $err, $stream) = @_;
    $stream->with_roles('+LineBuffer')->write_line_separator('bar')->write_line("foobar\x0Abarbaz");
  });

  my $timeout = Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timeout);

  is_deeply \@outputs, [['foo', 'bar'],["\x0A",'bar'],['baz','bar']], 'three lines received';

  Mojo::IOLoop->reset;
};

subtest 'Multiple lines on close' => sub {
  my @outputs;
  my $server = Mojo::IOLoop->server(address => '127.0.0.1', sub {
    my ($loop, $stream, $id) = @_;
    $stream->with_roles('+LineBuffer')->watch_lines->read_line_separator('1');
    $stream->on(read_line => sub {
      my ($stream, $line, $sep) = @_;
      push @outputs, [$line, $sep];
    });
    $stream->on(read => sub { Mojo::IOLoop->stop; shift->read_line_separator('2')->close });
  });
  my $port = Mojo::IOLoop->acceptor($server)->port;

  my $client = Mojo::IOLoop->client(address => '127.0.0.1', port => $port, sub {
    my ($loop, $err, $stream) = @_;
    $stream->write('before1mid2after');
  });

  my $timeout = Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timeout);

  is_deeply \@outputs, [['before', '1'], ['mid', '2'], ['after', undef]], 'remaining lines and bytes received';

  Mojo::IOLoop->reset;
};

subtest 'Line separator on close' => sub {
  my @outputs;
  my $server = Mojo::IOLoop->server(address => '127.0.0.1', sub {
    my ($loop, $stream, $id) = @_;
    $stream->with_roles('+LineBuffer')->watch_lines;
    $stream->on(read_line => sub {
      my ($stream, $line, $sep) = @_;
      push @outputs, [$line, $sep];
    });
    $stream->on(read => sub { Mojo::IOLoop->stop; shift->read_line_separator('3')->close });
  });
  my $port = Mojo::IOLoop->acceptor($server)->port;

  my $client = Mojo::IOLoop->client(address => '127.0.0.1', port => $port, sub {
    my ($loop, $err, $stream) = @_;
    $stream->write('bar3');
  });

  my $timeout = Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timeout);

  is_deeply \@outputs, [['bar', '3']], 'remaining line received';

  Mojo::IOLoop->reset;
};

subtest 'No line separator on close' => sub {
  my @outputs;
  my $server = Mojo::IOLoop->server(address => '127.0.0.1', sub {
    my ($loop, $stream, $id) = @_;
    $stream->with_roles('+LineBuffer')->watch_lines;
    $stream->on(read_line => sub {
      my ($stream, $line, $sep) = @_;
      push @outputs, [$line, $sep];
    });
    $stream->on(read => sub { Mojo::IOLoop->stop; shift->read_line_separator('4')->close });
  });
  my $port = Mojo::IOLoop->acceptor($server)->port;

  my $client = Mojo::IOLoop->client(address => '127.0.0.1', port => $port, sub {
    my ($loop, $err, $stream) = @_;
    $stream->write('bar');
  });

  my $timeout = Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timeout);

  is_deeply \@outputs, [['bar', undef]], 'remaining bytes received';

  Mojo::IOLoop->reset;
};

subtest 'Closing stream in read_line event' => sub {
  my @outputs;
  my $server = Mojo::IOLoop->server(address => '127.0.0.1', sub {
    my ($loop, $stream, $id) = @_;
    $stream->with_roles('+LineBuffer')->watch_lines;
    $stream->on(read_line => sub {
      my ($stream, $line, $sep) = @_;
      push @outputs, [$line, $sep];
      $stream->close;
    });
    $stream->on(read => sub { Mojo::IOLoop->stop });
  });
  my $port = Mojo::IOLoop->acceptor($server)->port;

  my $client = Mojo::IOLoop->client(address => '127.0.0.1', port => $port, sub {
    my ($loop, $err, $stream) = @_;
    $stream->with_roles('+LineBuffer')->write_line('foo');
  });

  my $timeout = Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
  Mojo::IOLoop->start;
  Mojo::IOLoop->remove($timeout);

  is_deeply \@outputs, [['foo', "\x0D\x0A"]], 'one line received';

  Mojo::IOLoop->reset;
};

done_testing;
