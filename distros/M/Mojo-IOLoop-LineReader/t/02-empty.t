
use Mojo::Base -strict;

use Test::More;

use Mojo::IOLoop::LineReader;
use File::Temp qw(tempfile :seekable);

# Create an empty temp file
my $tmp = tempfile();
print {$tmp} '';
$tmp->seek(0, SEEK_SET);    # rewind

my $r = Mojo::IOLoop::LineReader->new($tmp);
$r->on(
  readln => sub {
    my ($r, $line) = @_;
    fail("No 'read' event expected");
  }
);
$r->on(
  close => sub {
    pass("eof");
  }
);

$r->start;
$r->reactor->start;
done_testing;

