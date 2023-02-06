use strict;
use warnings;

=head1 NAME

PDL::Graphics::Prima::SizeSpec - a module for handling size specifications

=head1 SYNOPSIS

 use PDL::Graphics::Prima::SizeSpec;

 # Create a SizeSpec parser for your window/widget
 my $parser = PDL::Graphics::Prima::SizeSpec::Parser->new($my_window);

 # Create a dynamic size-computing object from a string:
 my $size = $parser->parse('10%width + 2em - 5px');

 # Get the size in pixels using the size method:
 print "That amounts to ", $size->size, " pixels\n";

 # stringification is mostly round-tripable:
 print "The original spec was $size\n";

 # use the spec directly in numeric evaluations
 print "Too big\n" if $size > 100;

 # Instead of a string, you can provide a hashref to the parser
 my $size = $parser->parse({em => 2, px => -5,
     pctwidth => 10});


 ### Create more sophisticated parsers by subclassing ###
 package My::Parser;
 our @ISA = qw(PDL::Graphics::Prima::SizeSpec::Parser);

 sub size_spec_pctcolwidth {
     my ($self, $percent) = @_;

     # Return a closure that takes no arguments and which
     # returns pixels for a given column width percentage
     return sub {
         return $self->{widget}->column_width * $percent / 100;
     }
 }

 # Now I can create a parser...
 my $newspaper_parser = My::Parser->new($newspaper);
 # ... and use the parser to create a size spec
 #     that knows how to parse '20%colwidth'
 my $size_spec = $newspaper_parser->parse($size);

=head1 DESCRIPTION

If you've ever worked with CSS, you know that you can specify the sizes
of things using lots of different units. C<PDL::Graphics::Prima::SizeSpec>
is my attempt at providing a similar sort of capability for Prima
widgets.

The primary purpose of a SizeSpec object is to compute pixel distances for you.
However, the SizeSpec object is dynamic insofar as it responds to changes in
the associated widget. If you have a SizeSpec that depends upon the height or
width of the widget, and the widget gets resized, then the SizeSpec's numeric
value will change in response. Likewise if your SizeSpec depends upon the
em-width and you change your widget's font.

In practice, SizeSpec objects are little more than thin wrappers around a
collection of closures. Once you've used a parser to obtain a SizeSpec object,
you can easily obtain the number of pixels associated with the SizeSpec by
evaluating it in numerical context, or by calling the C<size> method:

 my $margin = $margin_spec->size;

If you know that certain units are associated with dynamic behavior, you
can inquire as to whether a given unit is used:

 if ($margin_spec->uses_unit('%width')) {
     ...
 }

You do not build SizeSpecs directly with a call to C<new>. Instead, SizeSpecs
are built by SizeSpec parsers. The parser's job is to validate the input and
construct closures that efficiently map the specified units to pixel
values. These closures are at the heart of the SizeSpec objects.
Parsers also produce the string representation of the SizeSpec that is
used when the SizeSpec is stringified.

Parse objects provide only a single user-level method: C<parse>. This
method accepts either a string containing an arithmetic combination of
units (i.e. C<'5em - 2px'>) or a hashref of unit/value pairs. The string
form is usually more convenient for simple specifications, but you can
do clever things with the hashref form. For example, the value
associated with the hashref can be an object that overloads addition,
such as a PDL. In that case, the final size given by the SizeSpec will
itself be a PDL, not a scalar.

A SizeSpec's stringification is usually round-tripable, except when you
parse a hashref that includes objects. The stringification is meant to
be human readable and simply stringifies the object itself, thus
discarding class information. (I have gone to the pains of handling large
PDL objects in a sensible way: PDLs with more than 10 elements are
stringified to C<'[PDL]'>.)

Both SizeSpecs and SizeSpec parsers assume they are working with a
single widget, specified as the first argument to the parser's
constructor. If you want to use an identical SizeSpec string on two
different widgets, you need to build a separate parser for each widget.

The base parser class knows how to handle the following units:

=over

=item px

Raw pixel counts.

=item em

The width of the letter M

=item %width, pctwidth

A percentage of the widget's width.

=item %height, pctheight

A percentage of the widget's height.

=item line

A multiple of the font (i.e. line) height.

=back

Unitless numbers are treated as pixels. Pixel sizes for all of these are
obtained from the parser's widget, which is the first argument provided
to the constructor.

