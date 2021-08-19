use strict;
use warnings;
use PDL::Graphics::Simple;
use Test::More;
use File::Temp q/tempfile/;
use PDL;

my $tests_per_engine = 17;
my @engines = qw/gnuplot pgplot plplot prima/;
my $smoker = ($ENV{'PERL_MM_USE_DEFAULT'} or $ENV{'AUTOMATED_TESTING'});
$ENV{PGPLOT_DEV} ||= '/NULL' if $smoker;

sub ask_yn {
    my ($msg, $label) = @_;
    return pass $label if $smoker;
    print STDERR qq{\n\n$msg  OK? (Y/n) > };
    my $a = <STDIN>;
    unlike($a, qr/n/i, $label);
}

##############################
# Try the simple engine and convenience interfaces...

eval q: $a = xvals(50); lines $a sin($a/3) :;
plan skip_all => 'No plotting engines installed' if $@ =~ /Sorry, all known/;
is($@, '', "simple lines plot succeeded");
ok( defined($PDL::Graphics::Simple::global_object), "Global convenience object got spontaneously set" );
ask_yn q{  test>  $a = xvals(50); lines $a sin($a/3);
You should see a sine wave...}, "convenience plot OK";

eval q: erase :;
is($@, '', 'erase worked');
ok(!defined($PDL::Graphics::Simple::global_object), 'erase erased the global object');

eval "PDL::Graphics::Simple::show();";
is($@, '');

my $mods = do { no warnings 'once'; $PDL::Graphics::Simple::mods };
ok( (  defined($mods) and ref $mods eq 'HASH'  ) ,
    "module registration hash exists");

