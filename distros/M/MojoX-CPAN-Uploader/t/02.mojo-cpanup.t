use strict;
use warnings;

use Test::More tests => 1;                      # last test to print

use IPC::Open3;
use File::Spec;

my($wtr, $rdr, $err);

my $pid =
  open3($wtr, $rdr, $err, $^X, '-c',
    File::Spec->catfile(qw/blib script mojo-cpanup/));

my $result = join '', <$rdr>;
chomp $result;

like($result, qr/syntax OK/);
