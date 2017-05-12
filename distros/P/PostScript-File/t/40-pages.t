#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use File::Spec ();

BEGIN {
  # RECOMMEND PREREQ: File::Temp 0.15 - need tempdir
  eval "use File::Temp 0.15 'tempdir';";
  plan skip_all => "File::Temp 0.15 required for testing" if $@;

  plan tests => 6;
}

use charnames qw(:full);
use PostScript::File qw(check_file incpage_label incpage_roman);

my $hash = { headings => 1,
	     paper => 'US-Letter',
	     errors => 1,
	     debug => 2,
	     page => "viii",
	     incpage_handler => \&incpage_roman,
	     reencode => "ISOLatin1Encoding",
	     fontsuffix => "-latin1",
	     };
my $ps = PostScript::File->new( $hash );
isa_ok($ps, 'PostScript::File'); # object created

my $label = $ps->get_page_label();
is($label, "viii", 'page viii');
$ps->add_to_page( <<END_PAGE1 );
    [ (This is page $label) ] db_print
    /Helvetica-latin1 findfont
    12 scalefont
    setfont
    172 400 moveto
    (First page) show
END_PAGE1

$ps->newpage();
$label = $ps->get_page_label();
is($label, "ix", 'page ix');
my $msg = "Second Page: \N{LATIN SMALL LETTER E WITH CIRCUMFLEX} £";
$ps->add_to_page( <<END_PAGE2 );
    [ (This is page $label) ] db_print
    /Times-BoldItalic-latin1 findfont
    12 scalefont
    setfont
    172 400 moveto
    ($msg) show
END_PAGE2

my $dir  = $ARGV[0] || tempdir(CLEANUP => 1);
my $name = "fi04pages";
my $out  = $ps->output( $name, $dir );

is($ps->get_filename, undef, 'Did not set filename');

is($out, File::Spec->catfile( $dir, "$name.ps" ), 'expected output filename');

my $file = check_file( "$name.ps", $dir );
ok(-e $file);

__END__
