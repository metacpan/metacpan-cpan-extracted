
use Mojo::Base -strict;

use Test::More;

use Mojo::IOLoop::LineReader;
use File::Temp qw(tempfile :seekable);

# This tests lines as read by LineReader match simple <> loop

my @TESTS = (
  {content => [], name => 'empty file',},
  {
    content => [
      'a' x 30 . "\n",    #
      'b' x 20 . "\n",    #
      'c' x 25 . "\n",    #
      'd' x 10
    ],
    name => 'regular file'
  },
  {content => [], name => 'file with "0"',},
  {
    content => ["a\n\n", "b\nc\n\n", "d\n\n\n",],
    name    => 'file by paragraphs',

    input_record_separator => '',
  },
  {
    content => [
      "---\na:3\n...\n",        #
      "---\n[1,2,3]\n...\n",    #
      "---\nx: 42\ny: 43\n...\n",
    ],
    name => 'file with "\n...\n" separator',

    input_record_separator => "\n...\n",
  },
  {
    content => ["The quick brown fox jumps over the lazy dog\n" x 10],
    name    => 'file with undef separator',

    input_record_separator => undef,
  },
  {
    content => [('a' x 20 . "\n") x (int(131072 / 21) + 1)],
    name => 'big file (> 131072 bytes)',
  },
);

plan tests => 2 * scalar @TESTS;

for my $t (@TESTS) {
  my @content = @{$t->{content}};
  my $name    = $t->{name};                             # FIXME use test name
  my $rs      = $t->{input_record_separator} // "\n";

  # Write content to temp file
  my $tmp = tempfile();
  print {$tmp} join('', @content);

  # use <>
  $tmp->seek(0, SEEK_SET);                              # rewind
  my @expected = do { local $/ = $rs; <$tmp> };
  push @expected, \"eof";

  # use LineReader
  {
    $tmp->seek(0, SEEK_SET);                            # rewind
    my @output;
    local $/ = $rs;
    my $r = Mojo::IOLoop::LineReader->new($tmp);
    $r->on(readln => sub { my ($r, $line) = @_; push @output, $line; });
    $r->on(close => sub { push @output, \"eof"; });
    $r->start;
    $r->reactor->start;

    is_deeply(\@output, \@expected, $name);
  }

  # use LineReader + input_record_separator
  {
    $tmp->seek(0, SEEK_SET);    # rewind
    my @output;
    my $r = Mojo::IOLoop::LineReader->new($tmp)->input_record_separator($rs);
    $r->on(readln => sub { my ($r, $line) = @_; push @output, $line; });
    $r->on(close => sub { push @output, \"eof"; });
    local $/ = "oops!\n";
    $r->start;
    $r->reactor->start;

    is_deeply(\@output, \@expected, "$name - using attr");
  }
}

