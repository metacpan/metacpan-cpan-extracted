#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Path::Maker;
sub to_dist { local $_ = shift; s{::}{-}g; $_      }
sub to_path { local $_ = shift; s{::}{/}g; "$_.pm" }

my $module = shift or die "usage: $0 Your::Module\n";

my $maker = Path::Maker->new(
    template_dir    => "$FindBin::Bin/share",
    template_header => "? my \$arg = shift;\n",
);

my $dist  = to_dist($module);
my $path  = to_path($module);
my $arg   = {
    module_name => $module,
    module_path => "lib/$path",
    user        => $ENV{USER},
    today       => scalar(localtime),
};

$maker->create_dir($dist);
$maker->render_to_file('Makefile.PL'    => "$dist/Makefile.PL",   $arg);
$maker->render_to_file('Changes'        => "$dist/Changes",       $arg);
$maker->render_to_file('Module'         => "$dist/lib/$path",     $arg);
$maker->render_to_file('t/00_compile.t' => "$dist/t/00_copile.t", $arg);
$maker->render_to_file('script.pl'      => "$dist/script.pl",     $arg);
$maker->chmod("$dist/script.pl", 0755);
$maker->write_file("$dist/.proverc", "-l -v t\n");
