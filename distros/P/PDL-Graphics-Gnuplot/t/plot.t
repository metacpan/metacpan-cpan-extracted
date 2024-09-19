use strict;
use warnings;
use Test::More;
use PDL::Graphics::Gnuplot qw(plot gpwin);
use File::Temp qw(tempfile);
use PDL;
use PDL::Transform::Cartography; # t_raster2fits

##########
# Uncomment these to test error handling on Microsoft Windows, from within POSIX....
# $PDL::Graphics::Gnuplot::debug_echo = 1;
# $PDL::Graphics::Gnuplot::MS_io_braindamage = 1;

$ENV{GNUPLOT_DEPRECATED} = 1;   # shut up deprecation warnings
my $w=eval { gpwin() };

is $@, '';
isa_ok($w, 'PDL::Graphics::Gnuplot', "Constructor created a plotting object");

isnt $PDL::Graphics::Gnuplot::gp_version, '', "Extracted a version string from gnuplot" or diag "Raw output: '$PDL::Graphics::Gnuplot::raw_output'";

diag( "\nP::G::G v$PDL::Graphics::Gnuplot::VERSION, gnuplot v$PDL::Graphics::Gnuplot::gp_version, Perl v$], $^X on $^O #\n" );

my $x = sequence(5);

##############################
#
our (undef, $testoutput) = tempfile('pdl_graphics_gnuplot_test_XXXXXXX');

{
  # test basic plotting
  eval{ plot ( {terminal => 'dumb 79 24', output => $testoutput}, $x); };
  is($@, '',           'basic plotting succeeded without error' );
  ok(-e $testoutput, 'basic plotting created an output file' );
  # call the output good if it's at least 80% of the nominal size
  my @filestats = stat $testoutput;
  cmp_ok($filestats[7], '>', 79*24*0.8, 'basic plotting created a reasonably-sized file');
  PDL::Graphics::Gnuplot::restart();
  unlink($testoutput) or diag "\$!: $!";
}

ok($PDL::Graphics::Gnuplot::gp_version, "gp_version is nonzero after first use of P::G::G");

##############################
#
{
  # purposely fail.  This one should fail by sensing that "bogus" is bogus, *before* sending
  # anything to Gnuplot.

  eval{ plot ( {terminal => 'dumb 79 24', output => $testoutput, silent=>1}, with => 'bogus', $x); };
  like $@, qr/invalid plotstyle \'with\ bogus\' in plot/s,  'we find bogus "with" before sending to gnuplot';

  eval{ plot( {terminal => 'dumb 79 24', output=>$testoutput, topcmds=>"this should fail"}, with=>'line', $x); };
  like $@, qr/invalid command/o, "we detect an error message from gnuplot";

  PDL::Graphics::Gnuplot::restart();

  unlink($testoutput) or warn "\$!: $!";
}

##############################
#
eval { $w = gpwin( 'dumb', size=>[79,24],output=>$testoutput, wait=>1) };
is($@, '', "constructor works");
isnt ref $w, '', "constructor works";

SKIP:{
    # Check timeout.
    skip "Skipping timeout test, which doesn't work under MS Windows", 1
	if($PDL::Graphics::Gnuplot::MS_io_braindamage);
    eval { $w->plot ( { topcmds=>'pause 2'}, with=>'line', $x) };
    like($@, qr/1 second/, "gnuplot response timeout works");
}

eval { $w->restart };
is($@, '', "restart worked OK\n");
undef $w;
ok(1, "destructor worked OK\n");

##############################
# Test options parsing

# Some working variables
$x = xvals(51);
my $y = $x*$x;

do {
 # Object options passed into plot are transient
    $w = gpwin('dumb',size=>[79,24,'ch'], output=>$testoutput);
    $w->options(xr=>[0,30]);
    is_deeply $w->{options}{xrange}, [0, 30],
	"xr sets xrange option properly in options call";
    $w->plot($x);

    my @lines = do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };
    is( 0+@lines, 24, "setting 79x24 character dumb output yields 24 lines of output");
    like $lines[-2], qr/.*\s30\s*$/,
      "xrange option generates proper X axis (and dumb terminal behaves as expected)";

    $w->{options}{output} = "${testoutput}2";
    $w->plot($x,{xr=>[0,5]});

    @lines = do { open my $fh, "<", "${testoutput}2" or die "${testoutput}2: $!"; <$fh> };
    like $lines[-2], qr/.*\s5\s*$/,
      "inline xrange option overrides stored xrange option (and dumb terminal behaves as expected)";

    is_deeply $w->{options}{xrange}, [0, 30],
	"inline xrange does not change stored xrange option";

    is_deeply $w->{last_plot}{options}{xrange}, [0, 5],
	"inline xrange is stored in last_plot options";
    undef $w;
};

unlink("${testoutput}2") or warn "\$!: $! for '${testoutput}2'";
unlink($testoutput) or warn "\$!: $! for '$testoutput'";

##############################
# Test manual reset in multiplots
#
# Normally we issue a "reset" before sending options for each plot, to ensure that
# gnuplot is in a known state -- but in multiplots we can't do that or we'd break the
# multiplot.  We attempt to eradicate leftover state in gnuplot, so we have to test
# that.  The main thing is that labels should be cleared.
{
    $w = gpwin('dumb',size=>[79,24,'ch'], output=>$testoutput);
    $w->multiplot(layout=>[1,2]);
    $w->line(xvals(5)**2,{xlabel=>"FOO BAR BAZ"});
    $w->line(xvals(5)**2); # no xlabel -- should not print one
    $w->end_multi;
    undef $w;
    my @lines = grep m/FOO BAR BAZ/, do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };
    is 0+@lines, 1, "xlabel gets reset on multiplots";
}

