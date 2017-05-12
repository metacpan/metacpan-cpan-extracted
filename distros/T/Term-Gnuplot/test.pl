use Term::Gnuplot;
use Config;
use integer;			# To get the same results as standard one

# Allow loading newly-created executables from blib/script
$ENV{PATH} = "blib/script$Config{path_sep}$ENV{PATH}";
# print STDERR "path = $ENV{PATH}\n";

$| = 1;

my ($n, $d);
my $desc = Term::Gnuplot::_available_terms();

my $test_terms = !(@ARGV and $ARGV[0] eq 'none');

@files = @ARGV, shift @files, &test_term($ARGV[0]), exit 0
  if @ARGV and $test_terms;

if ($test_terms) {
  # list_terms();
  for $n (sort keys %Term::Gnuplot::description) {
    my $t = "\t" x (2 - int ((1 + length $n)/8));
    print " $n$t=> $Term::Gnuplot::description{$n}\n";
  }

  test_term("dumb");
  if ($Term::Gnuplot::description{pm}) {
    test_term("pm");
  } 
  if ($ENV{DISPLAY} and $Term::Gnuplot::description{x11}) {
      &test_term("x11");
  }
}
while ($test_terms) {
  $|=1;
  # list_terms();
  for $n (sort keys %Term::Gnuplot::description) {
    my $t = "\t" x (2 - int ((1 + length $n)/8));
    print " $n$t=> $Term::Gnuplot::description{$n}\n";
  }
  print "Type terminal name, 'file' to set output file(s), or ENTER to finish";
  print "\n  Or type 'pTk' to try the direct-to-Tk demo: ";
  $in = <STDIN>;
  chomp $in;
  if ($in eq 'file') {
    print "Output file name(s) for builtin and Perl tests? ";
    $file = <STDIN>;
    chomp $file;
    @files = split " ", $file;
    push @files, "perl$files[0]" if @files == 1;
    redo;
  }
  last unless $in;
  &test_term($in);
  @files = ();
}

my $ptk_canvas;
my $mw;
my $ptk;
my $ptk_waited;

