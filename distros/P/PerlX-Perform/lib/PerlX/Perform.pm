package PerlX::Perform;

use 5.006;
use strict;

our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS, @ISA);
BEGIN {
	$PerlX::Perform::AUTHORITY = 'cpan:TOBYINK';
	$PerlX::Perform::VERSION   = '0.006';
	
	require Exporter;
	@ISA       = qw/Exporter/;
	@EXPORT    = qw/perform wherever/;
	@EXPORT_OK = qw/perform wherever whenever/;
	%EXPORT_TAGS = (
		default   => \@EXPORT,
		all       => \@EXPORT_OK,
		wherever  => [qw/perform wherever/],
		whenever  => [qw/perform whenever/],
		);
}

sub blessed ($)
{
	my $thing = shift;
	if (ref $thing and UNIVERSAL::can($thing, 'can'))
	{
		return (ref($thing) || $thing || 1);
	}
	return;
}

sub perform (&;$)
{
	my ($coderef, $thing) = @_;
	if (defined $thing)
	{
		$_ = $thing;
		@_ = ();
		goto $coderef;
	}
	if (@_ == 1)
	{
		return PerlX::Perform::Manifesto->new($coderef);
	}
	return;
}

sub wherever ($;@)
{
	my $thing = shift;
	if (@_ and !ref $_[0] and $_[0] eq 'perform')
	{
		shift;
	}
	if (@_ and blessed $_[0] and $_[0]->isa('PerlX::Perform::Manifesto'))
	{
		my $manifesto = shift;
		@_ = ($thing);
		goto $manifesto;
	}
	elsif (@_ and ref $_[0] eq 'CODE')
	{
		my $manifesto = &perform(shift);
		@_ = ($thing);
		goto $manifesto;
	}
	return $thing;
}

*whenever = \&wherever;

package PerlX::Perform::Manifesto;

use 5.006;
use strict;

sub new
{
	my ($class, $code) = @_;
	
	if (PerlX::Perform::blessed $code and $code->isa(__PACKAGE__))
	{
		return $code;
	}
	
	bless sub {
			my $thing = shift;
			return unless defined $thing;
			$_ = $thing;
			@_ = ();
			goto $code;
		}, $class;
}

__FILE__
__END__

=head1 NAME

PerlX::Perform - syntactic sugar for if (defined ...) { ... }

=head1 SYNOPSIS

 my $foo = function_that_might_return_undef();
 perform { say $_ } wherever $foo;
 
 my $bar = function_that_might_return_undef();
 wherever $bar, perform { say $_ };

=head1 DESCRIPTION

Executes some code if a given scalar is defined. Within the code block,
the scalar is available as C<< $_ >>.

Note that there is no comma before C<wherever> here:

 my $foo = function_that_might_return_undef();
 perform { say $_ } wherever $foo;

But there is one before C<perform> here:

 my $bar = function_that_might_return_undef();
 wherever $bar, perform { say $_ };

=head2 Gory Details

The implementation is pure Perl. The closest it gets to trickery is
that the two functions defined by this package use prototypes.

=head3 perform

C<perform> is a function can be called in two ways:

=over 

=item * with a single coderef argument

In this case, C<perform> returns a blessed version of that coderef; a
so-called Manifesto object.

=item * with a coderef argument followed by a scalar

Generates the Manifesto object, and executes the Manifesto on the
scalar, returning the result.

Or rather, it has the effective result of doing the above. But it inlines
the logic from PerlX::Perform::Manifesto.

=back

=head3 wherever

C<wherever> is a function can be called in three ways:

=over 

=item * with a single scalar argument

In this case, C<wherever> passes through the argument unchanged.

=item * with a scalar argument and a Manifesto

In this case, C<wherever> executes the Manifesto with the scalar argument.

=item * with a scalar argument and a coderef

In this case, C<wherever> turns the coderef into a Manifesto and
executes it with the scalar argument.

=back

This means that it's possible to do this:

 my $manifesto = perform { say $_ };
 wherever $foo, $manifesto;
 wherever $bar, $manifesto;

And indeed C<wherever> does allow a little additional syntactic sugar
by skipping over the string "perform" if it is used as the second
parameter. Thus you can write:

 my $manifesto = perform { say $_ };
 wherever $foo, perform => $manifesto;
 wherever $bar, perform => $manifesto;

But because PerlX::Perform::Manifesto passes through any
already-blessed coderefs, this will work too:

 my $manifesto = perform { say $_ };
 wherever $foo, &perform($manifesto);
 wherever $bar, &perform($manifesto);

=head2 Tail Calls

Both C<perform> and C<wherever> make extensive use of C<goto> in order to
conceal their usage on the call stack.

=begin private

=item blessed

=end private

=head2 whenever

This is available as an alias for C<wherever>, but is not exported by default.
You need to request it like:

 use PerlX::Perform qw/perform whenever/;

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=PerlX-Perform>.

=head1 SEE ALSO

L<http://www.modernperlbooks.com/mt/2012/02/a-practical-use-for-macros-in-perl.html>.

L<Scalar::Andand>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

