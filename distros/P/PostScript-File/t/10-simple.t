#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use File::Spec ();

BEGIN {
  # RECOMMEND PREREQ: File::Temp 0.15 - need tempdir
  eval "use File::Temp 0.15 'tempdir';";
  plan skip_all => "File::Temp 0.15 required for testing" if $@;

  plan tests => 8;
}

use PostScript::File 2.00 qw(check_file);
ok(1); # module found

my $ps = PostScript::File->new();
isa_ok($ps, 'PostScript::File'); # object created

my $dir  = $ARGV[0] || tempdir(CLEANUP => 1);
my $name = "fi01simple";
my $out  = $ps->output( $name, $dir );
ok(1); # survived so far

is($ps->get_filename, undef, 'Did not set filename');

is($out, File::Spec->catfile( $dir, "$name.ps" ), 'expected output filename');

my $file = check_file( "$name.ps", $dir );
ok($file);
ok(-e $file);

# PNG output is disabled

eval { PostScript::File->new(png => 1) };
like($@, qr/^PNG output is no longer supported/, 'no PNG');
