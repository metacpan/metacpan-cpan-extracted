#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use File::Spec ();

BEGIN {
  # RECOMMEND PREREQ: File::Temp 0.15 - need tempdir
  eval "use File::Temp 0.15 'tempdir';";
  plan skip_all => "File::Temp 0.15 required for testing" if $@;

  plan tests => 9;
}

use PostScript::File qw(check_file);
ok(1); # module found

my $ps = PostScript::File->new(
    eps => 1,
    headings => 1,
    width => 160,
    height => 112,
    );
isa_ok($ps, 'PostScript::File'); # object created

$ps->add_to_page( <<END_PAGE );
    /Helvetica findfont
    12 scalefont
    setfont
    50 50 moveto
    (hello world) show
END_PAGE
my $page = $ps->get_page_label();
is($page, '1', "page 1");
ok($ps->get_page());

my $dir  = $ARGV[0] || tempdir(CLEANUP => 1);
my $name = "fi02eps";
my $out  = $ps->output( $name, $dir );
ok(1); # survived so far

is($ps->get_filename, undef, 'Did not set filename');

is($out, File::Spec->catfile( $dir, "$name.epsf" ), 'expected output filename');

my $file = check_file( "$name.epsf", $dir );
ok($file);
ok(-e $file);
