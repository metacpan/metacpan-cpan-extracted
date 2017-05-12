#!perl
local($|) = 1;

BEGIN {
    our $tests_per_engine = 17;
    our @engines = qw/gnuplot pgplot plplot prima/;

}
use Test::More tests=> ( + 3                              # up-front
			 + (@engines)*($tests_per_engine) # in per-engine loop
			 + 14                             # down-back
    );

use File::Temp q/tempfile/;
use PDL;

our $smoker = ($ENV{'PERL_MM_USE_DEFAULT'} or $ENV{'AUTOMATED_TESTING'});

sub get_yn{
    my $default = shift || 'y';
    if($smoker) {
	return $default;
    } else {
	my $a = <STDIN>;
	return $a;
    }
}

##############################
# Module loads properly
eval "use PDL::Graphics::Simple;";
ok(!$@);

eval "PDL::Graphics::Simple::show();";
ok(!$@);

*mods = \$PDL::Graphics::Simple::mods;
*mods = \$PDL::Graphics::Simple::mods; # duplicate to shut up the typo detector.
ok( (  defined($mods) and ref $mods eq 'HASH'  ) ,
    "module registration hash exists");

for $engine(@engines) {
    my $w;

    ok( (  $mods->{$engine} and ref($mods->{$engine}) eq 'HASH' and ($module = $mods->{$engine}->{module}) ),
	"there is a modules entry for $engine ($module)" );

  SKIP: {
      my($check_ok);
      eval qq{\$check_ok = ${module}::check(1)};
      ok(!$@, "${module}::check() ran OK");

      unless($check_ok) {
	  skip "Skipping tests for engine $engine (not working)", $tests_per_engine - 2;
      }

      eval { $w = new PDL::Graphics::Simple(engine=>$engine) };
      ok( ( !$@ and ref($w) eq 'PDL::Graphics::Simple' ), "contructor for $engine worked OK");


##############################
# Simple line & bin plot
      eval { $w->plot(with=>'line', xvals(10), xvals(10)->sqrt * sqrt(10), 
		      with=>'bins', sin(xvals(10))*10,
		 {title=>"PDL: $engine engine, line & bin plots"}),

      };
      ok(!$@, "plot succeeded\n");
      print $@ if($@);
      print STDERR qq{
Testing $engine engine: You should see a superposed line plot and bin
plot, with x range from 0 to 9 and yrange from 0 to 9. The two plots
should have different line styles.  OK? (Y/n) > };

      $a = get_yn();
      ok( $a !~ m/^n/i, "line plot looks ok" );



##############################
# Error bars plot
      eval { $w->plot( with=>'errorbars', xvals(37)*72/36, (xvals(37)/3)**2, xvals(37),
		       with=>'limitbars', sin(xvals(90)*4*3.14159/90)*30 + 72, xvals(90)/2, ones(90)*110,
		       {title=>"PDL: $engine engine, error (rel.) & limit (abs.) bars"}
		 ); };
      ok(!$@, "errorbar plot succeeded"); print($@) if($@);
      
      print STDERR qq{
Testing $engine engine: You should see error bars (symmetric relative to each
plotted point) and limit bars (asymmetric about each plotted point).
OK? (Y/n) > };

      $a = get_yn(); 
      ok( $a !~ m/^n/i,
	  "errorbars / limitbars OK");


##############################
# Image & circles plot
      eval { $w->plot(with=>'image', rvals(11,11), 
		      with=>'circle', xvals(15), xvals(15)*1.5, sin(xvals(15))**2 * 4,
		      {title=>"PDL: $engine engine, image & circle plots (not justified)"}
		 );
      };
      ok(!$@, "plot succeeded\n");
      print $@ if($@);
      print STDERR qq{
Testing $engine engine: You should see a radial 11x11 "target" image
and some superimposed "circles".  Since the plot is not justified, the
pixels in the target image should be oblong and the "circles" should
be ellipses.  OK? (Y/n) > };
      $a = get_yn(); 
      ok( $a !~ m/^n/i,
	  "image and circles plot looks ok");

##############################
# Image & circles plot (justified)
      eval { $w->plot(with=>'image', rvals(11,11), 
		      with=>'circle', xvals(15), xvals(15)*1.5, sin(xvals(15))**2 * 4,
		      {title=>"PDL: $engine engine, image & circle plots (justified)", j=>1}
		 );
      };
      ok(!$@, "justified image and circles plot succeeded"); print($@) if($@);
      print STDERR qq{
Testing $engine engine: You should see the same plot as before, but
justified.  superimposed "circles".  Since the plot is justified,
the pixels in the target image should be square and the "circles" should
really be circles.  OK? (Y/n) > };

      $a = get_yn(); 
      ok( $a !~ m/^n/i,
	  "justified image and circles plot looks ok");

##############################
# Log scaling

      eval { $w->plot(with=>'line',xvals(500)+1,{log=>'y',title=>"PDL: $engine engine, Y=X (semilog)"}); };
      ok(!$@, "log scaling succeeded");
      print STDERR qq{
Testing $engine engine: You should see a simple logarithmically scaled plot,
with appropriate title.  OK? (Y/n) > };

      $a = get_yn();
      ok( $a !~ m/^n/i,
	  "log scaled plot looks OK");


##############################
# Text

      eval { $w->plot(with=>'labels', 
		      xvals(5), xvals(5), 
		      ["<left-justified","<    left-with-spaces", "|centered","|>start with '>'",">right-justified"],
		      {title=>"PDL: $engine engine, text on graph", yrange=>[-1,5] }
		 );
      };
      ok( !$@, "labels plot succeeded" );
      print STDERR qq{
Testing $engine engine: You should see "left-justified" text left
aligned on x=0, "left-with-spaces" just right of x=1, "centered"
centered on x=2, ">start with '>'" centered on x=3, and
"right-justified" right-aligned on x=4.  OK? (Y/n) > };
      $a = get_yn();
      ok( $a !~ m/^n/i,
	  "labels plot looks OK");
      

##############################
# Multiplot
      eval { $w=new PDL::Graphics::Simple(engine=>$engine, multi=>[2,2]); };
      ok(!$@, "Multiplot declaration was OK");
      
      $w->image( rvals(9,9),{wedge=>1} );       $w->image( -rvals(9,9),{wedge=>1} );
      $w->image( sequence(9,9) );    $w->image( pdl(xvals(9,9),yvals(9,9),rvals(9,9)) );
      
      print STDERR qq{
Testing $engine engine: You should see two bullseyes across the top (one in 
negative print), a gradient at bottom left, and an RGB blur (if supported
by the engine - otherwise a modified gradient) at bottom right.  The top two
panels should have colorbar wedges to the right of the image.
OK? (Y/n) > };

$a = get_yn();
      ok($a !~ m/^n/i,
	 "multiplot OK");


    }

}


