
use Mojo::Base -strict;

use Test::More;

use Mojo::IOLoop::LineReader;
use File::Temp qw(tempfile :seekable);

# Create a temp file with "0" as content
my $tmp = tempfile();
print {$tmp} '0';
$tmp->seek(0, SEEK_SET);    # rewind

my $i = 0;                  # line counter

my $r = Mojo::IOLoop::LineReader->new($tmp);
$r->on(
  readln => sub {
    my ($r, $line) = @_;
    $i++;
    is($i,    1,   "First line");
    is($line, "0", "Contains '0'");
  }
);
$r->on(
  close => sub {
    is($i, 1, "eof (after 1 read)");
  }
);

$r->start;
$r->reactor->start;
done_testing;