The general way of adding new units or overriding the interpretation of
known units is to subclass the parser, discussed in L</SUBCLASSING>. If
you just want to create a single parser object with special unit
handling, you can specify a key/subref pair in the parser constructor
call. The key must be a SizeSpec unit name, described under
L</SUBCLASSING>, and the method must be identical to a SizeSpec unit
method. In short, the associated subref should accept the parser object
and the multiple of the unit as arguments, and return a closure that
takes no arguments and returns a size in pixels for the associated
quantity. Thus the newspaper example written above could have been
written as

 my $newspaper_parser = PDL::Graphics::Prima::SizeSpec::Parser->new(
     $newspaper,
     size_spec_pctcolwidth => sub {
         my ($self, $percent) = @_;
         return sub {
             return $self->{widget}->column_width * $percent / 100;
         }
     },
 );

As another example, if you want to create a parser for which the C<line>
unit refers to the widget's drawn line width, you could do this:

 my $parser = PDL::Graphics::Prima::SizeSpec::Parser->new(
     $canvas,
     size_spec_line => sub {
         my ($self, $multiple) = @_;
         return sub { $canvas->lineWidth * $multiple  };
     },
 );

Parsers with ad-hoc units may be convenient, but are difficult to
extend. If you want to create a parser that others can use, consider
creating a subclass of C<PDL::Graphics::Prima::SizeSpec::Parser>.

=cut

########################################################################
            package PDL::Graphics::Prima::SizeSpec;
########################################################################
# Bare-bones object that merely evaluates an already-parsed size spec
# and knows how to stringify and numerify itself. The real magic happens
# in the ::Parser package defined below.

sub new {
	my ($class, $spec_string, $used_units_hash, @subrefs) = @_;
	my $self = {
		spec_string => $spec_string,
		used_units  => $used_units_hash,
		subrefs     => \@subrefs,
	};
	return bless $self, $class;
}

use overload '""' => sub { $_[0]->{spec_string} },
	'0+' => \&size,
	'+' => \&add,
	'-' => \&subtract,
	'*' => \&multiply,
	'/' => \&divide,
	'<=>' => \&compare,
	fallback => 1;

sub add {
	my ($self, $other, $swap) = @_;
	return $self->size + $other;
}

sub subtract {
	my ($self, $other, $swap) = @_;
	return $other - $self->size if $swap;
	return $self->size - $other;
}

sub multiply {
	my ($self, $other, $swap) = @_;
	return $self->size * $other;
}

sub divide {
	my ($self, $other, $swap) = @_;
	return $other / $self->size if $swap;
	return $self->size / $other;
}

sub compare {
	my ($self, $other, $swap) = @_;
	return $other <=> $self->size if $swap;
	return $self->size <=> $other;
}

sub size {
	my $self = shift;
	my $size = 0;
	$size += $_->() for @{$self->{subrefs}};
	return $size;
}

sub uses_unit {
	my ($self, $unit_to_check) = @_;
	return exists $self->{used_units}{$unit_to_check};
}


########################################################################
          package PDL::Graphics::Prima::SizeSpec::Parser;
########################################################################
use Scalar::Util ();
use Carp;

sub new {
	my ($class, $widget, %args) = @_;
	croak('You must provide a widget to PDL::Graphics::Prima::SizeSpec::Parser')
		if not defined $widget or not eval { $widget->isa('Prima::Drawable') };
	my $self = bless { %args, widget => $widget}, $class;

	# Avoid memory leaks
	Scalar::Util::weaken($self->{widget});

	return $self;
}

sub parse {
	my ($self, $spec) = @_;
	return $spec if ref($spec)
		and eval { $spec->isa('PDL::Graphics::Prima::SizeSpec') };

	# If it's a string spec,
	return $self->parse_string($spec) unless ref($spec);
	return $self->parse_hashref($spec);
}

sub parse_string {
	my ($self, $spec) = @_;
	my $orig_spec = $spec;

	# Build a collection of self-closed subrefs to evaluate
	my (@subrefs, %used_units);

	while ($spec) {
		# Strip leading white space
		$spec =~ s/^\s+//;
		# Remove positive signs and/or addition
		$spec =~ s/^\+\s*//;
		# remove white space between subtraction and the forthcoming
		# unit; turn into negative number
		$spec =~ s/^-\s+/-/;

		# Pull out the number and suffix, and look for a subref
		if ($spec =~ s/^(-?\d+(\.\d*)?)\s*(%?\w+)?//) {
			my ($amount, $unit) = ($1, $3);
			$unit ||= 'unitless';
			push @subrefs, $self->get_closure_for($unit, $amount);
			$unit =~ s/^pct/%/;
			$used_units{$unit} = 1;
		}
		else {
			# Anything else generates an error
			croak("Unable to parse length spec starting at $spec");
		}
	}
	return PDL::Graphics::Prima::SizeSpec->new($orig_spec, \%used_units, @subrefs);
}