##############################
# Try the simple engine and convenience interfaces...

print STDERR<<'FOO';

##############################
Convenience interface tests...
FOO

ok( !defined($PDL::Graphics::Simple::global_object), "Global convenience object not defined" );

eval q: $a = xvals(50); lines $a sin($a/3) :;
ok(!$@, "simple lines plot succeeded");

ok( defined($PDL::Graphics::Simple::global_object), "Global convenience object got spontaneously set" );

print STDERR q{
  test>  $a = xvals(50); lines $a sin($a/3); 
You should see a sine wave... OK? (Y/n) > };


$a = get_yn();
ok($a !~ m/^n/i, "convenience plot OK");

eval q: erase :;
ok(!$@, 'erase worked');
ok(!defined($PDL::Graphics::Simple::global_object), 'erase erased the global object');

##############################
# Test imag 
$im = 0; # shut up the typo detector
$im = 1000 * sin(rvals(100,100)/3) / (rvals(100,100)+30);

eval q{ imag $im };
ok(!$@, "imag worked with no additional arguments" );

print STDERR q{
  test> $im = 1000 * sin(rvals(100,100)/3) / (rvals(100,100)+30);
  test> imag $im;
You should see a bullseye pattern with a brighter inner ring.  OK? (Y/n) > };


$a=get_yn();
ok($a !~ m/^n/i, "bullseye OK");

eval q{ imag $im, {wedge=>1, title=>"Bullseye!"} };
ok(!$@, "imag worked with plot options");

print STDERR q{
  test> imag $im, {wedge=>1, title=>"Bullseye!", j=>1};
You should see the same image, but with a colorbar wedge on the right; a title
up top; and a justified aspect ratio (circular rings). The color scale may be 
slightly less contrasty than the last frame, because some engines extend the 
colorbar wedge to round numbers.   Ok? (Y/n) > };

$a = get_yn();
ok($a !~ m/^n/i, "justified bullseye and wedge OK");


eval q{ imag $im, 0, 30, {wedge=>1, j=>1} };
ok(!$@, "imag worked with bounds");

print STDERR q{
  test> imag $im, 0, 30, {wedge=>1, j=>1};
You should see the same image, but with no title and with a tighter 
dynamic range that cuts off the low values (black rings instead of
the fainter parts of the bullseye).  Ok? (Y/n) > };

$a = get_yn();
ok($a !~ m/^n/i, "crange shortcut is OK");

eval q{ erase };
ok(!$@, "erase executed");

print STDERR qq{
  test> erase
The window should have disappeared.  Ok? (Y/n) > };

$a = get_yn();
ok($a !~ m/^n/i, "erase worked");

print "End of tests\n";
