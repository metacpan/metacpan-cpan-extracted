use strict;
use warnings;

package PDL::Graphics::Prima::Limits;

our $VERSION = 0.17;   # update with update-version.pl

# Defines the lm (limits) package in a way that CPAN won't index it
package
lm;

use Carp;
#our @CARP_NOT = qw(PDL::Graphics::Prima::Axis PDL::Graphics::Prima);

my $inf;
BEGIN {
	use PDL::Lite;
	$inf = -PDL->pdl(0)->log->at(0);
}

# The fact that lm::Auto is infinite is exploited in pset::Histogram, so if
# you change the representation here, be sure to change the representation
# there, too.
use constant Auto => $inf;
use constant HoldNoWarn => -$inf;
sub Hold () {
	warn("Deprecation notice: unless you speak up, lm::Hold is going to be removed");
	return -$inf;
}

1;

__END__

=head1 NAME

PDL::Graphics::Prima::Limits - defining a few useful constants for setting axis limits

=head1 DESCRIPTION

You probably won't ever need to use this module explicitly, but you will likely
use the constants defined here to manipulate axis autoscaling. This module defines
the constants C<lm::Auto> and C<lm::Hold>. If the explanation below
does not make sense, these constants are also discussed in
L<PDL::Graphics::Prima::Axis>, L<PDL::Graphics::Prima::Simple>, and elsewhere.

=over

=item lm::Auto

When you set an axis's min or max to C<lm::Auto>, you turn on min or max
autoscaling:

 # Set the x-min to -5 for now...
 $plot->x->min(-5);
 
 # Turn on autoscaling for x-min:
 $plot->x->min(lm::Auto);

=item lm::Hold

DEPRECATION CANDIDATE. I am considering deprecating this limit in favor of
a new limit, discussed below. If you use C<lm::Hold>, please let me know so
that I can take your concerns into consideration. It presently serves as a
fairly simple shorthand that I have not actually used in any of my real
code. It is easy to create the desired effect with simple code, and I have
concocted a much more helpful meaning for this value, detailed under the
next item, C<lm::NextTick>.

=over

This constant gives a shorthand for changing from autoscaling to non-autoscaling.
For example, suppose you are building a plot from multiple data sets and want
to autoscale based on the first few but not for the remaining. In that case you
might say:

 $plot->dataSets->{'data'} = ds::Pair($x, $y);
 $plot->y->minmax(lm::Hold, lm::Hold);
 $plot->dataSets->{'model'} = ds::Func(\&my_func);

You can achieve the same ends like so:

 $plot->dataSets->{'data'} = ds::Pair($x, $y);
 $plot->y->minmax($plot->y->minmax);
 $plot->dataSets->{'model'} = ds::Func(\&my_func);

If you just wanted to set the min to hold, you could use C<lm::Hold> like this:

 $plot->y->min(lm::Hold);

which is equivalent to:

 $plot->y->min($plot->y->min);

Also note that the return value of C<$plot-E<gt>y->min> returns different things
depending on whether you are using scalar or list context. (Yes, that's an Axis
thing, not a Limits thing, but it bears repeating here anyway.)

=back

=item lm::NextTick

PROPOSAL CANDIDATE. I am considering adding this functionality some time in
mid to late 2013. It would use the same bit representation as what is
currently C<lm::Hold>, so this would be a backwards incompatible change.
However, I am not aware of any code that actually uses C<lm::Hold> apart
from a few of my own example scripts (I don't use it in any of my production
code), so I suspect it will be fine. (Or, perhaps I should actually make
turning autoscaling on or off a separate axis method. Ah well, ideas, ideas.
Feedback welcome.)

=over

The proposed behavior of C<lm::NextTick> is similar to that of C<lm::Auto>
in that the axis limits would be computed automatically from the data. The
major difference is that C<lm::NextTick> is that, having computed the "tight"
automatic min and/or max, the algorithm would actually set the min and/or
max to a value slightly lower and/or higher, corresponding to the value that
the Tick calculator would pick for the next major tick value. The goal here
would be better static figures without having to tweak the limits.

For example, when I create a default diamond plot in a containing window of
400x400 pixels with inputs C<$x = pdl(1.1, 18.2)> and C<$y = pdl(10, 20)>,
the actual axis extrema are slightly wider thant the data's min and max and
come to 0.84 and 18.5, in order to accomodate the width of the diamonds. I
see three tick marks at 5, 10, and 15. When C<lm::NextTick> gets implemented,
the extrema for that specification would be 0 and 20, showing tick marks at
0, 5, 10, 15, and 20.

That, at least, is the proposed specification. I imagine this would get a
lot more use than C<lm::Hold>, especially since it's not even possible at
the moment.

=back

=back

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