sub get_closure_for {
	my ($self, $unit, $amount) = @_;
	(my $method = $unit) =~ s/^%/pct/;
	$method = 'size_spec_' . $method;

	# is this a per-parser method?
	if (exists $self->{$method} and ref($self->{$method}) eq ref(sub {})) {
		 return $self->{$method}->($amount);
	}
	# Does the parse class know how to create a closure?
	elsif ($self->can($method)) {
		return $self->$method($amount);
	}
	else {
		croak('Unknown unit ' . $unit);
	}
}

sub parse_hashref {
	my ($self, $spec) = @_;
	my (@subrefs, %used_units);
	my $spec_string = '';
	for my $unit (sort keys %$spec) {
		my $amount = $spec->{$unit};
		$used_units{$unit} = 1;

		# Build the list of subrefs
		push @subrefs, $self->get_closure_for($unit, $amount);

		# Add this to the spec string. Piddles with more than 10 elements
		# are merely described by their class.
		if (Scalar::Util::bless($amount) and eval {$amount->isa('PDL')}
			and $amount->nelem > 10)
		{
			$spec_string .= '+[' . ref($amount) . ']';
		}
		else {
			$spec_string .= '+' if $amount >= 0;
			$spec_string .= $amount;
		}
		$unit =~ s/^pct/%/;
		$spec_string .= $unit unless $unit eq 'RAW';
	}

	return PDL::Graphics::Prima::SizeSpec->new($spec_string, \%used_units, @subrefs);
}

########################################################################
# All unit methods return closures that can quickly compute values based
# on the given arguments and other closed-over things
########################################################################

# Pixels return their argument
sub size_spec_px {
	my ($self, $amount) = @_;
	return sub { $amount }
}

# unitless numbers are taken to be pixels, and thus return their argument
*size_spec_unitless = \&size_spec_px;

# Em-widths calculate the width based on the widget
sub size_spec_em {
	my ($self, $amount) = @_;
	return sub {
		# Get the width of the letter M
		my $points = $self->{widget}->get_text_box('M');
		return $amount * ($points->[4] - $points->[0]);
	};
}

# %height is based on the widget's height
sub size_spec_pctheight {
	my ($self, $amount) = @_;
	return sub { return $amount / 100 * $self->{widget}->height };
}

# %width is based on the widget's width
sub size_spec_pctwidth {
	my ($self, $amount) = @_;
	return sub { return $amount / 100 * $self->{widget}->width };
}

# line is based on the font's size
sub size_spec_line {
	my ($self, $amount) = @_;
	return sub { return $amount * $self->{widget}->font->height };
}

1;

__END__

=head1 SUBCLASSING

If you find yourself creating lots parsers with the same specialized
parsing units, you should consider creating a parser subclass. You add
new units by providing methods with the prefix C<size_spec_>.

=head2 NAMING UNITS

You are free to use any unit name you want so long as it can be used
as a function name with the prefix C<size_spec_>. For example, you may
want to have a unit called C<day_of_week>. In that case, you would have
a method called C<size_spec_day_of_week>:

 sub size_spec_day_of_week {
     my ($self, $amount) = @_;
     return sub {
         ...
     };
 }

C<PDL::Graphics::Prima::SizeSpec::Parser> also knows how to handle units
that include the percent sign, C<%>. For a unit such as C<%colwidth>,
you would have a method called C<size_spec_pctcolwidth>. Note that the
amount given is not divided by 100 for you, as demonstrated in the C<colwidth>
example in the L</SYNOPSIS>.

One final unit name of importance is the unitless unit. The normal
interpretation of unitless numbers is as pixels. However,
L<PDL::Graphics::Prima> uses SizeSpec parsers for which raw numbers
correspond to x- or y-locations on the plot. If you need to overload
the unitless unit, you would use the method name C<size_spec_unitless>.

=head2 UNIT METHODS

A unit method should take the parser object and the amount obtained by
the parser, and it should return a closure which expects no arguments
and which computes and returns its the amount's equivalent size in
pixels. Note that if you need to refer to the widget to obtain a
property for your unit, you should refer to the widet using the C<widget>
key of the parse object. This will avoid circular references.

Here is an example of the implementation of the C<%width> size
specification:

 # %width is based on the widget's width
 sub size_spec_pctwidth {
     my ($self, $amount) = @_;
     return sub { return $amount / 100 * $self->{widget}->width };
 }

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

=item L<PDL::Graphics::Prima::SizeSpec|PDL::Graphics::Prima::SizeSpec/>

Compute pixel distances from meaningful units

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
