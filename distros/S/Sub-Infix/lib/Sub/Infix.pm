use 5.006;
use strict;
use warnings;

package Sub::Infix;

BEGIN {
	$Sub::Infix::AUTHORITY = 'cpan:TOBYINK';
	$Sub::Infix::VERSION   = '0.004';
}

use Exporter ();
our @ISA    = qw( Exporter );
our @EXPORT = qw( infix );

sub infix (&)
{
	my $code = shift;
	sub () { bless +{ code => $code }, "Sub::Infix::PartialApplication" };
}

{
	package Sub::Infix::PartialApplication;
	
	use Carp qw(croak);
	
	BEGIN {
		eval { require Scalar::Util; }
			? 'Scalar::Util'->import(qw/blessed/)
			: eval(q{
				require B;
				sub blessed ($) {
					return undef unless length(ref($_[0]));
					my $b = B::svref_2object($_[0]);
					return undef unless $b->isa('B::PVMG');
					my $s = $b->SvSTASH;
					return $s->isa('B::HV') ? $s->NAME : undef;
				}
			});
	};
	
	use overload
		q(|)   => sub { _apply($_[2] ? @_[1,0] : @_[0,1], "|") },
		q(/)   => sub { _apply($_[2] ? @_[1,0] : @_[0,1], "/") },
		q(<<)  => sub { _apply($_[2] ? @_[1,0] : @_[0,1], "<<") },
		q(>>)  => sub { _apply($_[2] ? @_[1,0] : @_[0,1], ">>") },
		q(&{}) => sub { $_[0]->{code} },
		q("")  => sub { !!1 },
		q(0+)  => sub { !!1 },
		q(bool)=> sub { !!1 },
	;
	
	sub _apply
	{
		my ($left, $right, $op) = @_;
		my $self;
		
		if (blessed $left and $left->isa(__PACKAGE__))
		{
			croak ">>infix<< not supported" if $op eq "<<";
			($self = $left)->{right} = $right;
		}
		elsif (blessed $right and $right->isa(__PACKAGE__))
		{
			croak ">>infix<< not supported" if $op eq ">>";
			($self = $right)->{left} = $left;
		}
		else
		{
			croak "incorrect usage of infix operator";
		}
		
		if (exists $self->{op})
		{
			my $combo = join "infix", sort $op, $self->{op};
			unless ($combo eq '<<infix>>' or $combo eq '/infix/'  or $combo eq '|infix|')
			{
				croak "$combo not supported";
			}
		}
		else
		{
			$self->{op} = $op;
		}
		
		if (exists $self->{left} and exists $self->{right})
		{
			return $self->{code}->($self->{left}, $self->{right});
		}
		
		return $self;
	}
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sub::Infix - create a fake infix operator

=head1 SYNOPSIS

   use Sub::Infix;
   
   # Operator needs to be defined (or imported) at compile time.
   BEGIN { *plus = infix { $_[0] + $_[1] } };
   
   my $five = 2 |plus| 3;

=head1 DESCRIPTION

Sub::Infix creates fake infix operators using overloading. It doesn't
use source filters, or L<Devel::Declare>, or any of that magic. (Though
Devel::Declare isn't magic enough to define infix operators anyway; I
know; I've tried.) It's pure Perl, has no non-core dependencies, and
runs on Perl 5.6.

The price you pay for its simplicity is that you cannot define an
operator that can be used like this:

   my $five = 2 plus 3;

Instead, the operator needs to be wrapped with real Perl operators in
one of three ways:

   my $five = 2 |plus| 3;
   my $five = 2 /plus/ 3;
   my $five = 2 <<plus>> 3;

The advantage of this is that it gives you three different levels of
operator precedence.

You can also call the function a slightly less weird way:

   my $five = plus->(2, 3);

=head2 How does it work?

C<< 2 |plus| 3 >> is parsed by perl as: C<< 2 | ( &plus() | 3 ) >>.

C<< &plus() >> returns an object that overloads the C<< | >> operator;
let's call that C<< $obj >>.

The overloaded C<< $obj | 3 >> operation stashes C<< 3 >> inside
C<< $obj >> noting that the number is the right operand, and returns
C<< $obj >>.

Then C<< 2 | $obj >> is evaluated, stashing C<< 2 >> inside C<< $obj >>
as the left operand. At this point, the object notices that it has both
operands, and calls the coderef from the definition of the operator,
passing it both operands.

=begin trustme

=item infix

=end trustme

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Sub-Infix>.

=head1 SEE ALSO

L<http://code.activestate.com/recipes/384122-infix-operators/>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

