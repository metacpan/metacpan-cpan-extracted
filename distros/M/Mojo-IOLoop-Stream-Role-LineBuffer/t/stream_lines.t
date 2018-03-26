use strict;
use warnings;
use Test::More;
use Mojo::IOLoop;
use Mojo::IOLoop::Stream;

pipe my $read, my $write or die "Failed to open pipe: $!";

my @lines;
my $reader = Mojo::IOLoop::Stream->with_roles('+LineBuffer')->new($read)->watch_lines;
$reader->on(read_line => sub {
  my ($reader, $line, $sep) = @_;
  push @lines, [$line, $sep];
});
$reader->on(read => sub { Mojo::IOLoop->stop });
$reader->start;

my $writer = Mojo::IOLoop::Stream->with_roles('+LineBuffer')->new($write);
$writer->start;

$writer->write('foo');

my $timeout = Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
Mojo::IOLoop->remove($timeout);

is_deeply \@lines, [], 'no lines received';
@lines = ();

$writer->write("bar\x0Abaz");

$timeout = Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
Mojo::IOLoop->remove($timeout);

is_deeply \@lines, [['foobar', "\x0A"]], 'one line received';
@lines = ();

$writer->write_line('line?');

$timeout = Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
Mojo::IOLoop->remove($timeout);

is_deeply \@lines, [['bazline?', "\x0D\x0A"]], 'one line received';
@lines = ();

$reader->read_line_separator('bar');
$writer->write_line_separator('bar');
$writer->write_line("foobar\x0Abarbaz");

$timeout = Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
Mojo::IOLoop->remove($timeout);

is_deeply \@lines, [['foo', 'bar'],["\x0A",'bar'],['baz','bar']], 'three lines received';
@lines = ();

$reader->on(read => sub { shift->close });
$writer->write('garbage');

$timeout = Mojo::IOLoop->timer(0.1 => sub { Mojo::IOLoop->stop });
Mojo::IOLoop->start;
Mojo::IOLoop->remove($timeout);

is_deeply \@lines, [['garbage', undef]], 'remaining bytes received';

done_testing;