{
  my $w = gpwin('dumb',size=>[79,24,'ch'], output=>$testoutput);
  my $text = eval { $w->multiplot_generate(layout=>[1,2]); };
  is($@, '', "multiplot_generate succeeded");
  like $text, qr/set multiplot\s+layout 2,1/, 'multiplot_generate';
  $text = eval { $w->multiplot_next_generate };
  is($@, '', "multiplot_next_generate succeeded");
  like $text, qr/set multiplot next/, 'multiplot_next_generate';
  $text = eval { $w->end_multi_generate };
  is($@, '', "end_multi_generate succeeded");
  like $text, qr/unset multiplot/, 'end_multi_generate';
}

{
  my $w = gpwin('dumb',size=>[79,24,'ch'], output=>$testoutput);
  my $r9 = rvals(9,9);
  eval {$w->plot({colorbox => 1},{with => 'image'},$r9->xvals,$r9->yvals,$r9)};
  is($@, '', "colorbox succeeded");
  for my $dims ([3,9,9],[4,9,9],[9,9,3],[9,9,4]) {
    eval {$w->plot({with => 'image'},$r9->xvals,$r9->yvals,rvals(@$dims))};
    is($@, '', "regularising image succeeded (@$dims)");
  }
  eval {$w->plot({with => 'fits'},$r9)};
  isnt $@, '', "with 'fits' only if FITS header";
  my @dims = $r9->dims;
  my $h = PDL::Graphics::Gnuplot::_make_fits_hdr(@dims[0,1], 1, 1, 0, 0, @dims[0,1], qw(X Y Pixels Pixels));
  $r9->sethdr($h);
  eval {$w->plot({with => 'fits'},$r9)};
  is($@, '', "with 'fits'");
  eval {$w->plot({with => 'fits', resample=>1},$r9)};
  is($@, '', "with 'fits', resample");
  eval {$w->plot({with => 'fits', resample=>[100,100]},$r9)};
  is($@, '', "with 'fits', resample [100,100]");
  my $r9_rgb = pdl(0,$r9,$r9)->mv(-1,0); $r9_rgb->slice(0) .= 6; $r9_rgb *= 20;
  eval {$w->plot({with => 'fits'}, t_raster2fits()->apply($r9_rgb))};
  is($@, '', "with 'fits', rgb");
}

{
  my $w = gpwin('dumb',size=>[79,24,'ch'], output=>$testoutput);
  my $r9 = rvals(9,9);
  eval {$w->plot({colorbox => 1},{with => 'image'},$r9->xvals,$r9->yvals,$r9,
    {with=>'lines'}, xvals(5)**2,
  )};
  is($@, '', "both image and non-image to exercise image-range path");
}

if ($PDL::Graphics::Gnuplot::gp_version >= 4.7) { # only 4.7+
  $w = gpwin('dumb',size=>[79,24,'ch'], output=>$testoutput);
  $w->multiplot(layout=>[1,2]);
  $w->line(xvals(5)**2,{xlabel=>"FOO BAR BAZ"});
  $w->multiplot_next;
  $w->end_multi;
  undef $w;
  my @lines = grep m/FOO BAR BAZ/, do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };
  is 0+@lines, 1, "xlabel gets reset on multiplots";
}

##############################
# Test ascii data transfer (binary is tested by default on platforms where it works)
eval {$w = gpwin('dumb', size=>[79,24,'ch'],output=>$testoutput);};
is $@, '';
ok($w,"opened window for ascii transfer tests");

eval { $w->options( binary=>0 ); };
is $@, '', "set binary mode to 0";

eval { $w->plot( xvals(5), xvals(5)**2 ); };
is($@, '', "ascii plot succeeded");

eval { $w->plot( [xvals(5)->list], [(xvals(5)**2)->list] ); };
is($@, '', "ascii array-ref plot succeeded");

my $text = eval { $w->plot_generate( xvals(5), xvals(5)**2 ); };
is($@, '', "plot_generate succeeded");
like $text, qr/plot\s*\$PGG_data_\d+\s*using 1:2 notitle with lines\s*dt solid/, 'plot_generate';

eval { $w->plot( xvals(10000), xvals(10000)->sqrt ); };
is($@, '', "looong ascii plot succeeded ");

##############################
# Test replotting

eval {$w = gpwin('dumb',size=>[79,24,'ch'], output=>$testoutput)};
is $@, '';
ok($w,"re-opened window");

eval { $w->plot({xr=>[0,30]},xvals(50),xvals(50)**2); };
is($@, ''," plot works");

my @lines = do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };
is(0+@lines, 24, "test plot made 24 lines");

eval { $w->restart(); };
is($@, '',"restart succeeded");

unlink($testoutput) or warn "\$!: $!";
ok(!(-e $testoutput), "test file got deleted");

eval { $w->replot(); };
is($@, '', "replot works");

my @l2 = do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };
$w->restart;
unlink($testoutput) or warn "\$!: $!";
is(0+@l2, 24, "test replot made 24 lines");

is_deeply \@lines, \@l2, "replot reproduces output";

eval { $w->replot(xvals(50),40*xvals(50)) };
is($@, '', "replotting and adding a line works");

# lame test - just make sure the plots include at least two lines
# and that one is higher than the other.
my @l3 = do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };
$w->restart;
unlink($testoutput) or warn "\$!: $!";
is(0+@l3, 24, "test replot again made 24 lines");

if($w->{gp_version} == 5.0 && $Alien::Gnuplot::pl==0
   or
   $w->{gp_version} == 5.2 && $Alien::Gnuplot::pl==0
) {
    # gnuplot 5.0 patchlevel 0 uses plusses and hyphens to draw curves in ASCII
    # match whitespace / curve / whitespace / curve / whitespace  on line 12
    like($l3[12], qr/\s+[\-\+]+\s+[\-\+]+\s+/, "test plot has two curves");
} else {
    # most gnuplots use #'s and *'s for the first two ASCII curves
    like($l3[12], qr/\#\s+\*/, "test plot has two curves and curve 2 is above curve 1");
}

# test that options updating modifies the replot
eval { $w->options(yrange=>[200,400]);  $w->replot(); };
is($@, '', "options set and replot don't crash");

my @l4 = do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };
$w->restart;
unlink($testoutput) or warn "\$!: $!";
is 0+@l4, 24, "replot made 24 lines after option set";

