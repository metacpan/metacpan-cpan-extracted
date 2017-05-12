package PerlX::ArraySkip;

my $_cpants = q/
use strict;
use warnings;
#/;

BEGIN {
	$PerlX::ArraySkip::AUTHORITY = 'cpan:TOBYINK';
	$PerlX::ArraySkip::VERSION   = '0.004';
}

sub import
{
	my $class  = shift;
	my $caller = caller;
	@_ = qw(arrayskip) unless @_;
	
	my $code = __PACKAGE__->can("arrayskip");
	
	#no strict 'refs';
	foreach my $func (@_)
	{
		*{"$caller\::$func"} = $code;
	}
}

unless (($ENV{PERLX_ARRAYSKIP_IMPLEMENTATION}||'') =~ /pp/i)
{
	eval q{ use PerlX::ArraySkip::XS 0.002 qw(arrayskip) };
}

__PACKAGE__->can('arrayskip') ? eval <<'END_XS' : eval <<'END_PP';

sub IMPLEMENTATION () { "XS" }

END_XS

sub IMPLEMENTATION () { "PP" }

sub arrayskip (@) { shift; @_ }

END_PP

1;

__END__

=head1 NAME

PerlX::ArraySkip - sub { shift; @_ }

=head1 SYNOPSIS

	use PerlX::ArraySkip qw(skip);
	
	my @list = (
		'a',
		skip 'b',
		'c',
		skip 'd',
		'e',
	);
	
	print join '', @list;   # prints 'ace'

=head1 DESCRIPTION

The C<arrayskip> function returns the entire list it was passed as arguments,
except the first. This is an entirely trivial function and can be written as:

	sub arrayskip { shift; @_ }

The principle of TIMTOWTDI says that there are other ways of skipping the
first item in an array, but according to my benchmarking this performs best.

A good question is: why would you want to do this? Well, in Perl there are
two common function calling patterns, named parameters:

	give(
		giver     => $alice,
		recipient => $bob,
		gift      => $dinosaur,
	);

and positional parameters:

	give($alice, $bob, $dinosaur);

Positional parameters look fine when you've got one or two arguments, but
can start looking unwieldly with four or more. Let's imagine that our
C<give> function takes a hypothetical fourth parameter, a boolean indicating
whether the gift had wrapping paper on:

	give($alice, $bob, $dinosaur, 1);

When we come back to that line a few weeks, we might be confused about
what it means. Is Bob giving Alice to the dinosaur once? The C<arrayskip>
function allows you to add extra items into the parameter list which will
be skipped over, and can thus act as comments:

	give(
		arrayskip 'giver',     $alice,
		arrayskip 'recipient', $bob,
		arrayskip 'gift',      $dinosaur,
		arrayskip 'wrapped',   1,
	);

Now let's use a couple of tricks to make it even clearer. Firstly,
PerlX::ArraySkip allows you to import the C<arrayskip> function with your
choice of name. You can call it something more suitable to your use case,
such as C<arg>. Secondly, the fat comma.

	use PerlX::ArraySkip 'arg';
	
	give(
		arg giver     => $alice,
		arg recipient => $bob,
		arg gift      => $dinosaur,
		arg wrapped   => 1,
	);

While the arguments are still positional (you can't change their order) they
now have the appearance of named arguments, improving their readability, and
the code's ease of maintenance.

So, why should you use PerlX::ArraySkip instead of defining your own
C<arrayskip> function? No reason at all. You can define your own function
in fewer keystrokes than loading this module. Observe:

	use PerlX::ArraySkip 'skip';
	sub skip { shift; @_ }

This module, while it does provide an implementation, is mostly just a place
to document the pattern. You could define your own function and include a
reference to this module as a comment:

	sub arg { shift; @_ } # see PerlX::ArraySkip

=begin trustme

=item C<arrayskip>

=end trustme

=head2 XS Backend

If you install L<PerlX::ArraySkip::XS>, a faster XS-based implementation will
be used instead of the pure Perl function. My basic benchmarking experiments
seem to show this to be around 55% faster.

Calling C<PerlX::ArraySkip::IMPLEMENTATION> will return "PP" or "XS" to
reveal the implementation currently in use.

=begin trustme

=item C<IMPLEMENTATION>

=end trustme

=head2 Environment

The environment variable C<PERLX_ARRAYSKIP_IMPLEMENTATION> may be set to
C<< "PP" >> to prevent the XS backend from loading.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=PerlX-ArraySkip>.

=head1 SEE ALSO

If you liked this, you might also like L<PerlX::Maybe>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 LICENCE

To the extent possible under law, Toby Inkster has waived all copyright and
related or neighbouring rights to PerlX::ArraySkip. This work is published
from the United Kingdom.

L<http://creativecommons.org/publicdomain/zero/1.0/>.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

