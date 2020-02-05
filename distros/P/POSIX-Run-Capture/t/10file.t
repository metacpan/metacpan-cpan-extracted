# -*- perl -*-

use lib 't', 'lib';

use strict;
use warnings;
use TestCapture;
use Test::More tests => 2;
use File::Temp;
use File::Cmp qw/fcmp/;
use File::Spec;

our($catbin, $input, $content);

my $fh = new File::Temp;
TestCapture({ argv => [$catbin, $input],
              stdout => $fh });
ok(fcmp($fh->filename, $input));

$fh = new File::Temp;
TestCapture({ argv => [$catbin, $input],
              stdout => $fh->filename });
ok(fcmp($fh->filename, $input));