my $diff = grep $l3[$_] ne $l4[$_], 0..23;
ok($diff, "modifying plot option affects replot");

##############################
# Test parsing of plot options when provided before curve options

$w = gpwin('dumb',size=>[79,24,'ch'], output=>$testoutput);
eval { $w->plot(xmin=>3, xvals(10),xvals(10)); };
is($@, '', "plot() worked for x,y plot with unescaped plot option");

eval { $w->plot(ls=>4,xmin=>3,xvals(10),xvals(10)) };
like($@, qr/No curve option found that matches \'xmin\'/, "xmin after a curve option fails (can't mix curve and plot options)");

eval { $w->plot(xmin=>3,xrange=>[4,5],xvals(10),xvals(10)) };
is($@, '', "plot works when curve options are given after plot options");
my @l5 = do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };
like($l5[22], qr/^\s*4\s+.*\s+5\s+$/, "curve option range overrides plot option range");

##############################
# Test parsing of plot options as arrays and/or PDLs, mixed.

eval { $w->plot(xmin=>3,xrange=>[4,5],xvals(10),[1,2,3,4,5,6,7,8,9,10])};
is($@, '', "two arguments, second one is an array, works OK");

eval { $w->plot(xmin=>3,xrange=>[4,5],[1,2,3,4,5,6,7,8,9,10],xvals(10))};
is($@, '', "two arguments, first one is an array, works OK");

eval { $w->plot([1,2,3,4,5],[6,7,8,9,10]);};
is($@, '', "two arguments, both arrays, works OK");

eval { $w->plot3d([1,2,3,4,5],[6,7,8,9,10],[6,7,8,9,10]);};
is($@, '', "plot3d all arguments are arrays, works OK");

eval { $w->gplot(with => 'points', pdl(0..2), pdl(0..2));};
is($@, '', "gplot points all arguments are pdls, works OK");

eval { $w->gplot(with => 'points', [ 0, 1, 2 ], [ 0, 1, 2 ]);};
is($@, '', "gplot points all arguments are arrays, works OK");

eval { $w->plot(xmin=>3,xrange=>[4,5],xvals(10),[1,2,3])};
like($@, qr/mismatch/, "Mismatch detected in array size vs. PDL size");

##############################
# Test placement of topcmds, extracmds, and bottomcmds
eval { $w->plot(xmin=>3,extracmds=>'reset',xrange=>[4,5],xvals(10),xvals(10)**2); };
is($@, '', "extracmds does not cause an error");
like($PDL::Graphics::Gnuplot::last_plotcmd, qr/\nreset\n(?:\$PGG_.*?\n)?plot/, "extracmds inserts exactly one copy in the right place");