sub test_term {
  my $name = shift;
  print "  $name ===> $desc->{$name}\n";
  my $comment = "";
  $comment = ' - height set to 32' if $name eq 'dumb';
  $comment = ' - window name set to "Specially named terminal"'
    if $name eq 'pm';

  print("Output file $files[0]\n"), plot_outfile_set(shift @files) if @files;
  if ($name eq 'pTk') {
    $name = 'tkcanvas';
    $ptk = 1;
    $ptk_canvas->delete('all') if $ptk_canvas;
    eval <<'EOE' unless $ptk_canvas;
      use Tk;

      $mw = MainWindow->new;
      $ptk_canvas = $mw->Canvas('-height', 400, '-width', '600','-border'=>0, '-relief' => 'raised', '-bg' => 'aliceblue')
	   ->pack('-fill', 'both', '-expand', 1);
      Term::Gnuplot::setcanvas($ptk_canvas);
      $mw->update();
      $mw->fileevent(STDIN, 'readable', sub {<STDIN>; $ptk_waited = 1});
EOE
    warn $@ if $@;
  }
  print("Switch to `$name': not OK: $out\n"), return
      unless $out = Term::Gnuplot::change_term($name);
  print "Builtin test for `$name'$comment, press ENTER\n";
  if ($ptk_canvas) {
    $ptk_waited = 0;
    $ptk_canvas->waitVariable(\$ptk_waited);
  } else {
    <STDIN>;
  }
  $mw->update() if $ptk;
  if ($name eq 'pm') {
    set_options('"Specially named terminal"');
  } elsif ($name eq 'dumb') {
    set_options(79,32);
  } elsif ($ptk) {
    set_options('tkperl_canvas');
  } else {
    set_options();		#  if $name eq 'gif' - REQUIRED to init things
  }
#  &Term::Gnuplot::init() if !$initialized{$name}++;
  &Term::Gnuplot::term_init();
#  print("Output file $files[0]\n"), plot_outfile_set(shift @files) if @files;

  &Term::Gnuplot::test_term();
  $ptk_canvas->update() if $ptk;
  print "\n$name builtin test OK, Press ENTER\n";
  if ($ptk_canvas) {
    $ptk_waited = 0;
    $ptk_canvas->waitVariable(\$ptk_waited);
  } else {
    <STDIN>;
  }


  print "Perl test for `$name'$comment [May have extra filled boxes];\n\tpress ENTER\n";
  if ($ptk_canvas) {
    $ptk_waited = 0;
    $ptk_canvas->waitVariable(\$ptk_waited);
  } else {
    <STDIN>;
  }

  use Term::Gnuplot ':ALL';

  print("Output file $files[0]\n"), 
#    plot_outfile_set(shift @files), reset() if @files;
    plot_outfile_set(shift @files) if @files;

  $ptk_canvas->delete('all') if $ptk_canvas;
#  init() unless $initialized{$name}++;
  term_init() unless $initialized{$name}++;
  {
    my($name,$description,$xmax,$ymax,$v_char,$h_char,$v_tic,$h_tic) =
      (&Term::Gnuplot::name,&Term::Gnuplot::description,&Term::Gnuplot::xmax,&Term::Gnuplot::ymax,
       &Term::Gnuplot::v_char,&Term::Gnuplot::h_char,&Term::Gnuplot::v_tic,&Term::Gnuplot::h_tic);
    print <<EOD;
Term data: 
	name '$name',
	description '$description',
	xmax $xmax,
	ymax $ymax,
	v_char $v_char,
	h_char $h_char,
	v_tic $v_tic,
	h_tic $h_tic.
EOD
  }

  my ($xsize,$ysize) = (1,1);
  my $scaling = scale($xsize, $ysize);
  my $xmax = xmax() * ($scaling ? 1 : $xsize);
  my $ymax = ymax() * ($scaling ? 1 : $ysize);
  my $pointsize = 1;			# XXXX We did not set it
  my $key_entry_height = $pointsize * v_tic() * 1.25;

  $key_entry_height = v_char() if $key_entry_height < v_char();
  my $p_width = $pointsize * v_tic();

#  graphics();
  term_start_plot();

  linewidth(1);
  # border linetype 
  linetype(LT_BLACK);
  move(0,0);
  vector($xmax-1,0);
  vector($xmax-1,$ymax-1);
  vector(0,$ymax-1);
  vector(0,0);
  justify_text(LEFT);
  put_text(h_char()*5, $ymax - v_char()*3,"Terminal Test, Perl");

  # axis linetype 
  linetype(LT_AXIS);
  move($xmax/2,0);
  vector($xmax/2,$ymax-1);
  move(0,$ymax/2);
  vector($xmax-1,$ymax/2);

  #	/* test width and height of characters */
  linetype(LT_BLACK);
  move(  $xmax/2-h_char()*10,$ymax/2+v_char()/2);
  vector($xmax/2+h_char()*10,$ymax/2+v_char()/2);
  vector($xmax/2+h_char()*10,$ymax/2-v_char()/2);
  vector($xmax/2-h_char()*10,$ymax/2-v_char()/2);
  vector($xmax/2-h_char()*10,$ymax/2+v_char()/2);
  put_text($xmax/2-h_char()*10,$ymax/2,
		"12345678901234567890");

  # test justification 
  justify_text(LEFT);
  put_text($xmax/2,$ymax/2+v_char()*6,"left justified");
  put_centered_text $xmax/2, $ymax/2+v_char()*5, "centre+d text";
  put_right_justified_text $xmax/2, $ymax/2+v_char()*4, "right justified";

  # test text angle 
  if (text_angle(TEXT_VERTICAL)) {
    put_centered_text v_char(), $ymax/2, "rotated ce+ntred text";
  } else {
    put_left_justified_text h_char()*2,$ymax/2-v_char()*2,"Can't rotate text";
  }
  justify_text(LEFT);
  text_angle(0);

  # test tic size 
  move($xmax/2+h_tic()*2,0);
  vector($xmax/2+h_tic()*2,v_tic());
  move($xmax/2,v_tic()*2);
  vector($xmax/2+h_tic(),v_tic()*2);
  put_text($xmax/2-h_char()*10,v_tic()*2+v_char()/2,"test tics");

  # test line and point types 

  pointsize($pointsize);
  my $x = $xmax - h_char()*6 - $p_width;
  my $y = $ymax - v_char();
  my $i;
  for ( $i = -2; $y > $key_entry_height; $i++ ) {
    linetype($i);
    if (justify_text(RIGHT)) {
      put_text($x,$y,$i+1);
    } else {
      put_text($x-length($i+1)*h_char(),$y,$i+1);
    }
    move($x+h_char(),$y);
    vector($x+h_char()*4,$y);
    if ( $i >= -1 ) {
      point($x+h_char()*5 + int($p_width/2),$y,$i);
    }
    $y -= $key_entry_height;
  }

  # test some arrows 
  linetype(0);
  $x = $xmax/4;
  $y = $ymax/4;
  $xl = h_tic()*5;
  $yl = v_tic()*5;
  arrow($x,$y,$x+$xl,$y,1);
  arrow($x,$y,$x+$xl/2,$y+$yl,1);
  arrow($x,$y,$x,$y+$yl,1);
  arrow($x,$y,$x-$xl/2,$y+$yl,0);
  arrow($x,$y,$x-$xl,$y,1);
  arrow($x,$y,$x-$xl,$y-$yl,1);
  arrow($x,$y,$x,$y-$yl,1);
  arrow($x,$y,$x+$xl,$y-$yl,1);

  # test fillbox
  $x = $xmax/2 + 3*h_tic();
  $y = $ymax/4;
  $xl = h_tic()*3;

  eval {
     arrow($x,$y-$yl,$x,$y,1);
     my ($dx, $dy) = (h_tic(), v_tic());
     my $xini = $x;
     linetype(1);
     # style == 1: $level is density 0..100
     for my $n (0..7) {
	{  no integer;
           color_fill_box($n/7, $x, $y, $xl, $yl);
        }
       #fillbox((($n/7*100) & 0xfff) | 1, $x, $y, $xl, $yl);
       #fillbox((((int($n*100/6)) & 0xfff)<<4) | 1, $x, $y, $xl, $yl);
       clear_box(     $xl/3+$x, $y + $yl/3,$xl/3,$yl/3);
       linetype(1);		# Bug in PM terminal - color leaks in clear_box
       $x += $xl + $dx;
     }
     # style == 1: $level is density 0..100
     $y += $yl + $dy;
     $x = $xini;
     # style == 2: $level is stipple pattern (0..6 for xterm)
     for my $n (0..7) {
       pattern_fill_box($n, $x, $y, $xl, $yl);
       clear_box(     $xl/3+$x, $y + $yl/3,$xl/3,$yl/3);
       linetype(1);		# Bug in PM terminal - color leaks in clear_box
       $x += $xl + $dx;
     }
     1;
  } or do {
     my $txt = $@;
     warn $@;
     $txt = substr($txt, 0, 18) . '...' unless length $txt < 21;
     put_text($x, $y, $txt);
  };
  linetype(0);

  # test fillbox
  $x = 3*$xmax/4;
  $y = 3*$ymax/4;
  $xl = h_tic()*5;

  eval {
     my @points = ($x, $y, $x + $xl, $y - $yl, $x + 2*$xl, $y,
		   $x + $xl, $y + $yl, $x + $xl, $y);
     my @points1 = ($x, $y, $x + $xl, $y - $yl/2, $x + 3*$xl/2, $y,
		    $x + $xl, $y + $yl/2, $x + $xl, $y);
     linetype(1);
     eval {color_fill_box(1, $x-$xl/2, $y-3*$yl/2, 3*$xl, 3*$yl)};
     linetype(0);
     arrow($x,$y-$yl,$x,$y,1);
     make_gray_palette();
     set_color 0.6;
     filled_polygon @points;
     set_color 0.4;
     filled_polygon @points1;
     1;
  } or do {
     my $txt = $@;
     warn $@;
     $txt = substr($txt, 0, 18) . '...' unless length $txt < 21;
     put_centered_text($x, $y, $txt);
  };
  linetype(0);

  Term::Gnuplot::set_mouse_feedback_rectangle(0, $xmax, 0, $ymax, 0, 100, 0, 100)
    if defined &Term::Gnuplot::set_mouse_feedback_rectangle;
#  Term::Gnuplot::enable_mousetracking() if defined &Term::Gnuplot::enable_mousetracking;
  # and back into text mode 

#  text();
  term_end_plot();
  $ptk_canvas->update() if $ptk;
  # Tk::MainLoop() if $pTk;
  print "\n$name Perl test OK, Press ENTER\n";
  if ($ptk_canvas) {
    $ptk_waited = 0;
    $ptk_canvas->waitVariable(\$ptk_waited);
  } else {
    <STDIN>;
  }
  &Term::Gnuplot::reset();
}

