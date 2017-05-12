# vim: filetype=perl ts=2 sw=2 expandtab

use strict;
use warnings;

use Test::More;
use HTTP::Headers;

sub DEBUG () { 0 }

plan tests => 20;

use_ok ('POE::Filter::HTTPChunk');

{ # all chunks in one go.
  my @results = qw( chunk_333 chunk_4444);
  my @input = ("9\nchunk_333\nA\nchunk_4444\n0\n");
  my $filter = POE::Filter::HTTPChunk->new;
  my $pending = $filter->get_pending;
  is ($pending, undef, "got no pending data");

  foreach my $data (@input) {
    $filter->get_one_start( [$data] );

    my $output;
    while ($output = $filter->get_one and @$output > 0) {
      is_deeply($output, \@results, "got expected chunks");
    }
  }
  $pending = $filter->get_pending;
  # TODO: ugh, must fix this
  is_deeply ($pending, [''], "got no pending data");
}
{ # with a fabricated chunk-extension. the filter doesn't handle
  # those, but they do get ignored, as required.
  my @results = qw( chunk_333 chunk_4444);
  my @input = ("9\nchunk_333\nA;foo=bar\nchunk_4444\n0\n");
  my $filter = POE::Filter::HTTPChunk->new;

  foreach my $data (@input) {
    $filter->get_one_start( [$data] );

    my $output;
    while ($output = $filter->get_one and @$output > 0) {
      is_deeply($output, \@results, "got expected chunks");
    }
  }
}
{ # with garbage before the chunk length
  my @results = qw( chunk_333 chunk_4444);
  my @input = ("9\nchunk_333\ngarbage\nA\nchunk_4444\n0\n");
  my $filter = POE::Filter::HTTPChunk->new;

  foreach my $data (@input) {
    $filter->get_one_start( [$data] );

    my $output;
    while ($output = $filter->get_one and @$output > 0) {
      is(shift @$output, shift @results, "got expected chunk");
    }
  }
}
{ # with trailing headers
  my @results = (
    qw( chunk_1 chunk_22 ),
    HTTP::Headers->new(Server => 'Apache/1.3.31 (Unix) DAV/1.0.3 mod_gzip/1.3.26.1a PHP/4.3.5 mod_ssl/2.8.19 OpenSSL/0.9.6c'),
  );
  my @input = ("7\nchunk_1\n8\nchunk_22\n0\nServer: Apache/1.3.31 (Unix) DAV/1.0.3 mod_gzip/1.3.26.1a PHP/4.3.5 mod_ssl/2.8.19 OpenSSL/0.9.6c\n\n");

  my $filter = POE::Filter::HTTPChunk->new;
  foreach my $data (@input) {
    $filter->get_one_start( [$data] );

    my $output;
    while ($output = $filter->get_one and @$output > 0) {
      is_deeply($output, \@results, "got expected chunks");
    }
  }
}
{ # with trailing headers and garbage after
  my @results = (
    qw( chunk_1 chunk_22 ),
    HTTP::Headers->new(Server => 'Apache/1.3.31 (Unix) DAV/1.0.3 mod_gzip/1.3.26.1a PHP/4.3.5 mod_ssl/2.8.19 OpenSSL/0.9.6c'),
  );
  my @input = ("7\nchunk_1\n8\nchunk_22\n0\nServer: Apache/1.3.31 (Unix) DAV/1.0.3 mod_gzip/1.3.26.1a PHP/4.3.5 mod_ssl/2.8.19 OpenSSL/0.9.6c\n\ngarbage");

  my $filter = POE::Filter::HTTPChunk->new;
  foreach my $data (@input) {
    $filter->get_one_start( [$data] );

    my $output;
    while ($output = $filter->get_one and @$output > 0) {
      is_deeply($output, \@results, "got expected chunks");
    }
  }
  my $pending = $filter->get_pending;
  is (shift @$pending, 'garbage', "got expected pending data");
}
{ # with whitespace after the chunksize
  my @results = qw(regular_chunk chunk_length_with_trailing_whitespace);
  my @input = ("d\nregular_chunk\n25   \nchunk_length_with_trailing_whitespace\n0\n",
  );

  my $filter = POE::Filter::HTTPChunk->new;
  foreach my $data (@input) {
    $filter->get_one_start( [$data] );

    my $output;
    while ($output = $filter->get_one and @$output > 0) {
      is_deeply($output, \@results, "got expected chunks");
    }
  }
}
{ # several pieces of input, this time cleverly split so the size
  # marker can't be read immediately because the ending newline is
  # in the next piece.
  my @results = qw( chunk_333 chunk_4444);
  my @input = ("9\nchunk_333\nA", "\nchunk_4444\n0\n");
  my $filter = POE::Filter::HTTPChunk->new;

  foreach my $data (@input) {
    $filter->get_one_start( [$data] );

    my $output;
    while ($output = $filter->get_one and @$output > 0) {
      is(shift @$output, shift @results, "got expected chunk");
    }
  }
}
{ # with garbage before the chunk length and some strategic
  # splits for coverage
  my @results = qw( chunk_333 chunk_4444);
  my @input = ("9\nchunk_333\n","garbage","\nA\nchunk_4444\n0\n");
  my $filter = POE::Filter::HTTPChunk->new;

  foreach my $data (@input) {
    $filter->get_one_start( [$data] );

    my $output;
    while ($output = $filter->get_one and @$output > 0) {
      is(shift @$output, shift @results, "got expected chunk");
    }
  }
}
{ # several pieces of input cleverly split for coverage.
  my @results = qw( chunk_333 chunk_4444);
  my @input = ("9\nchunk_333", "\n", "A\nchun", "k_4444\n0\n");
  my $filter = POE::Filter::HTTPChunk->new;

  foreach my $data (@input) {
    $filter->get_one_start( [$data] );

    my $output;
    while ($output = $filter->get_one and @$output > 0) {
      is(shift @$output, shift @results, "got expected chunk");
    }
  }
}
{ # extra garbage at the end gets retrieved by get_pending()
  my @results = qw( chunk_333 chunk_4444);
  my @input = ("9\nchunk_333\nA\nchunk_4444\n0\ngarbage");
  my $filter = POE::Filter::HTTPChunk->new;

  foreach my $data (@input) {
    $filter->get_one_start( [$data] );

    my $output;
    while ($output = $filter->get_one and @$output > 0) {
      is_deeply($output, \@results, "got expected chunks");
    }
  }
  my $pending = $filter->get_pending;
  is (shift @$pending, 'garbage', "got expected pending data");
}
{ # extra-extra garbage at the end gets retrieved by get_pending()
  my @input = ("9\nchunk_333\nA\nchunk_4444\n", "0\n", "7\ngarbage\n", "0\n");
  my $filter = POE::Filter::HTTPChunk->new;
  $filter->get_one_start( \@input );

  my $output = $filter->get_one();
  is_deeply($output, [qw/chunk_333 chunk_4444/], "got expected chunks");

  my $pending = $filter->get_pending;
  is_deeply($pending, ["7\ngarbage\n0\n"], "got expected pending data");
}