eval { $w->plot(xmin=>3,topcmds=>'reset',xrange=>[4,5],xvals(10),xvals(10)**2);};
is($@, '', "topcmds does not cause an error");
like($PDL::Graphics::Gnuplot::last_plotcmd, qr/set\s+output\s+\"[^\"]+\"\s+reset\s+set\s+palette/o, "topcmds inserts exactly one copy in the right place");

eval { $w->plot(xmin=>3,bottomcmds=>'reset',xrange=>[4,5],xvals(10),xvals(10)**2);};
is($@, '', "bottomcmds does not cause an error");
like($PDL::Graphics::Gnuplot::last_plotcmd, qr/\s+reset\s*$/o, "bottomcmds inserts exactly one copy in the right place");

##############################
# Test tuple size determination: 2-D, 3-D, and variables (palette and variable)
# We do not test the entire lookup table, just that the basic code is working

eval { $w->plot(xvals(10)); } ;
is($@, '', "2-D line plot accepts one PDL");

eval { $w->plot(xvals(10),xvals(10)); };
is($@, '', "2-D line plot accepts two PDLs");

eval { $w->plot(xvals(10),xvals(10),xvals(10));};
like($@, qr/Found 3 PDLs for 2D plot type/, "2-D line plot rejects three PDLs");

eval { $w->plot(ps=>'variable',with=>'points',xvals(10),xvals(10),xvals(10)) };
is($@, '', "2-D plot with one variable parameter takes three PDLs");

eval { $w->plot(ps=>'variable',with=>'points',xvals(10),xvals(10),xvals(10),xvals(10)) };
like($@, qr/Found 4 PDLs for 2D/, "2-D plot with one variable parameter rejects four PDLs");

SKIP: {
    skip "Skipping unsupported mode for deprecated earlier gnuplot",1
	if($PDL::Graphics::Gnuplot::gp_version < 4.4);
    eval { $w->plot3d(xvals(10,10))};
    is($@, '', "3-D plot accepts one PDL if it is an image");
};

eval { $w->plot3d(xvals(10),xvals(10)); };
like($@, qr/Found 2 PDLs for 3D/,"3-D plot rejects two PDLs");

eval { $w->plot3d(xvals(10),xvals(10),xvals(10)); };
is($@, '', "3-D plot accepts three PDLs");

eval { $w->plot3d(xvals(10),xvals(10),xvals(10),xvals(10)); };
like($@, qr/Found 4 PDLs for 3D/,"3-D plot rejects four PDLs");

eval { $w->plot3d(ps=>'variable',with=>'points',xvals(10),xvals(10),xvals(10),xvals(10));};
is($@, '', "3-D plot accepts four PDLs with one variable element");

eval { $w->plot3d(with=>'points',ps=>'variable',palette=>1,xvals(10),xvals(10),xvals(10),xvals(10));};
like($@, qr/Found 4 PDLs for 3D/,"3-D plot rejects four PDLs with two variable elements");

SKIP: {
    skip "Skipping unsupported mode for deprecated earlier gnuplot",1
	if($PDL::Graphics::Gnuplot::gp_version < 4.4);
    eval { $w->plot3d(with=>'points',ps=>'variable',palette=>1,xvals(10),xvals(10),xvals(10),xvals(10),xvals(10));};
    is($@, '', "3-D plot accepts five PDLs with one variable element");
}    ;

eval { $w->plot3d(with=>'points',ps=>'variable',palette=>1,xvals(10),xvals(10),xvals(10),xvals(10),xvals(10),xvals(10));};
like($@, qr/Found 6 PDLs for 3D/,"3-D plot rejects six PDLs with two variable elements");


##############################
# Test threading in arguments
eval { $w->plot(legend=>['line 1'], pdl(2,3,4)); };
is($@, '', "normal legend plotting works OK");

eval { $w->plot(legend=>['line 1', 'line 2'], pdl(2,3,4)); };
like($@, qr/Legend has 2 entries; but 1 curve/, "Failure to thread crashes");

eval { $w->plot(legend=>['line 1'], pdl([2,3,4],[1,2,3])); };
like($@, qr/Legend has 1 entry; but 2 curve/, "Failure to thread crashes (other way)");

eval { $w->plot(legend=>['line 1','line 2'], pdl([2,3,4],[1,2,3]),[3,4,5]) };
like($@, qr/only 1-D PDLs are allowed to be mixed with array/, "Can't thread with array refs");

eval { $w->plot(legend=>['line 1','line 2'], pdl([2,3,4],[1,2,3]),[3,4]) };
like($@, qr/only 1-D PDLs/, "Mismatched arguments are rejected");

##############################
# Test non-persistence of autoset options
eval { $w->options(xrange=>[1,2]); };
is_deeply $w->{options}{xrange}, [1, 2], "xrange set ok\n";

eval { $w->reset; $w->restart; };
is($@, '', "reset was ok\n");

is $w->{options}{xrange}, undef, "reset cleared xrange option";

eval { $w->plot(with=>'lines', xvals(5)); };
is $w->{options}{xrange}, undef, "plotting a line did not set xrange option";

eval { $w->plot(with=>'image', rvals(5,5)); };
is $w->{options}{xrange}, undef, "plotting an image did not set xrange option";

##############################
# Test esoteric argument parsing

eval { $w->plot(with=>'lines',y2=>3,xvals(5)); };
like($@, qr/No curve option found that matches \'y2\'/,"y2 gets rejected");

eval { $w->plot(with=>'lines',xvals(5),{lab2=>['foo',at=>[2,3]]}); };
is($@, '', "label is accepted ($@)");

##############################
# Test xtics simple-case handling

eval { $w->restart; $w->output('dumb',output=>$testoutput) };
is($@, '', "gnuplot restart works");

eval { $w->reset; } ;
is($@, '', "gnuplot reset works");

sub get_axis_testoutput {
    my $file = shift;
    my @lines = do { open my $fh, "<", $file or die "$file: $!"; <$fh> };
    chomp for @lines;
    for my $i(0..$#lines) {
	last if( $lines[$#lines] =~ m/[^\s]/ );
	pop @lines;
    }
    my $line = $lines[-1];
    $line =~ s/^\s+//;
    $line;
}

eval { $w->plot(xvals(50)->sqrt) };
is $@, '', "plotting after reset worked ok with autotics";

my $line_nums = get_axis_testoutput($testoutput);
is_deeply [split /\s+/,$line_nums], [0,5,10,15,20,25,30,35,40,45,50], "autogenerated tics work (case 1)";

eval { $w->plot(xvals(50)->sqrt,{xtics=>0}) };
is($@, '', "xvals plot (no xtics) succeeded");

like($w->{last_plotcmd}, qr/unset xtics/, "xtics=>0 generated an 'unset xtics' command");

$line_nums = get_axis_testoutput($testoutput);
like $line_nums, qr/-------------------------------/, "No labels with xtics=>0";

eval { $w->plot(xvals(50)->sqrt,{"mxtics"=>{}})};
is($@, '', "plot with mxtics set to a hash succeeded");

eval { $w->plot(xvals(50)->sqrt,{xtics=>10})};
is($@, '', "xvals plot(xtics=>10) succeeded");

$line_nums = get_axis_testoutput($testoutput);
is_deeply [split /\s+/,$line_nums], [0,10,20,30,40,50], "tics with spacing 10 work";

eval { $w->plot(xvals(50)->sqrt, {xtics=>[]}) };
is($@, '', "xvals plot (xtics=>[]) succeeded");

$line_nums = get_axis_testoutput($testoutput);
is_deeply [split /\s+/,$line_nums], [0,5,10,15,20,25,30,35,40,45,50], "autogenerated tics work (case 2)";

undef $w;
unlink($testoutput) or warn "\$!: $!";

##############################
# Test some random plot options parsing cases

eval { $w=gpwin('dumb',output=>$testoutput) };
is($@, '', "constructor still works");

eval { $w->plot(xvals(500)-10, xvals(500)+40, { autoscale=>{} }) };
is($@, '', "autoscale accepts an empty hash ref");

my $ticks = get_axis_testoutput($testoutput);
is_deeply [split /\s+/,$ticks], [-50,0,50,100,150,200,250,300,350,400,450,500], "autoscale=>{} gives correct scaling";

eval { $w->plot(xvals(500)-10,xvals(500)+40,{ autoscale=>{x=>'fix'}}); };
is($@, '', "autoscale accepts a non-empty hash ref");

$ticks = get_axis_testoutput($testoutput);
is_deeply [split /\s+/,$ticks], [0,50,100,150,200,250,300,350,400,450], "autoscale=>{x=>fix} fixes the X axis scaling";

undef $w;
unlink($testoutput) or warn "\$!: $!";


##############################
# Check default-location plotting
if( -e 'Plot-1.txt' ) {
    unlink 'Plot-1.txt' or warn "Can't delete Plot-1.txt: $!";
}
eval {$w = gpwin('dumb',size=>[80,24]);};
is($@, '',"creation of dumb terminal with no output option works ($@)");
eval {$w->line(xvals(50)**2);};
is($@, '',"plotting to default output device works ($@)");
eval {undef $w;};
is($@, '',"closing default output window works");
ok((-e 'Plot-1.txt'),"correct file got created by default output");
unlink 'Plot-1.txt' or warn "Can't delete Plot-1.txt after test: $!";


###########
# Test size option parsing -- inches by default, also
# accepts both array ref and scalar parameters.
eval {$w=gpwin('dumb',size=>[7,5]); $w->line(xvals(50)**2); $w->close;};
is($@, '', "plotting to 42x30 text file worked");
@lines = eval { open my $fh, "<", "Plot-1.txt" or die "Plot-1.txt: $!"; <$fh> };
is($@, '', "read ASCII plot OK");
eval { unlink 'Plot-1.txt';};

is(@lines+0, 30, "'7x5 inch' ascii plot created 30 lines (created ".(0+@lines).")");

eval {$w=gpwin('dumb',size=>5); $w->line(xvals(50)**2); $w->close;};
is($@, '', "plotting to 30x30 text file worked");
@lines = eval { open my $fh, "<", "Plot-1.txt" or die "Plot-1.txt: $!"; <$fh> };
is($@, '', "Read ASCII plot #2 OK");
eval { unlink 'Plot-1.txt';};

is(@lines+0, 30,"'5x5 inch' ascii plot with scalar size param worked");

##############################
# Interactive tests

sub ask_yn {
  my ($msg, $label) = @_;
  print STDERR "\n\n$msg (Y/n)";
  my $a = <STDIN>;
  unlike($a, qr/n/i, $label);
}

SKIP: {
    unless(exists($ENV{GNUPLOT_INTERACTIVE})) {
	diag "******************************\nSkipping 27 interactive tests.\n    Set the environment variable GNUPLOT_INTERACTIVE to enable them.\n******************************";
	skip "Skipping interactive tests - set env. variable GNUPLOT_INTERACTIVE to enable.",29;
    }

    for (qw(qt wxt x11)) {
      eval { $w = gpwin($_) };
      last if !$@;
    }
    is($@, '', "created a plot object");

    isa_ok $PDL::Graphics::Gnuplot::termTab->{$w->{terminal}}, 'HASH', "Terminal is a known type";

    ok($PDL::Graphics::Gnuplot::termTab->{$w->{terminal}}->{disp}, "Default terminal is a display type");
    print STDERR "\n\nwindow is type ".$w->{terminal}."\n\n";
    my $x = sequence(101)-50;

    eval { $w->plot($x**2); };
    is($@, '', "plot a parabola to a the display window");
    ask_yn "Is there a display window and does it show a parabola?", "parabola looks OK";

    if($PDL::Graphics::Gnuplot::termTab->{$w->{terminal}}->{disp}>1) {
	ask_yn "Mouse over the plot window. Are there metrics at bottom that update?", "parabola has metrics";
	if($PDL::Graphics::Gnuplot::gp_version < 4.6) {
	    print STDERR "\n\nYou're running an older gnuplot ($PDL::Graphics::Gnuplot::gp_version) and \nwon't be able to scroll.  You should upgrade.  Skipping scroll test.\n\n";
	    ok(1,"no scroll/zoom test");
	} else {
	    ask_yn "Try to scroll and zoom the parabola using the scrollbar or (mac) two-fingered\n scrolling in Y; use SHIFT to scroll in X, CTRL (command on mac) to zoom.  Does it work?", "parabola can be scrolled and zoomed";
	}
    } else {
	print STDERR "\n\nThe $w->{terminal} gnuplot terminal has no built-in metrics, skipping that test.\n\n";
	ok(1,"skipping metrics test");
	print STDERR "\n\nThe $w->{terminal} gnuplot terminal has no interactive zoom, skipping that test.\n\n";
	ok(1,"skipping interactive-zoom test");
    }

    eval { $w->reset; $w->plot( {title=>"Demo of two curves with Y1 and Y2", xl=>"X",yl=>"Y1",y2l=>"Y2"},
				{axes=>'x1y1',leg=>'X^{2} (on Y1)'},xvals(50),xvals(50)**2,
				{axes=>'x1y2',leg=>'X^{5} (on Y2)'},xvals(50),xvals(50)**5,
				{y2t=>[0,5e7,4e8],y2r=>[0,3.5e8]}
	       );};
    print $PDL::Graphics::Gnuplot::last_plotcmd."\n";
    ask_yn "Are there two curves labeled X^2 and X^5, with about the same vertical extent on the plot?", "two curves are OK";
    ask_yn "Are there appropriate tick marks in both Y1 and Y2 on opposite sides of the plot?\n  (There should be no ghost ticks from Y1 on the Y2 axis, or vice versa).", "ticks look OK";

    eval { $w->reset; $w->options(binary=>0,tee=>1); $w->plot( {title => "Parabola with error bars"},
				with=>"xyerrorbars", legend=>"Parabola",
				$x**2 * 10, abs($x)/10, abs($x)*5 ); };
    print $PDL::Graphics::Gnuplot::last_plotcmd."\n";
    ask_yn "Are there error bars in both X and Y, both increasing away from the vertex, wider in X than Y?", "error bars are OK";

    my $xy = zeros(21,21)->ndcoords - pdl(10,10);
    my $z = inner($xy, $xy);
    eval {     $w->reset; $w->plot({title  => 'Heat map',
				    '3d' => 1,
				    view=>[50,30,1],
				    zrange=>[-1,1]
				   },
				   with => 'image', $z*2);
    };
    is($@, '', "3-d plot didn't crash");
    ask_yn "Do you see a purple-yellow colormap image of a radial target, in 3-D?", "3-D heat map plot works OK";
    ask_yn "Try to rotate, pan, and zoom the 3-D image.  Work OK?", "Interact with 3-D image";

    my $pi    = 3.14159;
    my $theta = zeros(200)->xlinvals(0, 6*$pi);
    $z     = zeros(200)->xlinvals(0, 5);
    eval { $w->reset; $w->plot3d(cos($theta), sin($theta), $z); };
    is($@, '', "plot3d works");
    ask_yn "See a nice 3-D plot of a spiral?", "See a nice 3-D plot of a spiral?";

    $x = xvals(5);
    $y = xvals(5)**2;
    my $labels = ['one','two','three','four','five'];
    eval { $w->reset; $w->plot(xr=>[-1,6],yr=>[-1,26],with=>'labels',$x,$y,$labels); };
    ask_yn "See the labels with words 'one','two','three','four', and 'five'?", "labels plot is OK";

    $x = xvals(51)-25; $y = $x**2;
    eval { $w->reset; $w->plot({title=>"Parabolic fit"},
		 with=>"yerrorbars", legend=>"data", $x, $y+(random($y)-0.5)*2*$y/20, pdl($y/20),
		 with=>"lines",      legend=>"fit",  $x, $y); };
    is($@, '', "mocked-up fit plot works");
    ask_yn "See a green parabola with red error bar points on it?", "parabolic plot is OK";

    $theta = xvals(201) * 6 * $pi / 200;
    $z     = xvals(201) * 5 / 200;
    eval { $w->reset; $w->plot( {'3d' => 1, title => 'double helix'},
	    with => 'linespoints', pointsize=>'variable', pointtype=>2, palette=>1 ,
	    legend => 'spiral 1',
	    cos($theta), sin($theta), $z, 0.5 + abs(cos($theta)*2),
	    sin($theta/3),
	    with => 'linespoints', pointsize=>'variable', pointtype=>4, palette=>1 ,
	    legend => 'spiral 2',
	    -cos($theta), -sin($theta), $z, 0.5 + abs(cos($theta)*2),
	    sin($theta/3)
	);};
    is($@, '', "double helix plot worked");
    ask_yn "See a double helix plot with variable point sizes and variable color?", "double helix plot is OK";

    eval { $w->reset; $w->plot( with=>'image', rvals(9,9), {xr=>[undef,9]}) };
    is($@, '', "image plot succeeded");
    ask_yn "You should see a 9x9 rvals image, scaled from -0.5 to 9.0 in X and -0.5 to
8.5 in y.  There should be a blank vertical bar 1/2 unit wide at the right
side of the image.  The other sides of the plot should be flush.  Ok?",
      "image initial ranging plot is OK";

    eval { $w->plot(with=>'image',rvals(9,9),
		    with=>'image', xvals(9,9)+7, yvals(9,9)+4, rvals(9,9),
		    with=>'line', xvals(20)->sqrt
	       );
    };
    is($@, '', "two-image range test plot succeeded");
    ask_yn "You should see two overlapping rvals images, with lower left pixels centered
on (0,0) and (7,4), respectively, and a square root curve superimposed.
The y range should be flush with the top and bottom of the two images.  The
x range should be set by the image at left and the curve at right, running
from -0.5 to 20.0.  The curve should end at 19.0.  Ok?",
      "image/line ranging plot is OK";

    if($PDL::Bad::Status) {
	eval {
	    $w = gpwin();
	    $w->multiplot(layout=>[2,1]);
	    $a = xvals(11)**2;
	    $a->slice("(5)") .= asin(pdl(1.1));
	    $b = (xvals(11)**2)->setbadif(xvals(11)==5);
	    print "a=$a\n";
	    print "b=$b\n";
	    $w->options(xlab=>"X", ylab=>"Y");
	    $w->line($a, {title=>"Parabola with NaN at x=5"});
	    $w->line($b, {title=>"Parabola with BAD at x=5"});
	    $w->end_multi;
	};
	is($@, '', "bad value plot succeeded");
	ask_yn "The two panels should have the same plot with different titles:  Y=X**2,
with a segment missing from X=4 to X=6.  OK?",
	  "bad value plot looks OK";
    } else {
	ok(1, "Skipping bad-value test since this PDL doesn't support badvals");
	ok(1, "Skipping bad-value test since this PDL doesn't support badvals");
    }


##############################
# Mousing tests
#

    if( $ENV{DISPLAY}  and  $PDL::Graphics::Gnuplot::valid_terms->{x11} ) {
	eval { $w=gpwin('x11'); $w->image(rvals(9,9), {title=>"X11 window for mouse test"}) };
	is($@, '', "plotting to x11 window worked.");

	print STDERR "\n\nClick in the X11 window for mouse test.\n";
	eval { my $h = $w->read_mouse(); };
	is($@, '', "Mouse test read a click");

	# Try with a new window
	$w=gpwin($w->{terminal});
	eval { print $w->read_mouse(); };
	like $@, qr/no existing/,"Trying to read the mouse input on an empty window doesn't work";

    } else {
	ok(1,"Skipping x11 plot");
	ok(1,"Skipping click test for non-x11 device");
	ok(1,"Skipping mouse input test for non-x11 device");
    }
}

##############################
# Test date plotting
eval {$w=gpwin( "dumb", size=>[79,24,'ch'],output=>$testoutput );};
is($@, '', "dumb terminal still works");

# Some date stamps
my @dates = (-14552880,   # Apollo 11 launch
	  0,           # UNIX epoch
	  818410080,   # SOHO launch
	  946684799,   # The banking system did not melt down.
	  1054404000); # A happy moment in 2003
my $dates = pdl(@dates);

eval { $w->plot( {xdata=>'time'}, with=>'points', $dates->clip(0), xvals($dates) ); };
is($@, '', "time plotting didn't fail");
my $lines1 = join '', do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };

eval { $w->plot( {xr=>[0,$dates->max],xdata=>'time'}, with=>'points', $dates, xvals($dates) ); };
is($@, '', "time plotting with range didn't fail");
my $lines2 = join '', do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };

eval { $w->plot( {xr=>[$dates->at(3),$dates->at(4)], xdata=>'time'}, with=>'points', $dates, xvals($dates));};
is($@, '', "time plotting with a different range didn't fail");
my $lines3 = join '', do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };

print "lines1:\n$lines1\n\nlines2:\n$lines2\n\nlines3:\n$lines3\n\n";
SKIP: {
    skip "Skipping date ranging tests since Gnuplot itself doesn't work",2;
is($lines1, $lines2,  "Setting the time range to what it would be anyway duplicates the graph");
isnt($lines2, $lines3, "Modifying the time range modifies the graph");
}


##############################
# Check that title setting/unsetting works OK
eval { $w->reset; $w->plot({title=>"This is a plot title"},with=>'points',xvals(5));};
is($@, '', "Title plotting works, no error");

@lines = do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };

