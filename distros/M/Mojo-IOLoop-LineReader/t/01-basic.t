
use Mojo::Base -strict;

use Test::More;

use Mojo::IOLoop::LineReader;
use File::Temp qw(tempfile :seekable);

my @content = (    #
  'a' x 30 . "\n",    #
  'b' x 20 . "\n",    #
  'c' x 25 . "\n",    #
  'd' x 10
);

plan tests => 1 + scalar @content;

# Write content to temp file
my $tmp = tempfile();
print {$tmp} join('', @content);
$tmp->seek(0, SEEK_SET);    # rewind

my $i = 0;                  # line counter

my $r = Mojo::IOLoop::LineReader->new($tmp);
$r->on(
  readln => sub {
    my ($r, $line) = @_;
    $i++;
    is($line, shift @content, "line $i");
  }
);
$r->on(
  close => sub {
    ok(!@content, "eof");
  }
);

$r->start;
$r->reactor->start;

