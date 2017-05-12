use strict;
use warnings;
use Test::More;
use File::Find qw(find);

find({
  wanted => sub {
    return if not /\.pl$/i;
    ok(`$^X -Mblib -c $_ 2>&1` =~ /syntax OK$/, $_);
  },
  no_chdir => 1,
}, 'examples');

done_testing;