SKIP:{
    skip "Skipping title tests due to obsolete version of gnuplot (BSD uses 4.2, which fails these)",3
	if($w->{gp_version} < $PDL::Graphics::Gnuplot::gnuplot_req_v);

    like("@lines[0..3]", qr/This is a plot title/, "Plot title gets placed on plot")
      or diag explain \@lines;

    eval { $w->plot({title=>""},with=>'points',xvals(5));};
    is($@, '', "Non-title plotting works, no error");

    @lines = do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };
    if($w->{gp_version} < 5.2) {
	like($lines[1], qr/^\s*$/, "Setting empty plot title sets an empty title");
    } else {
	# Late-model gnuplots use the top lines if there is no title
	like($lines[1], qr/\-{50,70}/);
    }
}

##############################
# Check that 3D plotting of grids differs from threaded line plotting
SKIP:{
    skip "Skipping 3-D plots since gnuplot is ancient",4
	if($w->{gp_version} < $PDL::Graphics::Gnuplot::gnuplot_dep_v);

    eval { $w->plot({trid=>1,title=>""},with=>'lines',sequence(3,3)); };
    is($@, '', "3-d grid plot with single column succeeded");
    my $lines = join '', do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };

    eval { $w->plot({trid=>1,title=>"",yr=>[-1,1]},with=>'lines',cdim=>1,sequence(3,3));};
    is($@, '', "3-d threaded plot with single column succeeded");
    my $lines2 = join '', do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };

    isnt( $lines2, $lines, "the two 3-D plots differ");

    if( $w->{gp_version} < 5.0 ) {
	like $lines2, qr/\#/;
	unlike $lines, qr/\#/, "the threaded plot has traces the grid lacks";
    } else {
	# 5.0 no longer uses hashes and asterisks to distinguish the lines, so just check that the plot
	# changed.
	skip "Skipping hash/asterisk test since gnuplot is 5.0 or newer", 2;
    }
}

