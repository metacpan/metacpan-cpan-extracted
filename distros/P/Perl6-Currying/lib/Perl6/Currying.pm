package Perl6::Currying;

use Filter::Simple;
use Carp;

croak "Perl6::Placeholders should not be loaded before Perl6::Currying"
	if $INC{'Perl6/Placeholders.pm'};

my $name = qr/(?:\w+(?:::\w+)*)/;
my $scalar = qr/\s*\$\w+\s*/;
our $balbrack = qr{ (?: (?> [^{}]+ ) | \{ (??{ $balbrack }) \} )* }x;

sub prebind {
	my $sub = shift;
	croak "Odd list of bindings for prebind" if @_%2;
	my %bound = @_;
	my $proto = $prototype{$sub} ||= prototype($sub);
	croak "Can't prebind sub with prototype ($proto)" 
		unless $proto =~ /^$scalar(,$scalar)*$/;
	croak "Can't prebind nonexistent parameter \$$_ of sub($proto)"
		foreach grep { $proto !~ /\$$_/ } keys %bound;
	my $parampos = $parampos{$sub} ||= do {
		my @params = $proto =~ /(\w+)/g;
		my %parampos; @parampos{@params} = 0..$#params; \%parampos;
	};
	my @bound = sort { $b->{pos} <=> $a->{pos} }
		    map { pos=>$parampos->{$_}, val=>$bound{$_}}, keys %bound;
	$proto =~ s/,?\$$_// for keys %bound;
	my $HOF = sub {
		splice @_, $bound[$_]{pos}, 0, $bound[$_]{val} for 0..$#bound;
		goto &$sub;
	};
	$prototype{$HOF} = $proto;
	return $HOF;
}

sub Perl6::Currying::Attributes::MODIFY_CODE_ATTRIBUTES {
	my( $package, $ref, @attrs) = @_;
	for my $i (reverse 0..$#attrs) {
		next unless $attrs[$i] =~ /^Prototype\((.*)\)$/;
		$prototype{$ref} = $1;
		splice @attrs, $i;
	}
	return @attrs;
}

push @UNIVERSAL::ISA, 'Perl6::Currying::Attributes';

