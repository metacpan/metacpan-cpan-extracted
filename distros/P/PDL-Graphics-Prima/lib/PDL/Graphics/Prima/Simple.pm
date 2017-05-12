package PDL::Graphics::Prima::Simple;
use strict;
use warnings;
use Carp 'croak';

our $VERSION = 0.17;   # update with update-version.pl

use PDL::Graphics::Prima;

=head1 NAME

PDL::Graphics::Prima::Simple - a very simple plotting interface for
PDL::Graphics::Prima

=head1 SYNOPSIS

 use PDL::Graphics::Prima::Simple;
 use PDL;
 
 
 # --( Super simple line and symbol plots )--
 
 # Generate some data - a sine curve
 my $x = sequence(100) / 20;
 my $y = sin($x);
 
 # Draw x/y pairs. Default x-value are sequential:
 line_plot($y);        line_plot($x, $y);
 circle_plot($y);      circle_plot($x, $y);
 triangle_plot($y);    triangle_plot($x, $y);
 square_plot($y);      square_plot($x, $y);
 diamond_plot($y);     diamond_plot($x, $y);
 X_plot($y);           X_plot($x, $y);
 cross_plot($y);       cross_plot($x, $y);
 asterisk_plot($y);    asterisk_plot($x, $y);
 
 # Sketch the sine function for x initially from 0 to 10:
 func_plot(0 => 10, \&PDL::sin);
 
 
 # --( Super simple histogram )--
 
 # Plot a distribution
 hist_plot($distribution);
 # Tweak the binning
 hist_plot($distribution, bt::Linear(normalize => 0));
 
 
 # --( Super simple matrix plots )--
 
 # Generate some data - a wavy pattern
 my $image = sin(sequence(100)/10)
             + sin(sequence(100)/20)->transpose;
 
 # Generate a grayscale image:
 matrix_plot($image);  # smallest is white
 imag_plot($image);    # smallest is black
 
 # Set the x and y coordinates for the image boundaries
 #            left, right,  bottom, top
 matrix_plot([ 0,     1  ], [ 0,     2 ],  $image);
 imag_plot(  [ 0,     1  ], [ 0,     2 ],  $image);
 
 
 # --( More complex plots )--
 
 # Use the more general 'plot' function for
 # multiple DataSets and more plotting features:
 my $colors = pal::Rainbow()->apply($x);
 plot(
     -lines         => ds::Pair($x, $y
         , plotType => ppair::Lines
     ),
     -color_squares => ds::Pair($x, $y + 1
         , colors   => $colors,
         , plotType => ppair::Squares(filled => 1)
     ),
     
     x => { label   => 'Time' },
     y => { label   => 'Sine' },
 );
 
 
 # --( Managing window interaction )--
 
 # In scripts and older Term::ReadLine, if you press
 # the letter 'q' when viewing a plot, you can
 # re-invoke interaction with:
 twiddle;
 
 # query auto-twiddling
 my $is_auto_twiddline = auto_twiddle;
 # Turn auto-twiddling on or off
 auto_twiddle(1);
 auto_twiddle(0);

=head1 DESCRIPTION

One of Perl's mottos is to "make easy things easy, and hard things possible."
The bulk of the modules provided by the
L<PDL::Graphics::Prima|PDL::Graphics::Prima/> distribution
focus on the latter half, making hard but very powerful things possible.
This module tackles the other half: making easy things easy. This module
provides a number of simple functions for quick data plotting so that you can
easily get a first look at your data. You can think of this as providing a
function-based interface to plotting, in contrast to the GUI/OO interface of
the rest of L<PDL::Graphics::Prima|PDL::Graphics::Prima/DESCRIPTION>. Or you
can look at this as providing a handy collection of plot (and window)
constructors for the standard use cases. Either perspective is basically correct.

In addition to making easy plots easy, this module and its documentation are
meant to serve as an introduction to L<PDL::Graphics::Prima|PDL::Graphics::Prima/>.
If you are new to the libarary, this is where you should start.

This module is built on L<the Perl Data Language|PDL> and
L<the Prima GUI toolkit|Prima>. You do not need to know much about
L<Prima|Prima> to use this tutorial, but you should know
L<the basics of PDL|PDL::QuickStart>.

When you use this library, you get a handful of functions for quick data
plotting that include

=over

=item lines

L<line_plot|/line_plot> takes one or two L<piddle|PDL::Core/pdl>s, one for y and optionally one for
x, and makes a L<line plot|PDL::Graphics::Prima::PlotType/ppair::Lines> with
them; if you don't give an x L<piddle|PDL::Core/pdl>, it uses
L<sequential integers starting from zero|PDL::Basic/xvals>. 

=item symbols

Various symbol plots, like L<cross_plot|/cross_plot> and
L<diamond_plot|/diamond_plot>, take one or two L<piddle|PDL::Core/pdl>s, one
for y and optionally one for
x, and and plots the L<symbol|PDL::Graphics::Prima::PlotType/ppair::Symbols>
at the given points; if you don't give an x L<piddle|PDL::Core/pdl>, it uses
L<sequential integers starting from zero|PDL::Basic/xvals>. 

=item functions

L<func_plot|/func_plot> takes an I<initial> plot min/max and a L<function reference|perlsub> and
makes a L<line plot|PDL::Graphics::Prima::PlotType/ppair::Lines> of the
L<function|perlsub>; it can optionally take the number of points to evaluate
on each drawing operation; see L<PDL::Graphics::Prima::DataSet/ds::Func>

=item histograms

L<hist_plot|/hist_plot> takes a L<piddle|PDL::Core/pdl> of data to be plotted and an optional
L<bin type|PDL::Graphics::Prima::DataSet/Sets> and plots a
L<histogram|PDL::Graphics::Prima::PlotType/ppair::Histogram>. If no bin
type is supplied, L<linear binning|PDL::Graphics::Prima::DataSet/bt::Linear>
is used.

=item images

Both L<matrix_plot|/matrix_plot> and L<imag_plot|/imag_plot> take one or
three arguments, the first two of which specify the x-bounds and the
y-bounds, the third (or only) of which is the matrix to plot

=item plot (...)

L<plot|/"PLOT FUNCTION"> is a much more powerful routine that takes the same
arguments you would pass to
the constructor of a L<plot widget|PDL::Graphics::Prima/>, and packs the
resulting plot widget in a L<stand-alone window|Prima::Window>.

=back

And with that, let's look at how to I<use> these to view data!

=head1 TUTORIAL

To begin, let's assume you have some x/y data that you want to plot with lines
connecting them. My canonical example is a sine wave. Here's a complete script
to get us started:

 use PDL;
 use PDL::Graphics::Prima::Simple;
 my $x = sequence(100)/10;
 line_plot($x, $x->sin);
 print "All done!\n";

The C<use PDL> line L<pulls in all the machinery for the Perl Data Language|PDL>
and, more importantly, imports the L<C<sequence>|PDL::Basic/sequence> function
(among many others) into the current package. On the third line we use that
function to generate a bunch of x-data with a spacing of 1/10. In the last
line we plot the sine of that sequence of points.

When you run the above example script, it will block at the C<line_plot>
command and display a L<Prima window|Prima::Window> with your plot. (On the
other hand, if you are in the L<pdl shell|perldl>, the plot will be displayed
but it will not block your shell if you have a recent version of
L<Term::ReadLine>.) We will return to the blocking behavior, and how to call
this in a non-blocking fashion, in a little bit.

=head2 Interactive Features

For now, turn your attention to the plot. This is a highly interactive
plot, as are all plots made with
L<PDL::Graphics::Prima|PDL::Graphics::Prima/>. In particular,
your plot responds to the following user interactions:

=over

=item right-click zooming

Clicking and dragging your right mouse button will zoom into a specific region.
You will see a zoom rectangle on the plot until you release the mouse, at which
point the plot will be zoomed-in to the region that you selected.

=item scroll-wheel zooming

You can zoom-in and zoom-out using your scroll wheel. The zooming is designed to
keep the data under the mouse at the same location as you zoom in and out.
(This is not a 100% guarantee, but for most uses it works about right.)

=item dragging/panning

Once you have zoomed into a region, you can examine nearby data by clicking and
dragging with your left mouse button, much like an interactive map.

=item context menu

Right-clicking on the plot will bring up a L<context menu|Prima::Menu> with
options including restoring auto-scaling, L<copying the current plot image to
your clipboard|PDL::Graphics::Prima/copy_to_clipboard>* (to paste directly
into, say, Microsoft's PowerPoint or LibreOffice's Impress),
and saving the current plot image to a
L<postscript|PDL::Graphics::Prima/save_to_postscript> or
L<raster|PDL::Graphics::Prima/save_to_file> file. Postscript
output is L<always|Prima::PS::Drawable> L<supported|Prima::PS::Printer>, but
the supported raster output file formats depend on the L<image libraries and
codecs that Prima was able to build against|Prima::image-load>, so are system-
and machine-dependent. For additional information on raster images, see
L<Prima::Image>.