# Test C convenience functions:

my $c = Term::Gnuplot::term_count;
my $c1 = keys %Term::Gnuplot::description;
print "not " if $c != $c1;
print "ok # term_counts: $c, $c1\n";
print "not " if Term::Gnuplot::get_terms(-1);
print "ok # term[-1] missing\n";
print "not " unless Term::Gnuplot::get_terms(0);
print "ok # term[0] present\n";
print "not " if Term::Gnuplot::get_terms($c);
print "ok # term[$c] missing\n";
print "not " unless Term::Gnuplot::get_terms($c-1);
print "ok # term[$c-1] present\n";

my $tt = Term::Gnuplot::_available_terms;
my $c2 = keys %$tt;
print "not " if $c != $c2 or $c != $c1;
print "ok # term_counts: $c, $c1, $c2\n";

my @k = grep !$Term::Gnuplot::description{$_}, keys %$tt;
print "not " if @k;
print "ok # mismatched terms: @k\n";

@k = grep !$$tt{$_}, keys %Term::Gnuplot::description;
print "not " if @k;
print "ok # mismatched terms: @k\n";

@k = grep $$tt{$_} ne $Term::Gnuplot::description{$_}, keys %Term::Gnuplot::description;
print "not " if @k;
print "ok # mismatched descr: @k\n";