FILTER_ONLY 
	executable => sub {
		# Subroutine declarations
			s<sub \s* ($name) \s* \( (.*?) \) \s* \{>
			 <sub $1 :Prototype($2) { my($2)=\@_;>gx;
			s<sub \s* \( (.*?) \) \s* \{>
			 <sub ($1) { my($1)=\@_;>gx;
		# Method call syntax
			s{(&$name)\.prebind\(}
			 {Perl6::Currying::prebind(\\$1,}g;
			s{&?(\$$name)\.prebind\(}
			 {Perl6::Currying::prebind($1,}g;
			s{&\{($balbrack)\}\.prebind\(}
			 {Perl6::Currying::prebind($1,}g;
		# Indirect object syntax
			s[\bprebind\s*(&$name)\s*: ]
			 [Perl6::Currying::prebind \\$1,]g;
			s[\bprebind\s*&?(\$$name)\s*:]
			 [Perl6::Currying::prebind $1,]g;
			s[\bprebind\s*&\{($balbrack)\}\s*:]
			 [Perl6::Currying::prebind $1,]g;
		},

__END__

=head1 NAME

Perl6::Currying - Perl 6 subroutine currying for Perl 5

=head1 VERSION

This document describes version 0.05 of Perl6::Currying,
released May 29, 2002.

=head1 SYNOPSIS

	use Perl6::Currying;

	sub add ($a,$b) { $a + $b }	# Define a sub with named params

	print add(1,2);			# Call it

	my $incr = &add.prebind(a=>1);	# Bind the $a argument to 1
					# to create an increment subroutine

	print $incr->(3), "\n";		# Increment a number


=head1 DESCRIPTION

The Perl6::Currying module lets you try out the new Perl 6 explicit
higher-order function syntax in Perl 5.

In Perl 6 any subroutine can be "partially bound". That is, you can supply 
some of its arguments and thereby create another subroutine that calls
the original with those arguments automatically supplied.

Subroutine parameters are partially bound by calling the
C<prebind> method on the subroutine. This method call returns a 
reference to a new subroutine that calls the original subroutine,
inserting into its argument list the prebound arguments. For example:

        # Perl 6 code
        sub divide ($numerator, $denominator) {
                return $numerator / $denominator;
        }

        my $halve = &divide.prebind(denominator=>2);

Note that it's necessary to use the C<&> sigil to indicate that the
method C<CODE::prebind> is to be called on a C<CODE> object C<&divide>,
not the C<Whatever::prebind> of the C<Whatever> object returned
by I<calling> C<divide>. To get the latter, we would write:

	divide().prebind(...)

or:

	divide.prebind(...)

Having prebound the denominator, if we now call the subroutine referred
to by C<$halve> the effect is to call C<divide> with an automagically 
supplied denominator of 2. That is:

        # Perl 6 code
        print divide(42,2);     # calls &divide...prints 21
        print $halve(42);       # calls &divide...prints 21 

It's also possible to prebind I<all> the arguments of a subroutine, either
all at once:

        # Perl 6 code
        my $pi_approx = &divide.prebind(numerator=>22,denominator=>7);

        print $pi_approx();	# prints 3.14285714285714

or in stages:

        # Perl 6 code
        my $pi_legislated = $halve.prebind(numerator=>6);

        print $pi_legislated();	# prints 3

Note that we I<didn't> need the C<&> sigil before C<$halve> since this
syntax is unambiguously a call (through a reference to a C<CODE> object)
to C<CODE::prebind>.

You can also use the Perl 6 aliasing operator (C<:=>) to create new named 
subroutines by partially binding existing ones. For example:

	# Perl 6 code
	
	&reciprocal := &divide.prebind(numerator=>1);

	print reciprocal(10)	# prints 0.1


=head2 Parameter binding in Perl 5

The Perl6::Currying module allows you to use the same syntax in Perl 5.

That is, you can supply some of the arguments to a (specially prototyped)
Perl 5 subroutine and thereby create another subroutine that calls
the original with those arguments automatically supplied.

The new subroutine is created by calling the C<prebind> method on the
original subroutine. For example:

        # Perl 5 code
	use Perl6::Currying;

        sub divide ($numerator, $denominator) {
                return $numerator / $denominator;
        }

        my $halve = &divide.prebind(denominator=>2);

Notes:

=over

=item 1.

As the above example implies, Perl6::Currying gives you the (limited)
ability to declare Perl 5 subroutines with named parameters.  Currently 
those parameters must be a list of comma-separated scalars, as shown
above. Each parameter becomes a lexical scalar variable within the
body of the subroutine.

=item 2.

For forward compatibility, to prebind parameters in Perl 5,
the Perl 6 method call syntax
(C<$objref.methodname(...)>) is used, rather than the
Perl 5 syntax (C<$objref-E<gt>methodname(...)>).

=item 3.

To be consistent with Perl 6, it's still
necessary to use the C<&> sigil to indicate that the method to be called
is C<CODE::prebind>, not the C<prebind> of the object returned by
calling C<divide>.

=back

Having prebound the denominator, if we now call the subroutine referred
to by C<$halve> the effect is to call C<divide> with an automagically
supplied denominator of 2. That is:

        # Perl 5 code
        print divide(42,2);     # calls &divide...prints 21
        print $halve->(42);     # calls &divide...prints 21

Note that since these are just normal Perl 5 subroutine calls, the
Perl 5 call-through-reference syntax (C<$subref-E<gt>(...)>) is used,
rather than the Perl 6 syntax (C<$subref.(...)>).

It's also possible to prebind I<all> the arguments of a subroutine, either
all at once:

        # Perl 5 code
	use Perl6::Currying;

        my $pi_approx = &divide.prebind(numerator=>22,denominator=>7);

        print $pi_approx->();	# prints 3.14285714285714

or in stages:

        # Perl 5 code
	use Perl6::Currying;

        my $pi_legislated = $halve.prebind(numerator=>6);

        print $pi_legislated();	# prints 3

You can also use Perl 5 typeglobs to create new named 
subroutines by partially binding existing ones. For example:

	# Perl 5 code
	
	*reciprocal = &divide.prebind(numerator=>1);

	print reciprocal(10)	# prints 0.1




=head1 REFERENCES

A quick introduction:
http://www.tunes.org/~iepos/introduction-to-logic/chap00/sect00.html

Definition of currying: http://www.cs.nott.ac.uk/~gmh//faq.html#currying

Implementation in Haskell: http://www.haskell.org/tutorial/functions.html


=head1 DEPENDENCIES AND INTERACTION

The module is implemented using Filter::Simple
and requires that module to be installed.

This module can be used in conjunction with the Perl6::Placeholders
module. For example:

	use Perl6::Currying;
	use Perl6::Placeholders;

	$add = { $^a + $^b };

	my $incr = $add.prebind(b=>1);

	print $incr->(7), "\n";

	my $div =  { $^x / $^y };

	print $div->(22,7), "\n";

	my $half_of = &$div.prebind(y=>2);
	my $reciprocal = $div.prebind(x=>1);

	print $half_of->(7), "\n";
	print $reciprocal->(7), "\n";

When using both modules, this module must be loaded first.


=head1 DIAGNOSTICS

=over

=item C<Odd list of bindings for prebind>

C<prebind> expects a list of C<parameter_name =E<gt> value> pairs
as its arguments. Instead it detected a non-even number of arguments.

=item C<Can't prebind sub with prototype (%s)> 

Currently the module only supports scalar named parameters.
It has detected an attempt to bind a subroutine that has some 
other type of parameter specified.

=item C<Can't prebind nonexistent parameter %s of sub(%s)>

You can only bind parameters that were actually declared in
the subroutine's prototype.

=item C<Perl6::Placeholders should not be loaded before Perl6::Currying>

When using both modules, Perl6::Placeholders should be loaded 
after Perl6::Currying.

=back


=head1 AUTHOR

Damian Conway (damian@conway.org)

=head1 BUGS

This module is not designed for serious implementation work.

It uses some relatively sophisticated heuristics to translate Perl 6
syntax back to Perl 5. It I<will> make mistakes if your code gets even
moderately tricky.

Nevertheless, bug reports are most welcome.

=head1 COPYRIGHT

Copyright (c) 2002, Damian Conway. All Rights Reserved.
This module is free software. It may be used, redistributed
and/or modified under the terms of the Perl Artistic License
  (see http://www.perl.com/perl/misc/Artistic.html)