* For reasons not clear to me, copying the plot to the clipboard does not
seem to work on Mac and appear to be due to limitations with the X-window
bindings.

=item resizable

When packed into a resizable window (as is the case in this example), the plot
can be resized and it will be updated and redrawn smoothly.

=back

The library lets you
L<specify the|PDL::Graphics::Prima::Axis/min, max>
L<x- and y-bounds of the plot|PDL::Graphics::Prima::Axis/minmax>, but if you do
not specify bounds, the axis bounds will be calculated to tightly fit the data.
In fact, the library is designed to automatically choose axis boundaries that fit your
data and symbols exactly. (And if you wanted a bit of padding included in that
auto-fitting... well... it's on my todo list. :-)

=head2 Soapbox

Having played around with the plot widget, you probably want to know how to
modify it programatically, by adding a L<title|PDL::Graphics::Prima/title> or
L<axis labels|PDL::Graphics::Prima::Axis/label>, perhaps. "What sort of
options," you ask, "does L<line_plot|/line_plot> accept for me to specify
these things?" Well, you can't specify those in your call to
L<line_plot|/line_plot>. You either add them to the object after
L<line_plot|/line_plot> builds something for you, or you use the more
powerful but verbose L<plot function|/"PLOT FUNCTION">.

"But WHY?" you ask. "WHY can't I just specify a plot title in
L<line_plot|/line_plot> and be done with it?" The reason is simple. The
underlying library is built on a very clean and well-thought-out object and
I would rather not waste my time creating or your time learning some
intermediate API. A means for specifying the plot title in
L<line_plot|/line_plot> is the first step down the road of confused mental
models. So, it's really in your best interst. Honest. :-)

"But WHY?" you ask again. OK, OK, I'll tell you how to essentially get what
you want.

=head2 Adding axis labels and titles via methods

First, you can use the C<line_plot> command to build a
L<plot object|PDL::Graphics::Prima/> and return them to you I<without
blocking your script.> This will allow you to modify the properties of the 
L<plot object|PDL::Graphics::Prima/> before it gets displayed. For example, I
can L<add a plot title|PDL::Graphics::Prima/title> and
L<specifically choose when to view the plot|Prima::Window/execute> like so:

 use PDL;
 use PDL::Graphics::Prima::Simple;
 
 # Non-blocking
 auto_twiddle(0);
 
 # Build the plot
 my $x = sequence(100)/10;
 my $plot = line_plot($x, $x->sin);
 
 # Add a title
 $plot->title('The sine wave');
 
 # Display the plot
 twiddle();

You next may ask how you modify the
L<axis properties|PDL::Graphics::Prima::Axis/>, such as
L<setting the bounds|PDL::Graphics::Prima::Axis/min, max>
or L<giving them labels|PDL::Graphics::Prima::Axis/label>. The
L<axes|PDL::Graphics::Prima::Axis/> are sub-objects of the
L<plot|PDL::Graphics::Prima/>, accessed with
L<like-named accessors|PDL::Graphics::Prima/x, y>: $plot->x. The
properties of the axes that you can modify include the
L<min|PDL::Graphics::Prima::Axis/min, max>,
L<max|PDL::Graphics::Prima::Axis/min, max>,
L<scaling type|PDL::Graphics::Prima::Axis/scaling>, and
L<axis label|PDL::Graphics::Prima::Axis/label>, and are discussed
in greater detail
L<under their own documentation|PDL::Graphics::Prima::Axis/>.
Let's see how to set the
L<x- and y-axis|PDL::Graphics::Prima/x, y>
L<labels|PDL::Graphics::Prima::Axis/label>:

 use PDL;
 use PDL::Graphics::Prima::Simple;
 
 # Build the plot
 auto_twiddle(0);
 my $x = sequence(100)/10;
 my $plot = line_plot($x, $x->sin);
 
 # Add a title and axis labels
 $plot->title('The Harmonic Oscillator');
 $plot->x->label('time (s)');
 $plot->y->label('displacement (cm)');
 
 # Display the plot
 twiddle();

=head2 Working with plot objects in the PDL shell

NOTE: The current state of readline integration, and its work-around, are
in a state of flux. These docs are not entirely accurate. But they're
close enough. Expect this to get fixed soon.

NOTE: L<Term::ReadLine::Perl> is a pure-perl implementation of L<Term::ReadLine::Gnu>
and it is very nice. However, it does not play nicely with the Prima readline
integration for reasons I do not yet fully understand. In particular, the
displayed text and cursor position are always displayed one step "behind" what
you last indicated with the navigation keys (but they are always up-to-date when
you type normal letters). If you have any ideas for how to remedy this, please
let me know! Thanks!

You can do the same sorts of manipulations from the
console and see the updates as soon as you press enter. The equivalent
commands as the ones shown above are:

 pdl> use PDL::Graphics::Prima::Simple
 pdl> auto_twiddle(0)
 pdl> $x = sequence(100)/10
 # After the next commant, the line plot window will pop up
 pdl> $plot = line_plot($x, $x->sin)
 pdl> $plot->title('The Harmonic Oscillator')
 pdl> $plot->x->label('time (s)')
 pdl> $plot->y->label('displacement (cm)')

Each method call to the plot command will cause the plot to get updated with the
new element or feature.

=head2 Axis minima and maxima

If you want to set the axis bounds, you can use the
L<min|PDL::Graphics::Prima::Axis/min, max>,
L<max|PDL::Graphics::Prima::Axis/min, max> and
L<minmax|PDL::Graphics::Prima::Axis/minmax> functions. For example,
continuing from the PDL shell, this sets the x-minimum to zero:

 pdl> $plot->x->min(0)

If you drag the plot around with your mouse and want to see the current
value of the min, you could say:

 pdl> p $plot->x->min

This will print two numbers, actually, the second being a boolean flag indicating
whether or not autoscaling is on. To just get the minimum value, call the C<min>
method in scalar context:

 pdl> p scalar($plot->x->min)

If you want to re-enable autoscaling, you pass in a special value for the
min or max (or both) denoted by the constant
L<C<lm::Auto>|PDL::Graphics::Prima::Limits/lm::Auto> as in

 # Set the x-axis to autoscaling
 pdl> $plot->x->minmax(lm::Auto, lm::Auto);
 # Set the y-minimum to autoscaling
 pdl> $plot->y->min(lm::Auto);

=head2 Histograms and images

I've only spoken so far about connecting x/y data with lines, but there are
other ways to visualize x/y data, and even other forms of data you may wish
to represent. For example, if you want to visualize a distribution of data,
you would want to use a histogram:

 use PDL;
 use PDL::Graphics::Prima::Simple;
 
 # Generate 100 samples with mean 0 and standard deviation 1
 my $distribution = grandom(100);
 hist_plot($distribution);

Or, you may have an image of data that you want to view.

 use PDL;
 use PDL::Graphics::Prima::Simple;
 
 # Generate 100 samples with mean 0 and standard deviation 1
 my $image = rvals(100, 100)
 matrix_plot($image);

And you won't be surprised to learn there are many other ways to display x/y
data, as well. But let's keep moving.

=head2 Adding DataSets

What if you wanted to plot additional data along with the current data? You
do this by creating a new L<DataSet|PDL::Graphics::Prima::DataSet/>. Let's start
by adding a L<DataSet|PDL::Graphics::Prima::DataSet/> with the cosine of a
slightly different x-range:

 use PDL;
 use PDL::Graphics::Prima::Simple;
 
 # Build the plot
 my $x = sequence(100)/10;
 my ($window, $plot) = line_plot($x, $x->sin);
 
 # Add a new dataset
 my $x2 = sequence(100)/10 + 1;
 $plot->dataSets{'cosine'} = ds::Pair($x2, $x2->cos);
 
 # Display the plot
 $window->execute;

The important line in this example is the part that includes
L<C<ds::Pair>|PDL::Graphics::Prima::DataSet/ds::Pair>. Like 
L<C<lm::Auto>|PDL::Graphics::Prima::Limits/lm::Auto>,
L<C<ds::Pair>|PDL::Graphics::Prima::DataSet/ds::Pair> is a function that
uses a short prefix so that it's fast and easy to type. This is a L<common
idiom in the Prima toolkit|Prima::Const/> (though in the toolkit it is used
exclusively for specifying useful constants). 
L<C<ds::Pair>|PDL::Graphics::Prima::DataSet/ds::Pair> is just a short-hand
for a constructor with an enormous name:

 # Short form
 my $ds = ds::Pair($x, $y);
 # Long form
 my $ds = PDL::Graphics::Prima::DataSet::Pair->new(x => $x, y => $y);

If you actually run that example, you will notice that the sine cureve is
plotted as a line, just as before, but the cosine curve is plotted with a
collection of unconnected diamonds. If you want to plot the cosine curve
with a line, you need to specify the line plot type:

 ...
 # Add a new dataset
 $plot->dataSets{'cosine'} = ds::Pair($x, $x->cos,
     plotType => ppair::Lines
 );
 ...

Perl is supposed to Do What I Mean, and you could argue that this is a case
of the plotting library I<not> doing what you mean: the cosine curve "should"
be plotted with L<lines|PDL::Graphics::Prima::PlotType/ppair::Lines>, because
that's how the sine curve was plotted. However, I believe that such behavior
violates the Principle of Least Surprise. The default plot type for pairwise
data is L<diamonds|PDL::Graphics::Prima::PlotType/ppair::Diamonds>, so if you
didn't specify a plot type, you actually meant to plot diamonds.

That brings us to the important distinction between a
L<DataSet|PDL::Graphics::Prima::DataSet/> and a
L<PlotType|PDL::Graphics::Prima::PlotType/>. A 
L<DataSet|PDL::Graphics::Prima::DataSet/> contains the x/y data, or the
distribution, or the image matrix that you want shown, along with one or
more means of visualizing that data. The means for visualizing that data are
what are called L<PlotType|PDL::Graphics::Prima::PlotType/>s, and different
L<DataSet|PDL::Graphics::Prima::DataSet/>s use distinct
L<PlotType|PDL::Graphics::Prima::PlotType/>s.

=head2 Adding axis labels and titles at construction

Although interacting with the plot object after creation is fun, it is also
nice to be able to specify all of these settings when the plot is initially
created. I have already explained how limited the super-simple interface is,
and L<why I chose to restrict it to be so limited|/Soapbox>. In light of that,
I now show you how to specify all of these properties and more with a single
C<plot> command.

Let's begin by examining the L<line_plot|/line_plot> command. The documentation
below states that the function call with args C<($x, $y)> is equivalent to
this line:

 plot(-data => ds::Pair($x, $y, plotType => ppair::Lines));

Let's expand that into a full example and include the title, x-label, and
y-label:

 use PDL;
 use PDL::Graphics::Prima::Simple;
 
 # Build the plot
 my $x = sequence(100)/10;
 plot(
     # Create the DataSet with the Lines pairwise plotType
     -data => ds::Pair($x, $x->sin,
         plotType => ppair::Lines
     ),
     
     # Set the title and axis labels
     title => 'The Harmonic Oscillator',
     x     => { label => 'time (s)' },
     y     => { label => 'displacement (cm)' },
 );

Notice that all arguments to L<plot|/"PLOT FUNCTION"> are key/value pairs.
There is a clean, heierarchical structure to the function call, and it is
clear simply by examining the punctuation which settings go with which piece.
For example, the L<ppair::Lines|PDL::Graphics::Prima::PlotType/ppair::Lines>
argument clearly belongs to the L<ds::Pair>. In this case, we use data
structures that Perl provides to help convey the structure of the plot we
are trying to create.

=head2 Blocking behavior

Precisely what happens when you call these functions depends on your
environment. These functions always create a stand-alone window with the plot,
but they may or may not pause your script or shell while you interact with
the plot. In regular Perl scripts, the code will block at these function
calls until you close the window or press 'q' in one of the plot windows. For
some folks, when using the PDL shell the functions return immediately,
letting them peform more calculations or create new plots while keeping other
plot windows open. For other folks, it's possible to go back and forth
between an active plot and an inactive PDL shell, or an active shell and an
inactive plot. From the shell, the C<twiddle> function makes the plot active;
from the plot, pressing 'q' returns focus to the shell.

The main drawback of using the Simple interface instead of the full-blown
widget interface is that it differs from the normal Prima GUI application
interface. I hope that this makes it easier for you to get started with this
plotting library, but I hope that you also take the time to learn how to
write Prima applications, with the Plot widget as just one component for
user interaction. If you need any substantial amount of user interaction or
real-time behavior, I suggest you work with the full Prima toolkit.

You may find yourself working on a script and wanting to create multiple plot
windows at once, without blocking until all of them are ready. You do this by
explicitly turning off autotwiddling. Specifically, you would write something
like this:

 my $was_auto_twiddling = auto_twiddle;
 auto_twiddle(0);
 
 # ... plotting operations ...
 
 # All done; restore previous autotwiddling
 # state and let the use interact:
 auto_twiddle($was_auto_twiddling);
 twiddle();

Although you can plot multiple L<DataSet|PDL::Graphics::Prima::DataSet/>s in the
same plot window, and you can simultaneously build multiple plot windows, a
limitation of this Simple interface is that you cannot create multiple
independent plots in the same window. This is achieved using the full GUI
toolkit by creating two plot widgets packed into a larger container widget. A
tutorial for this sort of thing is in the works but hasn't made it into the
distribution yet. Stay tuned!

Having covered that introductory material, let's cover things a little more
systematically.

=head1 SIMPLEST FUNCTIONS

These functions are bare-bones means for visualizing your data that are no
more than simple wrappers around the more powerful L<plot|/"PLOT FUNCTION">
function. If you just want to have a quick look at your data, you should start
with these. These functions can return the plot widget itself, allowing you
to modify it, but see the L<plot|/"PLOT FUNCTION"> if want more control
over your plot, such as plotting multiple data sets, using variable or
advanced symbols, using multiple plot types, controlling the axis scaling,
using colors, or setting the title or axis labels.

In all of these plots, bad values in x and y are simply omitted.

=over

=item line_plot ([$x], $y)

The C<line_plot> function takes either one or two arguments. In the one-argument
form, the argument is a piddle with your y data. In the two argument form the
arguments are a piddle with your x data and a piddle with your y data. The
function plots them by drawing black lines on a white background from one point
to the next. Usually C<$x> and C<$y> will have the same dimensions, but you can
use any data that are PDL-thread compatible. For example, here's a way to
compare three sets of data that have the exact same x-values:

 my $x = sequence(100)/10;
 my $y = sequence(3)->transpose + sin($x);
 
 # Add mild linear trends to the first and second:
 use PDL::NiceSlice;
 $y(:, 0) += $x/5;
 $y(:, 1) -= $x/6;
 
 line_plot($x, $y);

The x-values do not need to be sorted. For example, this plots a sine wave sine
wave oscillating horizontally:

 my $y = sequence(100)/10;
 my $x = sin($y);
 line_plot($x, $y);

For the truly lazy, you can simply supply the y-values:

 my $y = sin(sequence(100)/10);
 line_plot($y);

Bad values in your data, if they exist, will simply be skipped, inserting a
gap into the line.

For the two-argument form, to generate the same plot using the
L<plot|/"PLOT FUNCTION"> command, you would type this:

 plot(-data => ds::Pair($x, $y, plotType => ppair::Lines));

For the one-argument form, you would type this:

 plot(-data => ds::Pair($y->xvals, $y, plotType => ppair::Lines));

=cut

sub _get_pairwise_data {
	# If one arg, and it's a piddle, return a sequence and that piddle as x/y
	if (@_ == 1 and eval { $_[0]->isa('PDL') } ) {
		return (PDL->sequence($_[0]->dim(0)), $_[0]);
	}
	# If two args, and both are piddles, return them as x/y
	elsif (@_ == 2 and eval{$_[0]->isa('PDL') and $_[1]->isa('PDL')} ) {
		return @_;
	}
	
	# Neither of the above conditions applied: determine the function name, croak
	my $function_name = (caller(1))[3];
	$function_name =~ s/.*:://;
	croak("$function_name expects either one piddle (y-data) or two piddles (x- and y-data)");
}

sub line_plot {
	@_ = (-data => ds::Pair(_get_pairwise_data(@_), plotType => ppair::Lines));
	goto &plot;
}

=item circle_plot ([$x], $y)

Plots filled circles at (x, y). (See L<line_plot|/line_plot> for a more detailed description.)
Equivalent L<plot|/"PLOT FUNCTION"> commands for the two-argument forms include:

 plot(-data => ds::Pair($x, $y, plotType => ppair::Blobs));
 plot(-data => ds::Pair(
     $x,
     $y,
     plotType => ppair::Symbol(
         filled => 'yes',
         N_points => 0,
     ),
 ));

=cut

sub circle_plot {
	@_ = (-data => ds::Pair(_get_pairwise_data(@_), plotType => ppair::Blobs));
	goto &plot;
}

=item triangle_plot ([$x], $y)

Plots filled upright triangles at (x, y). (See L<line_plot|/line_plot> for a more detailed
description.) Equivalent L<plot|/"PLOT FUNCTION"> commands for the two-argument
form include:

 plot(-data => ds::Pair(
     $x,
     $y,
     plotType => ppair::Triangles(filled => 1)
 ));
 plot(-data => ds::Pair(
     $x,
     $y,
     plotType => ppair::Symbol(
         filled => 'yes',
         N_points => 3,
         orientation => 'up',
     ),
 ));

=cut

sub triangle_plot {
	@_ = (-data => ds::Pair(_get_pairwise_data(@_)
		, plotType => ppair::Triangles(filled => 1)));
	goto &plot;
}

=item square_plot ([$x], $y)

Plots filled squares at (x, y). (See L<line_plot|/line_plot> for a more detailed description.)
Equivalent L<plot|/"PLOT FUNCTION"> commands for the two-argument form include:

 plot(-data => ds::Pair(
     $x,
     $y,
     plotType => ppair::Squares(filled => 1)
 ));
 plot(-data => ds::Pair(
     $x,
     $y,
     plotType => ppair::Symbol(
         filled => 'yes',
         N_points => 4,
         orientation => 45,
     ),
 ));

=cut

sub square_plot {
	@_ = (-data => ds::Pair(_get_pairwise_data(@_)
		, plotType => ppair::Squares(filled => 1)));
	goto &plot;
}

=item diamond_plot ([$x], $y)

Plots filled diamonds at (x, y). (See L<line_plot|/line_plot> for a more detailed description.)
Equivalent L<plot|/"PLOT FUNCTION"> commands for the two-argument form include:

 plot(-data => ds::Pair($x, $y));
 plot(-data => ds::Pair(
     $x,
     $y,
     plotType => ppair::Diamonds(filled => 1)
 ));
 plot(-data => ds::Pair(
     $x,
     $y,
     plotType => ppair::Symbol(
         filled => 'yes',
         N_points => 4,
     ),
 ));

=cut

sub diamond_plot {
	@_ = (-data => ds::Pair(_get_pairwise_data(@_)));
	goto &plot;
}

=item cross_plot ([$x], $y)

Plots crosses (i.e. plus symbols) at (x, y). (See L<line_plot|/line_plot> for a more detailed
description.) Equivalent L<plot|/"PLOT FUNCTION"> commands for the two-argument
form include:

 plot(-data => ds::Pair($x, $y, plotType => ppair::Crosses));
 plot(-data => ds::Pair(
     $x,
     $y,
     plotType => ppair::Symbol(
         N_points => 4,
         skip => 0,
     ),
 ));

=cut

sub cross_plot {
	@_ = (-data => ds::Pair(_get_pairwise_data(@_), plotType => ppair::Crosses));
	goto &plot;
}

=item X_plot ([$x], $y)

Plots X symbols at (x, y). (See L<line_plot|/line_plot> for a more detailed description.)
Equivalent L<plot|/"PLOT FUNCTION"> commands for the two-argument form include:

 plot(-data => ds::Pair($x, $y, plotType => ppair::Xs));
 plot(-data => ds::Pair(
     $x,
     $y,
     plotType => ppair::Symbol(
         N_points => 4,
         skip => 0,
         orientation => 45,
     ),
 ));

=cut

sub X_plot {
	@_ = (-data => ds::Pair(_get_pairwise_data(@_), plotType => ppair::Xs));
	goto &plot;
}

=item asterisk_plot ([$x], $y)

Plots five-pointed asterisks at (x, y). (See L<line_plot|/line_plot> for a more detailed
description.) Equivalent L<plot|/"PLOT FUNCTION"> commands for the two-argument
form include:

 plot(-data => ds::Pair(
     $x,
     $y,
     plotType => ppair::Asterisks(N_points => 5)
 ));
 plot(-data => ds::Pair(
     $x,
     $y,
     plotType => ppair::Symbol(
         N_points => 5,
         skip => 0,
         orientation => 'up',
     ),
 ));

=cut

sub asterisk_plot {
	@_ = (-data => ds::Pair(_get_pairwise_data(@_)
		, plotType => ppair::Asterisks(N_points => 5)));
	goto &plot;
}


=item func_plot ($x_min, $x_max, $func_ref, [$N_points])

The C<func_plot> function takes three or four arguments and plots a function.
The first two arguments are the initial x-bounds (min and max); the third
argument is the function that you want to plot; the optional fourth argument is
the number of points that you want to use in generating the plot. The resulting
figure will have a black line drawn against a white background.

The function itself will be called whenever the plot needs to be redrawn. It
will be passed a single argument: a piddle with sequential x-points at which
the function should be evaluated. The function should return a piddle of
y-points to be plotted. Here are some examples:

 # Plot PDL's exponential function:
 func_plot (1, 5, \&PDL::exp);
 # this time with higher resolution:
 func_plot (1, 5, \&PDL::exp, 1000);
 
 # Plot a rescaled tangent function:
 func_plot (1, 5, sub {
     my $xs = shift;
     return 5 * ($xs / 4)->tan
 });
 # or equivalently, if you "use PDL":
 func_plot (1, 5, sub {
     my $xs = shift;
     return 5 * tan($xs / 4);
 });

Your function can return bad values, in which case they will not be drawn. For
example, here is a function that plots a decaying exponential, but only for
values of x greater than or equal to zero. It starts with an initial view of
x running from 0 to 4:

 func_plot (0, 4, sub {
     my $xs = shift;
     my $ys = exp(-$xs);
     return $ys->setbadif($xs < 0);
 });

The return value must have thread-compatible dimensions, but that means that they
do not need to be identical to the input x. For example, a scalar is
thread-compatible with a vector, so the following will create a line at a
y-value of 1:

 func_plot (0, 4, sub { 1 });

Or, you can return a piddle with more dimensions than the input:

 func_plot (0, 4, sub {
     my $xs = shift;
     my $first_ys = sin($xs);
     my $second_ys = cos($xs) + 3;
     return $first_ys->cat($second_ys);
});


If you do not specify the number of points to draw, the equivalent L<plot|/"PLOT FUNCTION">
command is this:

 plot(
     -data => ds::Func($func_ref),
     x => { min => $xmin, max => $xmax },
 );

If you do specify the number of points to draw, the equivalent L<plot|/"PLOT FUNCTION"> command
is this:

 plot(
     -data => ds::Func($func_ref, N_points => $N_points),
     x => { min => $xmin, max => $xmax },
 );

=cut

sub func_plot {
	croak("func_plot expects three or four arguments: the x min and max, the function reference,\n"
		. "   and, optionally, the number of points to plot")
		unless @_ == 3 or @_ == 4;
	my ($xmin, $xmax, $func_ref, $N_points) = @_;
	@_ = (
		-data => ds::Func($func_ref, ($N_points ? (N_points => $N_points) : ())),
		x => {
			min => $xmin,
			max => $xmax,
		},
	);
	goto &plot;
}

=item hist_plot ($distribution, [$bin_type])

The C<hist_plot> function takes a distribution of data that you want to
visualize and an optional binning type. This is a fairly simple wrapper
around the L<linear binning type|PDL::Graphics::Prima::DataSet/bt::Linear>
for the L<Distribution DataSet|PDL::Graphics::Prima::DataSet/Distribution>
using the
L<histogram pairwise plot type|PDL::Graphics::Prima::PlotType/Histogram>.
It plots the histogram as black-outlined rectangles against a white
background.

The equivalent L<plot|/"PLOT FUNCTION"> commands is:

 plot(-data => ds::Dist($distribution));

A lot of defaults go into that, so it might be useful to see some of those
expanded a bit:

 plot(-data =>
     ds::Dist($distribution,
         plotType => ppair::Histogram,
         binning => bt::Linear
     )
 );

You could tweak the binning, for example by using a
L<strict logarithmic binning|PDL::Graphics::Prima::DataSet/bt::StrictLog>,
which throws an exception if your distribution includes negative data:

 hist_plot($distribution, bt::StrictLog);

or you could specify that you want 15 bins:

 hist_plot($distribution, bt::Linear(nbins => 15));

There is quite a bit more to explore here, and it will be covered below.

=cut

sub hist_plot {
	my ($piddle, $subref) = @_;
	croak("hist_plot expects a piddle as the first argument")
		unless eval{$piddle->isa('PDL')};
	my @bin_args;
	if (defined $subref) {
		croak("hist_plot expects a optional bin type or subref")
			if ref($subref) ne ref(sub{});
		@bin_args = (binning => $subref);
	}
	@_ = (-data => ds::Dist($piddle, @bin_args));
	goto &plot;
}

=item matrix_plot ([$x_edges, $y_edges,] $matrix)

The C<matrix_plot> function plots a grayscale rendering of a matrix with
the largest values closest to black, the smallest values closest to white.
(For the opposite color sense, see L<imag_plot|/imag_plot>.) This function
takes either one or three arguments. The first designates the x min and max
of the plot; the second designates the y min and max of the plot, and the
third (or only) specifies a matrix that you want to have
plotted in grayscale. The x-edges and y-edges arguments should be
two-element array references, such as:

 matrix_plot ([0 => 5], [1 => 10], $matrix);

Bad values, if your matrix has any, are skipped. This means that you will have
a white spot in its place (since the background is white), which is not
great. Future versions may use a different color to specify bad values.

Not specifying edges looks like this:

 matrix_plot ($matrix);

and its equivalent L<plot|/"PLOT FUNCTION"> commands are:

 plot(-image => ds::Grid(
     $matrix,
     x_bounds => [0, 1],
     y_bounds => [0, 1],
 ));
 plot(-image => ds::Grid(
     $matrix,
     x_bounds => [0, 1],
     y_bounds => [0, 1],
     plotType => pgrid::Matrix,
 ));

Specifying edges looks like this:

 matrix_plot ([0 => 5], [1 => 10], $matrix);

and the quivalent is:

 plot(-image => ds::Grid(
     $matrix,
     x_bounds => [0, 5],
     y_bounds => [1, 10],
     plotType => pgrid::Matrix,
 ));

=cut

sub matrix_plot {
	my ($x, $y, $matrix);
	if (@_ == 1) {
		$matrix = $_[0];
		my @dims = $matrix->dims;
		$x = [0, $dims[0]];
		$y = [0, $dims[1]];
		($matrix) = @_;
	}
	elsif (@_ == 3) {
		($x, $y, $matrix) = @_;
	}
	else {
		croak("matrix_plot expects an image, optionally preceeded by its x- and y-limits:\n"
			. "matrix_plot ([x0, xf], [y0, yf], \$image)")
	}
	
	@_ = (-image => ds::Grid(
		$matrix,
		x_bounds => $x,
		y_bounds => $y,
	));
	goto &plot;
}

=item imag_plot ([$x_edges, $y_edges,] $matrix)

The C<imag_plot> function is identical to L<matrix_plot|/matrix_plot> except that the
color scaling runs from black (lowest) to white (highest). This form is
especially useful for plotting black and white images, in which case the
brightest points should be white.

Omitting edges, the command looks like this:

 imag_plot($matrix);

which has the equivalent L<plot|/"PLOT FUNCTION"> command:

 plot(-image => ds::Grid(
     $matrix,
     x_bounds => [0, 1],
     y_bounds => [0, 1],
     plotType => pgrid::Matrix(
         palette => pal::BlackToWhite
     ),
 ));

Specifying edges looks like this:

 imag_plot ([0 => 5], [1 => 10], $matrix);

and the quivalent is:

 plot(-image => ds::Grid(
     $matrix,
     x_bounds => [0, 5],
     y_bounds => [1, 10],
     plotType => pgrid::Matrix(
         palette => pal::BlackToWhite
     ),
 ));

=cut

sub imag_plot {
	my ($x, $y, $matrix);
	if (@_ == 1) {
		$matrix = $_[0];
		my @dims = $matrix->dims;
		$x = [0, $dims[0]];
		$y = [0, $dims[1]];
		($matrix) = @_;
	}
	elsif (@_ == 3) {
		($x, $y, $matrix) = @_;
	}
	else {
		croak("imag_plot expects an image, optionally preceeded by its x- and y-limits:\n"
			. "imag_plot ([x0, xf], [y0, yf], \$image)")
	}
	
	@_ = (-image => ds::Grid(
		$matrix,
		x_bounds => $x,
		y_bounds => $y,
		plotType => pgrid::Matrix(
			palette => pal::BlackToWhite
		),
	));
	goto &plot;
}

=back

=head1 PLOT FUNCTION

The C<plot> function is the real workhorse of this module. Not only does it
provide the functionality behind all of the above simple functions, but it
also lets you plot multiple L<DataSet|PDL::Graphics::Prima::DataSet/>s, specify
axis labels and a plot title, direct the axis scaling (linear or logarithmic), and set many other properties
of the plot.

Arguments that you pass to this function are almost identical to the arguments
that you would use to create a Plot widget, so it serves as an excellent sandbox
for playing with the widget's constructor. Also, once you understand how to use
this function, using the actual widget in an interactive GUI script is simply a
matter of understanding how to structure a GUI program.

The C<plot> function takes options and L<DataSet|PDL::Graphics::Prima::DataSet/>
specifications as key/value pairs. The basic usage of C<plot> looks like this:

 plot(
     -dataset1 => ds::Pair($x1, $y1, ...options...),
     x => {
     	axis => options,
     },
     -dataset2 => ds::Pair($x2, $y2, ...options...),
     y => {
     	axis => options,
     },
     -mydist => ds::Set($data, ...options...),
     title => 'Title!',
     titleSpace => 60,
     -the_image => ds::Grid($image, ...options...),
     ... Prima Drawable options ...
 );

Notice that some of the keys begin with a dash while others do not. Any key
that begins with a dash should be followed by a
L<DataSet|PDL::Graphics::Prima::DataSet/> object (created using the C<ds::xxx>
constructors). You can use any name that you wish for your
L<DataSet|PDL::Graphics::Prima::DataSet/>s, the only requirement is that the name
begins with a dash. (The dash is optional when it comes time to retrieve the
L<DataSet|PDL::Graphics::Prima::DataSet/> later.) The keys that do not begin with
a dash are Plot options. The Plot widget has a
handful of Plot-specific properties, but you can also specify any property of a
L<Prima::Widget> object.

In the world of C<PDL::Graphics::Prima>, the fundamental object is the Plot.
Each plot can hold one or more L<DataSet|PDL::Graphics::Prima::DataSet/>s, and
each L<DataSet|PDL::Graphics::Prima::DataSet/> is visualized using one or more
L<PDL::Graphics::Prima::PlotType/>s. This makes the plotType the simplest element
to discuss, so I'll start there.

=head2 Plot Types

Each L<DataSet|PDL::Graphics::Prima::DataSet/> can have one or more plotTypes. If
you only want to specify a
single plotType, you can do so by specifying it after the plotType key for your
L<DataSet|PDL::Graphics::Prima::DataSet/>:

 -data => ds::Pair(
     ...
     plotType => ppair::Squares,
     ...
 )

You can specify multiple plotTypes by passing them in an anonymous array:

 -data => ds::Pair(
     ...
     plotTypes => [ppair::Triangles, ppair::Lines],
     ...
 )

(Note that the singular and plural keys C<plotType> and C<plotTypes> are
interchangeable. Use whichever is appropriate.)

All the plotTypes take key/value paired arguments. You can specify various
L<Prima::Drawable|Prima::Drawable/> properties like
L<lineWidth|Prima::Drawable/lineWidth> or L<color|Prima::Drawable/color>; you
can pass plotType-specific options like symbol size
(for L<ppair::Symbol|PDL::Graphics::Prima::PlotType/ppair::Symbol> and its
derivatives) using the C<size> key or the baseline height for
L<ppair::Histogram|PDL::Graphics::Prima::PlotType/ppair::Histogram> using the
C<baseline> key; and some of the plotTypes have required arguments, such as
at least one error bar specification with
L<ppair::ErrorBars|PDL::Graphics::Prima::PlotType/ppair::ErrorBars>. To create
L<red|Prima::Const/cl> L<blobs|PDL::Graphics::Prima::PlotType/ppair::Blobs>,
you would use something like this:

 ppair::Blobs(color => cl::LightRed)

To create L<blobs|PDL::Graphics::Prima::PlotType/ppair::Blobs> of all
different colors, you would use the plural C<colors>
key and specify a piddle with Color values. (That's discussed below in an
example.) To specify a 5-pixel line width for a Lines plotType, you would say

 ppair::Lines(lineWidth => 5)

When a L<DataSet|PDL::Graphics::Prima::DataSet/> gets drawn, it draws the
different plotTypes in the order
specified. For example, suppose you specify C<cl::Black> filled triangles and
C<cl::LightRed> lines. If the triangles are specified first, they will have red
lines drawn through them, and if the triangles are second, the triangles will
be drawn over the red lines.

Each L<DataSet|PDL::Graphics::Prima::DataSet/> has a default plot type. For 
L<Dist|PDL::Graphics::Prima::DataSet/Dist>s, it is
L<ppair::histogram|PDL::Graphics::Prima::PlotType/ppair::Histogram>. For
L<Pairs|PDL::Graphics::Prima::DataSet/Pair>, it is
L<ppair::Diamonds|PDL::Graphics::Prima::PlotType/ppair::Diamonds>. For
L<Grids|PDL::Graphics::Prima::DataSet/>, it is
L<pgrid::Matrix|PDL::Graphics::Prima::PlotType/pgrid::Matrix>. If you
want to use a different plotType, you need to specify it as illustrated
by the translations given in the super-simple examples above. The plotTypes are
discussed thoroughly in
L<PDL::Graphics::Prima::PlotType|PDL::Graphics::Prima::PlotType/>, and are
summarized below:

 Pair plotTypes
 ==============
 ppair::Lines      - lines from point to point
 ppair::TrendLines - a linear fit to the data
 ppair::Blobs      - blobs (filled ellipses) with specifiable x- and y- radii
 ppair::Symbols    - open or filled regular geometric shapes with many options:
                     size, orientation, number of points, skip pattern, and fill
 ppair::Triangles  - open or filled triangles with  specifiable
                     orientations and sizes
 ppair::Squares    - open or filled squares with specifiable sizes
 ppair::Diamonds   - open or filled diamonds with specifiable sizes
 ppair::Stars      - open or filled star shapes with specifiable sizes,
                     orientations, and number of points
 ppair::Asterisks  - asterisk shapes with specifiable size, orientation, and
                     number of points
 ppair::Xs         - four-point asterisks that look like xs, with specifiable
                     sizes
 ppair::Crosses    - four-point asterisks that look like + signs, with
                     specifiable sizes
 ppair::Spikes     - spikes to (x,y) from a specified vertical or horizontal
                     baseline
 ppair::Histogram  - histograms with specifiable baseline and top padding
 ppair::ErrorBars  - error bars with specified x/y errors and cap sizes
 
 
 Grid plotTypes
 ==============
 pgrid::Matrix     - colored rectangles, i.e. images

More plot types are planned, but the ones listed above are the currently
implemented ones.

The plotTypes are the simplest unit in L<PDL::Graphics::Prima/>. The next
largest unit is the L<DataSet|PDL::Graphics::Prima::DataSet/>, which not only
holds data of various kinds, but
also holds the plotTypes that are to be applied to the given data.

=head2 DataSets

You can plot one or more sets of data on a given Plot. You do this by specifying
the L<DataSet|PDL::Graphics::Prima::DataSet/>'s name with a dash, followed by a
L<DataSet|PDL::Graphics::Prima::DataSet/> constructor. The
L<DataSet|PDL::Graphics::Prima::DataSet/> constructor specifies the properties of
your L<DataSet|PDL::Graphics::Prima::DataSet/>, including the data
itself along with the plotType or plotTypes.

In addition to the two types that I have already alluded to, namely
L<Pairs|PDL::Graphics::Prima::DataSet/Pair> and
L<Grids|PDL::Graphics::Prima::DataSet/Grid>, there are a collection of
derived L<Datasets|PDL::Graphics::Prima::DataSet/>. These include the
L<Function-based DataSet|PDL::Graphics::Prima::DataSet/Func> and the
L<Distribution Dataset|PDL::Graphics::Prima::DataSet/Dist>.

L<The Pairs DataSet|PDL::Graphics::Prima::DataSet/Pair> targets x/y paired data
and lets you visualize trends and correlations between two collections of data.
The L<constructor|PDL::Graphics::Prima::DataSet/ds::Pair> takes two arguments
(the x-data and the y-data) and then key/value pairs that indicate
your plotTypes and specify precisely how you want the data visualized:

 -scatter => ds::Pair($student_weights, $student_heights, ...options...)

Typical x/y plots are plotted in such a way that the x-data is sorted in
increasing order, but this is not required. This means that it is just as
easy to draw a sine function as it is to draw a spiral or a scatter plot.

L<Dists|PDL::Graphics::Prima::DataSet/Dist> take a single piddle of unordered
data and visually represents it with aggregated plots like histograms,
cumulative distributions, or curves to distribution fits. The
L<constructor|PDL::Graphics::Prima::DataSet/ds::Dist> takes a
single piddle argument that represents that data to plot, and then key/value
pairs that let you tweak how the data is visualized. The most important
key is the binning key, which dictates how the distribution should be mapped
to pairwise data.

 -distribution => ds::Dist($student_heights,
     binning => bt::Log(min => 2),
     ...options...
 )

Any pairwise plot type will work with the distribution plot types, but
some make more (or less) sense than others. For example,
L<CDFs|PDL::Graphics::Prima::DataSet/bt::CDF> are better visualized with
lines whereas L<linearly binned data|PDL::Graphics::Prima::DataSet/bt::Linear>
are sometimes better visualized with histograms.

L<Func DataSets|PDL::Graphics::Prima::DataSet/Func> let you specify a function
to plot, rather than forcing you to evaluate a specific function at fixed values
of x. They inherit from L<Pairs|PDL::Graphics::Prima::DataSet/Pair> (in an OO
sense) and differ in that the constructor expects a single function reference
rather than two piddles of data:

 -model => ds::Func(\&my_model, ...options...)

Because L<Func|PDL::Graphics::Prima::DataSet/Func> inherits from
L<Pairs|PDL::Graphics::Prima::DataSet/Pair>, any
L<Pairs PlotType|PDL::Graphics::Prima::PlotType/Pairs> will also work with
a L<Func DataSet|PDL::Graphics::Prima::DataSet/Func>.

The Grid DataSet is what you would use to visualize matrices or images. It
takes a single piddle which represents a matrix of data,
followed by key/value pairs the specify how you want the data plotted. In
particular, there are many ways to specify the grid centers or boundaries.

 -terrain => ds::Grid($landscape, ...options...)

The data that you specify for the Set, Pair, and Grid DataSets do not need
to be piddles: anything that can be converted to a piddle, including scalar
numbers and anonymous arrays of values, can be specified. That means that the
following are valid DataSet specifications:

 -data => ds::Pair(sequence(10), sequence(10)->sin)
 -data => ds::Pair([1, 2, 3], [1, 4, 9])
 -data => ds::Pair(sequence(100), 5)

Once you have specified the data or function that you want to plot, you can
specify other options with key/value pairs. I discussed the
plotType key already, but you can also specify any property in L<Prima::Drawable>.
When you specify properties from L<Prima::Drawable>, these become the default
parameters for all the plotTypes that belong to this DataSet. For example, you
can specify a default color as C<cl::LightRed>, and then the lines, blobs, and
error bars will be drawn in red unless they override the colors themselves.
Function-based DataSets also recognize the C<N_points> key, which indicates the
number of points to use in evaluating the function.

To get an idea of how this works, suppose I have some data that I want to
compare with a model. In this case, I would have two DataSets, the data (plotted
using error bars) and the model (plotted using a line). I would plot all of this
with code like so:

 plot(
     # The experimental data
     -data => ds::Pair(
         $x,
         $y,
         # I want error bars along with squares:
         plotTypes => [
             ppair::ErrorBars(y_err => $y_errors),
             ppair::Squares(filled => 1),
         ],
     ),
     
     # The model:
     -model => ds::Func(
         \&my_model,
         # Default plotType is diamonds, but I want lines:
         plotType => ppair::Lines,
         lineStyle => lp::ShortDash,
     ),
 );

The part C<< -data => ds::Pair(...) >> specifies the details for how you want to plot
the experimental data and the part C<< -model >> specifies the details for how you
want to plot the model.

The DataSets are plotted in ASCIIbetical order, which means that in the example
above, the model will be drawn over the error bars and squares. If you want the data
plotted over the model curve, you should choose different names so that they sort
the way you want. For example, using C<-curve> instead of C<-model> might work.
So would changing the names from C<-data> and C<-model> to C<-b_data> and
C<-a_model>, respectively.

=head2 Plot Options

Finally we come to setting plot-wide properties. As already discussed, you can
disperse DataSets among your other Plot properties. Plot-wide properties include
the title and the amount of room you want for the title (called titleSpace),
the axis specifications, and any default L<Prima::Drawable> properties that you
want applied to your plot.

The text for your plot's title should be a simple Perl string. UTF8 characters
are allowed, which means you can insert Greek or other symbols as you need them.
However, L<Prima>, and therefore L<PDL::Graphics::Prima>, does not support fancy
typesetting like subscripts or superscripts. (If you want that in the Plot
library, you should probably consider petitioning for and helping add that
functionality to Prima. Open-source is great like that!) The amount of space
allocated for the title is currently set at 80 pixels. You can specify a
different size if you prefer. (It should probably be calculated based on the
current font-size---Prima makes it relatively easy to do that---but that's not 
yet implemented.) Space is allocated for the title only when you specify one;
if none is specified, you have more room for your plot.

Axis labels have similar restrictions and capabilities as the title string, but
are properties of the axes themselves, which additionally have specifiable
bounds (min and max) and scaling type. At the moment, the only two scaling types
are C<sc::Linear> and C<sc::Log>. The bounds can be set to a specific numeric
value, or to C<lm::Auto> if you want the bounds automatically computed based on
your data and plotTypes.

Finally, this is essentially a widget constructor, and as such you can specify
any L<Prima::Widget> properties that you like. These include all the properties in
L<Prima::Drawable>. For example, the default background color is white, because
I like a white background on my plots. If you disagree, you can change the widget's
background and foreground colors by specifying them. The DataSets and their
plotTypes will inherit these properties (most importantly, the foreground color)
and use them unless you override those properties seperately.

=head2 Examples

This first example is a simple line plot with triangles at each point. There's only
one DataSet, and it has only two plotTypes:

 use strict;
 use warnings;
 use PDL::Graphics::Prima::Simple;
 use PDL;
 
 my $x = sequence(100)/10;
 my $y = sin($x);
 
 plot(
     -data => ds::Pair(
         $x,
         $y,
         plotTypes => [
             ppair::Triangles,
             ppair::Lines,
         ],
     ),
 );

Now for something more fun. This figure uses bright colors and random circle radii.
Notice that the lineWidth of 3 obscures many of the circles since their radii are
between 1 and 5. This has only one DataSet and two plotTypes like the
previous example. In contrast to the previous example, it specifies a number of
properties for the plotTypes:

 use strict;
 use warnings;
 use PDL::Graphics::Prima::Simple;
 use PDL;
 
 my $x = sequence(100)/10;
 my $y = sin($x);
 my $colors = pal::Rainbow->apply($y);
 
 plot(
     -data => ds::Pair(
         $x,
         $y,
         plotTypes => [
             ppair::Blobs (
                 radius => 1 + $x->random*4,
                 colors => $colors,
             ),
             ppair::Lines (
                 lineWidths => 3,
             ),
         ],
     ),
 );

Here I use a black background and white foreground, and plot the circles B<over>
the line instead of under it. I achieve this by changing the order of the
plotTypes---Lines then Blobs.

 use strict;
 use warnings;
 use PDL::Graphics::Prima::Simple;
 use PDL;
 
 my $x = sequence(100)/10;
 my $y = sin($x);
 my $colors = pal::Rainbow->apply($y);
 my $radius = 1 + $x->random*4;
 
 plot(
     -data => ds::Pair(
         $x,
         $y,
         plotTypes => [
             ppair::Lines (
                 lineWidths => 3,
             ),
             ppair::Blobs (
                 radius => $radius,
                 colors => $colors,
             ),
         ],
     ),
     backColor => cl::Black,
     color => cl::White,
 );

I find the smaller points very difficult to see, so here's a version in which I
'wrap' the points with a white radius. I also use the Symbols plotType instead
of the Blobs plotType because it's a bit more flexible:

 use strict;
 use warnings;
 use PDL::Graphics::Prima::Simple;
 use PDL;
 
 my $x = sequence(100)/10;
 my $y = sin($x);
 my $colors = pal::Rainbow->apply($y);
 my $radius = 1 + $x->random*4;
 
 plot(
     -data => ds::Pair(
         $x,
         $y,
         plotTypes => [
             ppair::Lines (
                 lineWidths => 3,
             ),
             ppair::Symbols(
                 size => 1 + $radius,
                 filled => 'no',
                 N_points => 0,
             ),
             ppair::Symbols (
                 size => $radius,
                 colors => $colors,
                 filled => 'yes',
                 N_points => 0,
             ),
         ],
     ),
     backColor => cl::Black,
     color => cl::White,
 );

Here I use PDL threading to achieve the same ends as the previous example, but
only using one Blobs plotType instead of two.

 use strict;
 use warnings;
 use PDL::Graphics::Prima::Simple;
 use PDL;
 
 my $x = sequence(100)/10;
 my $y = sin($x);
 my $rainbow_colors = pal::Rainbow->apply($y);
 my $whites = $y->ones * cl::White;
 my $colors = cat($whites, $rainbow_colors);
 my $inner_radius = 1 + $x->random*4;
 my $radius = cat($inner_radius + 1, $inner_radius);
 
 plot(
     -data => ds::Pair(
         $x,
         $y,
         plotTypes => [
             ppair::Lines (
                 lineWidths => 3,
             ),
             ppair::Blobs(
                 radius => $radius,
                 colors => $colors,
             ),
         ],
     ),
     backColor => cl::Black,
     color => cl::White,
 );

Here I generate some linear data with noise and perform a least-squares fit to
it. In this case I perform the least-squares fit by hand, since not everybody
will have Slatec installed. The important part is the C<use PDL::Graphics::Prima::Simple>
line and beyond.

This example demonstrates the use of multiple data sets, the use of the
ErrorBars plotType and the use of function-based data sets.

 use strict;
 use warnings;
 use PDL;
 
 my $x = sequence(100)/10;
 my $y = $x/2 - 3 + $x->grandom*3;
 my $y_err = 2*$x->grandom->abs + 1;
 
 # Calculate the slope and intercept:
 my $S = sum(1/$y_err);
 my $S_x = sum($x/$y_err);
 my $S_y = sum($y/$y_err);
 my $S_xx = sum($x*$x/$y_err);
 my $S_xy = sum($x*$y/$y_err);
 my $slope = ($S_xy * $S - $S_x * $S_y) / ($S_xx * $S - $S_x * $S_x);
 my $y0 = ($S_xy - $slope * $S_xx) / $S_x;
 
 
 use PDL::Graphics::Prima::Simple;
 
 plot(
     -data => ds::Pair(
         $x,
         $y,
         plotTypes => [
             ppair::Diamonds(filled => 'yes'),
             ppair::ErrorBars(y_err => $y_err),
         ],
     ),
     -func => ds::Func(
         sub { $y0 + $slope * $_[0] },
         lineWidth => 2,
         color => cl::LightRed,
     ),
 );

That example used a function-based DataSet, but we could just as easily have
used C<ppair::TrendLines> to compute the fit for us. The only difference between
the last example and the one below is that the trendline for this next example
does not extend out to infinity in the x-direction but terminates at the
end of the data.

 use strict;
 use warnings;
 use PDL;
 
 my $x = sequence(100)/10;
 my $y = $x/2 - 3 + $x->grandom*3;
 my $y_err = 2*$x->grandom->abs + 1;
 
 use PDL::Graphics::Prima::Simple;
 
 plot(
     -data => ds::Pair(
         $x,
         $y,
         plotTypes => [
             ppair::Diamonds(filled => 'yes'),
             ppair::ErrorBars(y_err => $y_err),
             ppair::TrendLines(
                 weights => $y_err,
                 lineWidths => 2,
                 colors => cl::LightRed,
             ),
         ],
     ),
 );


You can extend the Simple interface with GUI methods. The next example gives
you a first glimps into GUI-flavored programming by overriding the onMouseMove
method for this Prima widget. There are many ways of setting, overriding, or
adding callbacks in relation to all sorts of GUI events, but when using the
C<plot> command, your only option is to specify it as OnEventName.

In this example, I add (that's B<add>, not override, becaus Prima rocks) a
method that prints out the mouse position to the console. I also use logarithmic
scaling in the x direction (and specify x- and y-axes labels) to make things
interesting:

 use strict;
 use warnings;
 use PDL::Graphics::Prima::Simple;
 use PDL;
 
 # Turn on autoflush:
 $|++;
 
 my $x = sequence(100)/10 + 1;
 my $y = sin($x);
 
 plot(
     -data => ds::Pair(
         $x,
         $y,
         plotTypes => [
             ppair::Xs,
             ppair::Lines,
         ],
     ),
     onMouseMove => sub {
         # Get the widget and the coordinates:
         my ($self, $button_and_modifier, $x_pixel, $y_pixel) = @_;
         # Convert the pixel coordinates to real values:
         my $x = $self->x->pixels_to_reals($x_pixel);
         my $y = $self->y->pixels_to_reals($y_pixel);
         # Print the results:
         print "\r($x, $y)           ";
     },
     x => {
         label => 'time (s)',
         scaling => sc::Log,
     },
     y => {
         label => 'displacement (m)',
     }
 );

This kind of immediate feedback can be very useful. It is even possible to
capture keyboard events and respond to user interaction this way. But B<please>,
don't do that. If you need any substantial amount of user interaction, you
would do much better to learn to create a Prima application with buttons, lists,
and input lines, along with the Plot widget. For that, see the (soon to be
written) L<PDL::Graphics::Prima::InteractiveTut>.

=cut

# A function that allows for quick one-off plots by packing a plot widget
# into a window. In void context and no readline support, it builds and
# executes the window. In void context and readline support it returns
# immediately, letting the readline handle yield()ing. A scalar context
# return is only allowed when readline support is enabled. (App::Prima::REPL
# allows for scalar return context by overriding this plot command, and other
# libraries that want to support the simple interface should do the same.)
# In list context, it returns both the window and the plot object.

# A function that allows for quick one-off plots:
*plot = \&default_plot;
our $auto_twiddling = 1;
our $is_twiddling = 0;
our $N_windows = 0;
sub default_plot {
	# Make sure they sent key/value pairs:
	croak("Arguments to plot must be in key => value pairs")
		unless @_ % 2 == 0;
	my %args = @_;
	
	# Create a new window and pack the plot into said window
	unless (defined $::application) {
		require Prima::Application;
		Prima::Application->import;
	}
	my $window = Prima::Window->create(
		text  => $args{title} || 'PDL::Graphics::Prima',
		size  => $args{size} || [our @default_sizes],
		# Add a stop-twiddling listener
		onKeyDown => sub {
			my (undef, $key) = @_;
			$is_twiddling = 0 if chr($key) =~ /q/i;
		},
		# Pair of functions to note when windows are created and destroyed
		# for purposes of quitting twiddling when the last window is closed.
		onCreate => sub {
			$N_windows++;
		},
		onDestroy => sub {
			$N_windows--;
			$is_twiddling = 0 if $N_windows == 0;
		},
	);
	my $plot = $window->insert('Plot',
		pack => { fill => 'both', expand => 1},
		%args
	);
	$plot->onKeyDown(sub {
		my (undef, $key) = @_;
		$is_twiddling = 0 if chr($key) =~ /q/i;
	});
	# make sure it shows up on top.
	$window->bring_to_front;
	
	# Twiddle, then return. Note that twiddling (defined below) may be a
	# no-op for configurations where the application loop is already running.
	twiddle() if $auto_twiddling;
	return $plot;
}

sub auto_twiddle {
	$auto_twiddling = $_[0] if @_;
	return $auto_twiddling;
}

# Make twiddling a no-op if we're in the perldl shell and have event_loop
# support:
use Scalar::Util qw(refaddr);
if (PDL::Graphics::Prima::ReadLine->is_setup) {
	*twiddle = sub {};
}
# Otherwise, make it run the event loop:
else {
	*twiddle = sub {
		# twiddling should be a no-op if the plot function is not default_plot,
		# which is the case for App::Prima::REPL
		return if refaddr(\&plot) != refaddr(\&default_plot);
		
		# No event looping if we don't have any open windows. Otherwise,
		# they won't be able to exit the loop!
		print "No open plots\n" and return if $N_windows == 0;
		# Print a notice explaining what's going on:
		print "Twiddling plot; close window or press q or Q to resume\n";
		
		# We will use Prima's nice exception handling to exit the go()
		# method. In order to prevent undue error propogation, localize
		# the error message:
		local $@;
		
		$is_twiddling = 1;
		# Start the timer that will check for the exit condition. There
		# are a number of ways in which the loop will want to exit; placing
		# the exit excption here centralizes the exception handling.
		Prima::Timer->create(
			onTick => sub {
				if (not $is_twiddling) {
					$_[0]->stop;
					# die in order to exit the application loop
					die 'done with event loop';
				}
			},
			timeout => 500, # milliseconds
		)->start;
		# Run go() in an eval so we catch the exit exception
		eval { $::application->go };
		# Rethrow the error unless it was the exit exception
		die unless $@ =~ /^done with event loop/;
	};
}
# Add the twiddle method to the Prima window
*Prima::Window::twiddle = \&twiddle;
*Prima::Plot::twiddle = \&twiddle;


=head1 IMPORTED METHODS

There are a couple of ways to call this module. The first is just a simple
use statement:

 use PDL::Graphics::Prima::Simple;

This will import the above mentioned functions into your local package's
symbol table, which is generally what you want. If you do not want any
functions imported, you can call it with an empty string:

 use PDL::Graphics::Prima::Simple '';

or you can name the functions that you want imported:

 use PDL::Graphics::Prima::Simple qw(plot);

In addition, you can specify the default window plot size by passing a two
element anonymous array:

 # default to 800 x 800 window:
 use PDL::Graphics::Prima::Simple [800, 800];
 
 # default to 800 wide by 600 tall, import nothing:
 use PDL::Graphics::Prima::Simple [800, 600], '';
 
 # default to 300 wide by 450 tall, import 'plot' function:
 use PDL::Graphics::Prima::Simple [300, 450], 'plot';

As an experimental feature, you can provide a subroutine reference in
the import method. This subroutine reference will get invoked by the
plotting commands instead of the default plotting mechanism. This is of
marginal utility, and might be better achieved with a simple glob assignment
of C<*PDL::Graphics::Prima::Simple::plot> to your desired function. The glob
assignment has the advantage that it can be C<local>ized.

Note: I am considering adding a '-hold' option, which would cause all
void-context plot commands in scripts to not block, and cause the Prima
event loop to be run at the end of the script. However, I haven't settled
on either the behavior or the name. Input is welcome!

=cut

# import/export stuff:
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(plot line_plot circle_plot triangle_plot
	square_plot diamond_plot cross_plot X_plot asterisk_plot hist_plot
	matrix_plot imag_plot func_plot
	twiddle auto_twiddle
	);
our @EXPORT_OK = (@EXPORT);

our @default_sizes = (400, 400);

# Override the import method to handle a few user-specifiable arguments:
sub import {
	my $package = shift;
	my @args;
	# Run through all the arguments and pull out anything special:
	foreach my $arg (@_) {
		# See if they passed in an array reference
		if(ref ($arg) and ref($arg) eq 'ARRAY') {
			# Make sure it is the correct size:
			croak("Array references passed to PDL::Graphics::Prima::Simple indicate the\n"
				. "desired plot window size and must contain two elements")
				unless @$arg == 2;
			
			# Apparently we're good to go so save the sizes:
			@default_sizes = @$arg;
		}
		#elsif ($arg eq '-hold') {
		#	# Add code here for holding after each plot
		#}
		elsif (ref ($arg) and ref($arg) eq 'CODE') {
			# a CODE ref; assign plot() to it
			no warnings 'redefine';
			*plot = $arg;
		}
		else {
			push @args, $arg;
		}
	}
	
	$package->export_to_level(1, $package, @args);
}

1;

__END__

=head1 LIMITATIONS AND BUGS

I am sure there are bugs in this software. If you find them, you can report them
in one of two ways:

=over

=item PDL Mailing List

You can (and should!) join the PDL mailing list, and you should feel free to
post questions about this or any other PDL module on that list. For details on
how to sign-up, see L<http://pdl.perl.org/?page=mailing-lists>.

=item Github

The best place to report problems that you are sure are problems is at
L<http://github.com/run4flat/PDL-Graphics-Prima/issues>.

=back

=head1 SEE ALSO

For an introduction to L<Prima> see L<Prima::tutorial>.

=head1 AUTHOR

David Mertens (dcmertens.perl@gmail.com)

=head1 ADDITIONAL MODULES

Here is the full list of modules in this distribution:

=over

=item L<PDL::Graphics::Prima|PDL::Graphics::Prima/>

Defines the Plot widget for use in Prima applications

=item L<PDL::Graphics::Prima::Axis|PDL::Graphics::Prima::Axis/>

Specifies the behavior of axes (but not the scaling)

=item L<PDL::Graphics::Prima::DataSet|PDL::Graphics::Prima::DataSet/>

Specifies the behavior of DataSets

=item L<PDL::Graphics::Prima::Limits|PDL::Graphics::Prima::Limits/>

Defines the lm:: namespace

=item L<PDL::Graphics::Prima::Palette|PDL::Graphics::Prima::Palette/>

Specifies a collection of different color palettes

=item L<PDL::Graphics::Prima::PlotType|PDL::Graphics::Prima::PlotType/>

Defines the different ways to visualize your data

=item L<PDL::Graphics::Prima::ReadLine|PDL::Graphics::Prima::ReadLine/>

Encapsulates all interaction with the L<Term::ReadLine> family of
modules.

=item L<PDL::Graphics::Prima::Scaling|PDL::Graphics::Prima::Scaling/>

Specifies different kinds of scaling, including linear and logarithmic

=item L<PDL::Graphics::Prima::Simple|PDL::Graphics::Prima::Simple/>

Defines a number of useful functions for generating simple and not-so-simple
plots

=back

=head1 LICENSE AND COPYRIGHT

Unless otherwise stated, all contributions in code and documentation are
copyright (c) their respective authors, all rights reserved.

Portions of this module's code are copyright (c) 2011 The Board of
Trustees at the University of Illinois.

Portions of this module's code are copyright (c) 2011-2013 Northwestern
University.

Portions of this module's code are copyright (c) 2013-2014 Dickinson
College.

This module's documentation is copyright (c) 2011-2014 David Mertens.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
