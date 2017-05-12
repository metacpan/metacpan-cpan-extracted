use 5.016000;
use strict;
use warnings;

package PerlX::Window;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.004';

use Data::Alias;
use Exporter::Shiny (our @EXPORT = qw( window window_pos ));
use Scalar::Util qw( weaken );

BEGIN {
	my $impl;
	$impl ||= eval { require Hash::FieldHash;       'Hash::FieldHash' };
	$impl ||= do   { require Hash::Util::FieldHash; 'Hash::Util::FieldHash' };
	$impl->import('fieldhash');
};

our ($window, @window);

sub _exporter_validate_opts
{
	my $me = shift;
	my ($opts) = @_;
	
	return if ref $opts->{into};
	
	no strict qw(refs);
	*{$opts->{into} . "::window"} = \(my $tmp);
	*{$opts->{into} . "::window"} = [];
	$me->_setup_magic_string(\${$opts->{into} . "::window"});
	$me->_setup_magic_array(\@{$opts->{into} . "::window"});
}

my $scalar_wiz;
sub _setup_magic_string
{
	shift;
	my ($ref) = @_;
	
	if (eval { require Variable::Magic })
	{
		$scalar_wiz = Variable::Magic::wizard(
			get => sub { ${$_[0]} = $window; 1 },
			set => sub { $window = ${$_[0]}; 1 },
		);
		Variable::Magic::cast($ref, $scalar_wiz);
	}
	else
	{
		unless (exists(&PerlX::Window::_TieScalar::TIESCALAR))
		{
			eval q ~
				package #
					PerlX::Window::_TieScalar;
				sub TIESCALAR { my $tmp = undef; bless \$tmp, $_[0] }
				sub FETCH     { $PerlX::Window::window }
				sub STORE     { $PerlX::Window::window = $_[1] }
				1;
			~ or die("Something went horribly wrong: $@");
		}
		tie($$ref, 'PerlX::Window::_TieScalar');
	}
}

sub _setup_magic_array
{
	shift;
	my ($ref) = @_;
	
	unless (exists(&PerlX::Window::_TieArray::TIEARRAY))
	{
		eval q ~
			package #
				PerlX::Window::_TieArray;
			use Carp;
			sub TIEARRAY  { my $tmp = undef; bless \$tmp, $_[0] }
			sub STORE     { $PerlX::Window::window[ $_[1] ] = $_[2] }
			sub FETCH     { $PerlX::Window::window[ $_[1] ] }
			sub FETCHSIZE { scalar @PerlX::Window::window }
			sub STORESIZE { croak("Array has a fixed size") }
			sub EXTEND    { () }
			sub EXISTS    { !!1 }
			sub DELETE    { croak("Array element cannot be deleted") }
			sub CLEAR     { croak("Array has a fixed size") }
			sub PUSH      { croak("Array has a fixed size") }
			sub POP       { croak("Array has a fixed size") }
			sub SHIFT     { croak("Array has a fixed size") }
			sub UNSHIFT   { croak("Array has a fixed size") }
			sub SPLICE    { croak("Array has a fixed size") }
			1;
		~ or die("Something went horribly wrong: $@");
	}
	tie(@$ref, 'PerlX::Window::_TieArray');
}

fieldhash(my %pos);
my $last;

sub window (\[$@]$) :lvalue
{
	my ($ref, $n) = @_;
	
	$pos{$ref} = -1
		unless defined $pos{$ref};
	
	weaken( $last = $ref );
	++$pos{$ref};
	
	ref($ref) eq 'ARRAY'
		? _window_on_array(@_)
		: _window_on_string(@_);
}

sub window_pos (;\[$@]) :lvalue
{
	my ($ref) = @_ ? @_ : ($last);
	$pos{$ref};
}

sub _window_on_array :lvalue
{
	my ($ref, $n) = @_;
	my $pos = $pos{$ref};
	
	if ($pos + $n > scalar(@$ref))
	{
		alias( @window = () );
		$pos{$ref} = undef;
		return;
	}
	
	alias( @window = @{$ref}[$pos .. $pos+$n-1] );
	@window;
}

sub _window_on_string :lvalue
{
	my ($ref, $n) = @_;
	my $pos = $pos{$ref};
	
	if ($pos + $n > length($$ref))
	{
		my $tmp = undef;
		alias( $window = $tmp );
		$pos{$ref} = undef;
		return;
	}
	
	alias( $window = substr($$ref, $pos, $n) );
	$window;
}

1;

__END__

=pod

=encoding utf-8

=for stopwords backporting

=head1 NAME

PerlX::Window - sliding windows on a string or array

=head1 SYNOPSIS

   use feature qw(say);
   use PerlX::Window;
   
   my $string = "Foobar";
   
   while (defined window $string, 3)
   {
      say $window;  # says "Foo"
                    # says "oob"
                    # says "oba"
                    # says "bar"
   }

=head1 DESCRIPTION

This module provides a sliding window over a long string or array.
It exports two functions C<< window >> and C<< window_pos >>, and
two variables C<< $window >> and C<< @window >>.

=over

=item C<< window $string, $length >>

Calling this function returns the current window onto the string,
and increments the stored position. The window returned is an
I<lvalue> which means you can assign to it (like C<substr>).

Once the string has been exhausted, it returns C<undef> (or in
list context, the empty list), and resets the stored position for
the string.

=item C<< window @array, $length >>

Like the string version, but instead of operating on a substring
of a string, operates on a slice of an array.

=item C<< window_pos $string >>

Returns the position of the most recent window onto the string;
a zero-indexed integer.

=item C<< window_pos @array >>

Returns the position of the most recent window onto the array;
a zero-indexed integer.

=item C<< window_pos >>

Called with no arguments, defaults to the string or array from
the most recent call to C<< window >>.

=item C<< $window >>

An alias to the current window onto the string that has most
recently had C<< window >> called upon it.

C<< $window >> is implemented using L<Variable::Magic> if
installed, and a L<tie|perltie> otherwise.

=item C<< @window >>

An alias to the current window onto the array that has most
recently had C<< window >> called upon it.

You may not assign to this in list context, nor perform C<pop>,
C<push>, C<shift>, C<unshift>, or C<slice> operations on it,
nor any other operation that would change the length of the
array. You may however assign to indexes within the array:

   $window[0] = "Fee" if $window[0] eq "Foo";

C<< @window >> is implemented using a L<tie|perltie>.

=back

=head1 CAVEATS

C<< window >> is L<prototyped|perlsub/"Prototypes"> C<< (\[$@]$) >>
which means that the first argument must be a literal scalar or
array variable, and C<< window >> will actually fetch a reference
to that variable. This means the following are not the same:

   my $tmp = "Foobar";
   say $window
      while window $tmp, 3;

   say $window
      while window my $tmp = "Foobar", 3;

The second example says "Foo" infinitely because C<$tmp> is
redefined in each loop, so is a separate variable as far as
C<window> is concerned.

This module currently requires Perl 5.16, though I believe that
backporting it to Perl 5.8 is feasible.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=PerlX-Window>.

=head1 SEE ALSO

L<Data::Iterator::SlidingWindow>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