my $pgplot_ran = 0;
for my $engine (@engines) {
    my $w;

    my $module;
    ok( (  $mods->{$engine} and ref($mods->{$engine}) eq 'HASH' and ($module = $mods->{$engine}->{module}) ),
	"there is a modules entry for $engine ($module)" );

  SKIP: {
      my($check_ok);
      eval qq{\$check_ok = ${module}::check(1)};
      is($@, '', "${module}::check() ran OK");

      unless($check_ok) {
	  skip "Skipping tests for engine $engine (not working)", $tests_per_engine - 2;
      }
      $pgplot_ran ||= $engine eq 'pgplot';

      eval { $w = PDL::Graphics::Simple->new(engine=>$engine) };
      is($@, '', "contructor for $engine worked OK");
      isa_ok($w, 'PDL::Graphics::Simple', "contructor for $engine worked OK");

##############################
# Simple line & bin plot
      eval { $w->plot(with=>'line', xvals(10), xvals(10)->sqrt * sqrt(10),
		      with=>'bins', sin(xvals(10))*10,
		 {title=>"PDL: $engine engine, line & bin plots"}),

      };
      is($@, '', "plot succeeded\n");
      ask_yn qq{
Testing $engine engine: You should see a superposed line plot and bin
plot, with x range from 0 to 9 and yrange from 0 to 9. The two plots
should have different line styles.}, "line plot looks ok";



##############################
# Error bars plot
      eval { $w->plot( with=>'errorbars', xvals(37)*72/36, (xvals(37)/3)**2, xvals(37),
		       with=>'limitbars', sin(xvals(90)*4*3.14159/90)*30 + 72, xvals(90)/2, ones(90)*110,
		       {title=>"PDL: $engine engine, error (rel.) & limit (abs.) bars"}
		 ); };
      is($@, '', "errorbar plot succeeded"); print($@) if($@);
      ask_yn qq{Testing $engine engine: You should see error bars (symmetric relative to each
plotted point) and limit bars (asymmetric about each plotted point).}, "errorbars / limitbars OK";


##############################
# Image & circles plot
      eval { $w->plot(with=>'image', rvals(11,11),
		      with=>'circle', xvals(15), xvals(15)*1.5, sin(xvals(15))**2 * 4,
		      {title=>"PDL: $engine engine, image & circle plots (not justified)"}
		 );
      };
      is($@, '', "plot succeeded\n");
      ask_yn qq{Testing $engine engine: You should see a radial 11x11 "target" image
and some superimposed "circles".  Since the plot is not justified, the
pixels in the target image should be oblong and the "circles" should
be ellipses.}, "image and circles plot looks ok";

##############################
# Image & circles plot (justified)
      eval { $w->plot(with=>'image', rvals(11,11),
		      with=>'circle', xvals(15), xvals(15)*1.5, sin(xvals(15))**2 * 4,
		      {title=>"PDL: $engine engine, image & circle plots (justified)", j=>1}
		 );
      };
      is($@, '', "justified image and circles plot succeeded"); print($@) if($@);
      ask_yn qq{Testing $engine engine: You should see the same plot as before, but
justified.  superimposed "circles".  Since the plot is justified,
the pixels in the target image should be square and the "circles" should
really be circles.}, "justified image and circles plot looks ok";

##############################
# Log scaling

      eval { $w->plot(with=>'line',xvals(500)+1,{log=>'y',title=>"PDL: $engine engine, Y=X (semilog)"}); };
      is($@, '', "log scaling succeeded");
      ask_yn qq{Testing $engine engine: You should see a simple logarithmically scaled plot,
with appropriate title.}, "log scaled plot looks OK";


##############################
# Text

      eval { $w->plot(with=>'labels',
		      xvals(5), xvals(5),
		      ["<left-justified","<    left-with-spaces", "|centered","|>start with '>'",">right-justified"],
		      {title=>"PDL: $engine engine, text on graph", yrange=>[-1,5] }
		 );
      };
      is($@, '', "labels plot succeeded" );
      ask_yn qq{Testing $engine engine: You should see "left-justified" text left
aligned on x=0, "left-with-spaces" just right of x=1, "centered"
centered on x=2, ">start with '>'" centered on x=3, and
"right-justified" right-aligned on x=4.}, "labels plot looks OK";


##############################
# Multiplot
      eval { $w=new PDL::Graphics::Simple(engine=>$engine, multi=>[2,2]); };
      is($@, '', "Multiplot declaration was OK");
      $w->image( rvals(9,9),{wedge=>1} );       $w->image( -rvals(9,9),{wedge=>1} );
      $w->image( sequence(9,9) );    $w->image( pdl(xvals(9,9),yvals(9,9),rvals(9,9))*20 );
      ask_yn qq{Testing $engine engine: You should see two bullseyes across the top (one in
negative print), a gradient at bottom left, and an RGB blur (if supported
by the engine - otherwise a modified gradient) at bottom right.  The top two
panels should have colorbar wedges to the right of the image.}, "multiplot OK";
    }
}


# Continue the simple engine and convenience interfaces
##############################
# Test imag
my $im = 1000 * sin(rvals(100,100)/3) / (rvals(100,100)+30);

eval q{ imag $im };
is($@, '', "imag worked with no additional arguments" );
ask_yn q{  test> $im = 1000 * sin(rvals(100,100)/3) / (rvals(100,100)+30);
  test> imag $im;
You should see a bullseye pattern with a brighter inner ring.}, "bullseye OK";

eval q{ imag $im, {wedge=>1, title=>"Bullseye!"} };
is($@, '', "imag worked with plot options");
ask_yn q{  test> imag $im, {wedge=>1, title=>"Bullseye!", j=>1};
You should see the same image, but with a colorbar wedge on the right; a title
up top; and a justified aspect ratio (circular rings). The color scale may be
slightly less contrasty than the last frame, because some engines extend the
colorbar wedge to round numbers.}, "justified bullseye and wedge OK";

eval q{ imag $im, 0, 30, {wedge=>1, j=>1} };
is($@, '', "imag worked with bounds");
ask_yn q{  test> imag $im, 0, 30, {wedge=>1, j=>1};
You should see the same image, but with no title and with a tighter
dynamic range that cuts off the low values (black rings instead of
the fainter parts of the bullseye).}, "crange shortcut is OK";

eval q{ erase };
is($@, '', "erase executed");
my $extra = $pgplot_ran ? ' (for PGPLOT on X you need to close the X window to continue)' : '';
ask_yn qq{  test> erase
The window should have disappeared$extra.}, "erase worked";

done_testing;
