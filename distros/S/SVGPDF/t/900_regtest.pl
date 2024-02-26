#! perl

use strict;
use warnings;

# Integration tests.
#
# We intercept the debugging output and compare these.

use Test::More;
use Config;
our $api;

BEGIN {
    use_ok($api);
    use_ok("SVGPDF");
}

# For some specific build variants.
my $var = $Config{uselongdouble} ? "-ld" : "";
diag("Using variant $var") if $var;
my $test = 2;

BAIL_OUT("Missing test data") unless -d "regtest";

# Setup PDF context.
my $pdf = $api->new;
my $page = $pdf->page;
my $gfx = $page->gfx;

my $fccalls = {};

my $p = SVGPDF->new
  ( pdf => $pdf, fc => \&fonthandlercallback,
    atts => { debug    => 1, wstokens => 1 } );

ok( $p, "Have SVGPDF object" );
$test++;

# Collect the test files.
opendir( my $dh, "regtest" ) || BAIL_OUT("Cannot open test data");
my @files = grep { /^.+\.svg$/ } readdir($dh);
close($dh);
diag("Testing ", scalar(@files), " SVG files with $api");

foreach my $file ( sort @files ) {
    $file = "regtest/$file";
    #diag("Testing: $file");
    ( my $out = $file ) =~ s/\.svg/.out/;
    ( my $ref = $file ) =~ s/\.svg/.ref/;
    ( my $vref = $file ) =~ s/\.svg/$var.ref/;

    my $o;

    # Run test, and intercept stderr.
    my $errfd;
    open( $errfd, '>&', \*STDERR );
    close(STDERR);
    open( STDERR, '>:utf8', $out );
    $o = eval { $p->process( $file, reset => 1 ) };
    close(STDERR);
    open( STDERR, '>&', $errfd );

    my $ok = $o && @$o;
    ok( $ok, "Have XO results" );
    $test++;
    if ( $var && -s $vref ) {
	$ref = $vref;
	diag("Using ref = $ref");
    }
    $ok = -s $ref && !differ( $out, $ref );
    ok( $ok, $file );
    $test++;
    unlink($out), next if $ok;
    system( $ENV{SVGPDF_DIFF}, $out, $ref) if $ENV{SVGPDF_DIFF};
}

ok( $test == 2*@files+3, "Tested @{[0+@files]} files" );

# Callback should be called at most once per fam/style/weight.
for ( keys %$fccalls ) {
    is( $fccalls->{$_}, 1, "$_ font handler callbacks" );
    $test++;
}

return ++$test;

use File::LoadLines qw( loadlines );

sub differ {
    my ($file1, $file2) = @_;
    $file2 = "$file1" unless $file2;
    $file1 = "$file1";

    my @lines1 = loadlines($file1);
    my @lines2 = loadlines($file2);
    my $linesm = @lines1 > @lines2 ? @lines1 : @lines2;
    for ( my $line = 1; $line < $linesm; $line++ ) {
	$lines1[$line] //= "***missing***1";
	$lines2[$line] //= "***missing***2";
	next if $lines1[$line] eq $lines2[$line];
	Test::More::diag("Files $file1 and $file2 differ at line $line");
	Test::More::diag("  <  $lines1[$line]");
	Test::More::diag("  >  $lines2[$line]");
	return 1;
    }
    return 0 if @lines1 == @lines2;
    $linesm++;
    Test::More::diag("Files $file1 and $file2 differ at line $linesm" );
    Test::More::diag("  <  ", $lines1[$linesm] // "***missing***1");
    Test::More::diag("  >  ", $lines2[$linesm] // "***missing***2");
    1;
}

my $font;
sub fonthandlercallback {
    my ( $self, %args ) = @_;
    my $pdf   = $args{pdf};
    my $style = $args{style};
    my $key   = join("|", map { $_ // "normal" } @{$style}{qw(font-family font-style font-weight)});
    $fccalls->{$key}++;
    $font //= $pdf->font('Times-Roman');
}