##############################
# Test rudimentary polar plots

eval { $w->plot({trid=>1, mapping=>'cylindrical', angles=>'degrees'},
		wi=>'points',xvals(10)*36,xvals(10)*36,xvals(10)*36); } ;
is($@, '', "cylindrical plotting in degrees was parsed OK");

eval { $w->plot({trid=>1, mapping=>'sph', angles=>'rad'},
		wi=>'points',xvals(10)*36,xvals(10)*36,xvals(10)*36); } ;
is($@, '', "spherical plotting in radians was parsed OK (abbrevs in enums too)");

undef $w;
unlink($testoutput) or warn "\$!: $!";

##############################
##############################
## Test aspects of the parsers...
$w = gpwin();

eval { $w->options(xrange=>pdl(1,2)) };
is($@, '', "xrange accepts a PDL option");
is_deeply $w->{options}{xrange}, [1, 2],
    "xrange parses a 2-PDL into a array ref";

eval { $w->options(xrange=>pdl(1,2,3)) };
isnt($@, '', "xrange rejects a PDL with more than 2 elements");

eval {$w->options(xrange=>[21]);};
is($@, '', "xrange accepts a single-element array-ref");
is_deeply $w->{options}{xrange}, [21],
    "xrange parses single list element correctly";

eval { $w->options(justify=>"0") };
is($@, '', "justify accepts quoted zero");

