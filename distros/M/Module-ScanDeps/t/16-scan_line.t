#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use Module::ScanDeps qw/scan_line/;

{
my $chunk=<<'EOT';
use strict;
EOT
my @array=scan_line($chunk);@array=sort @array;
is_deeply(\@array,[sort qw{strict.pm}]);
}

{
my $chunk=<<'EOT';
require 5.10;
EOT
my @array=scan_line($chunk);@array=sort @array;
is_deeply(\@array,[sort qw{feature.pm}]);
}

{# RT#48151
my $chunk=<<'EOT';
require __PACKAGE__ . "SomeExt.pm";
EOT
eval {
  scan_line($chunk);
};
is($@,'');
}