eval { $w->options(justify=>"-1") };
like($@, qr/positive/, "justify rejects negative numbers");
undef $@;

eval { $w->options(justify=>"1") };
is($@, '', "justify accepts positive numbers");

eval {
  $w = gpwin('dumb', output=>$testoutput);
  $w->multiplot(layout=>[1,1]);
  $w->plot(
    {
      label => [ [ 'left-justified', at=>[0,0], 'left' ] ],
      xrange => [ 0, 4 ], yrange => [ -1, 5 ]
    },
    { with => 'labels' },
    [ 0 ], [ -1 ], [ '' ]
  );
};
is($@, '', "labels with multiplot works even in Gnuplot 6.0.1");

##############################
##############################
## Test explicit and implicit plotting in 2-D and 3-D, both binary and ASCII

$w = gpwin('dumb', output=>$testoutput);

# Test ASCII plot handling
$w->options(binary=>0);

eval { $w->plot(with=>'lines',xvals(5)) };
is($@, '', "ascii plot with implicit col succeeded");

like($PDL::Graphics::Gnuplot::last_plotcmd, qr/plot +\$PGG_data_\d+ +using 0\:1 /,
   "ascii plot with implicit col uses explicit reference to column 0");

eval { $w->plot(with=>'lines',xvals(5),xvals(5)) };
is($@, '', "ascii plot with no implicit col succeeded");
like($PDL::Graphics::Gnuplot::last_plotcmd, qr/plot +\$PGG_data_\d+ +using 1\:2 /s,
   "ascii plot with no implicit cols uses columns 1 and 2");

eval { $w->plot(with=>'lines',xvals(5,5)) };
is($@, '', "ascii plot with threaded data and implicit column succeeded");
like($PDL::Graphics::Gnuplot::last_plotcmd, qr/plot +\$PGG_data_\d+ +using 0\:1 [^u]+using 0\:1 /s,
   "threaded ascii plot with one implicit col does the Right Thing");


eval { $w->plot(with=>'lines',xvals(5),{trid=>1}) };
is($@, '', "ascii 3-d plot with 2 implicit cols succeeded");
like($PDL::Graphics::Gnuplot::last_plotcmd, qr/plot +\$PGG_data_\d+ +using 0:\(\$0\*0\):1/s,
   "ascii plot with two implicit cols uses column 0 and zeroed-out column 0");

eval { $w->plot(with=>'lines',xvals(5),xvals(5),{trid=>1})};
isnt($@, '', "ascii 3-d plot with 1 implicit col fails (0 or 2 only)");

eval { $w->plot(with=>'lines',xvals(5),xvals(5),xvals(5),{trid=>1}) };
is($@, '', "ascii 3-d plot with no implicit cols succeeds");
like($PDL::Graphics::Gnuplot::last_plotcmd, qr/plot +\$PGG_data_\d+ +using 1:2:3 /s,
   "ascii 3-d plot with no implicit cols does the Right Thing");

eval { $w->plot(with=>'lines',xvals(5,5),{trid=>1}) };
is($@, '', "ascii 3-d plot with 2-D data and 2 implicit cols succeeded");
like($PDL::Graphics::Gnuplot::last_plotcmd, qr/splot +"-" binary array=\(5,5\) /s,
   "ascii plot with 2-D data and 2 implicit cols uses binary ARRAY mode");

eval { $w->plot(with=>'lines',xvals(5,5),xvals(5,5),{trid=>1}) };
isnt($@, '', "ascii 3-d plot with 2-D data and 1 implicit col fails (0 or 2 only)");

eval { $w->plot(with=>'lines',xvals(5,5),xvals(5,5),xvals(5,5),{trid=>1}) };
is($@, '', "ascii 3-d plot with 2-D data and no implicit cols succeeded");
like($PDL::Graphics::Gnuplot::last_plotcmd, qr/splot +"-" binary record=\(5,5\) /s,
   "ascii plot with 2-D data and no implicit cols uses binary RECORD mode");

eval { $w->plot(with=>'yerrorbars', (xvals(50)-25)**2, pdl(0.5),{binary=>0})  };
is($@, '', "yerrorbars plot succeeded in ASCII mode");


##############################
# Test NaN plotting in binary and ASCII
$w->restart;
$a = pdl(1,4,-1,16,25)->sqrt; # 1,2,NaN,4,5
$b = pdl(1,4,9,16,25)->sqrt;  # 1,2,3,4,5

$w->plot(with=>'lines',$a,{binary=>1});
$w->close;
@lines = do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };
isnt $lines[12], '';
like substr($lines[12],20,40), qr/^\s+$/, "NaN makes a blank in a plot";

$w->restart;
eval {$w->plot(with=>'lines',legend=>'456',$b)};
is $@, '', "can use numeric-only strings for legend"; # GH#100
$w->close;

$w->restart;
$w->plot(with=>'lines',$b,{binary=>1});
$w->close;
@lines = do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };
isnt $lines[12], '';
unlike substr($lines[12],20,40), qr/^\s+$/, "No NaN makes a nonblank in a plot";

$w->restart;
$w->plot(with=>'lines',$b,{binary=>0});
$w->close;
@lines = do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };
isnt $lines[12], '';
unlike substr($lines[12],20,40), qr/^\s+$/, "No NaN makes a nonblank in a plot even with ASCII";

$w->restart;
$w->plot(with=>'lines',$a,{binary=>0});
$w->close;
@lines = do { open my $fh, "<", $testoutput or die "$testoutput: $!"; <$fh> };
isnt $lines[12], '';
like substr($lines[12],20,40), qr/^\s+$/, "NaN makes a blank in a plot even with ASCII";

# Test plotting of PDL subclasses
@MyPackage::ISA = qw/PDL/;
$a = { PDL => xvals(5)**2 };
bless($a,'MyPackage');
eval { $w->plot( $a ); };
is $@, '', "subclass of PDL plots OK";

my @d = qw(PDL Demos);
my $m51path;
foreach my $path (@INC) {
  my $check = File::Spec->catfile( $path, @d, "m51.fits" );
  if ( -f $check ) { $m51path = $check; last; }
}
if (defined $m51path) {
  my $m51 = rfits $m51path;
  eval { $w->reset; $w->plot(with => 'fits', $m51); }; # reset of "ascii"
  is $@, '', "with => 'fits' OK";
}

# Test terminal defaulting
eval { $w=PDL::Graphics::Gnuplot::new(size=>[9,9]); undef($w);};
is $@, '', "default terminal is selected OK";

undef $w;

unlink($testoutput) or warn "\$!: $!";

##############################
# Test default output plotting

unlink qw(Plot-1.txt Plot-2.txt);
 SKIP: {
     if( -e 'Plot-1.txt' || -e 'Plot-2.txt') {
	 print STDERR "\n***********\nSkipping default-plot-output tests:  files 'Plot-1.txt' and/or 'Plot-2.txt' exist.\n***********\n";
	 skip "Plot-1.txt and/or Plot-2.txt exist, can't check default plotting", 4;
     }
     $w=gpwin('dumb');
     eval { $w->line(xvals(20)**3); };
     is( $@, '', "default-output plot succeeded" );
     ok( -e "Plot-1.txt", "Plot got made" );
     eval { $w->line(xvals(10)**4); };
     is($@, '', "default-output plot succeeded again");
     ok( -e "Plot-2.txt", "Second plot got made" );
     unlink "Plot-1.txt";
     unlink "Plot-2.txt";
}

done_testing;
