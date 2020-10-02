use 5.008009;
use strict;
use warnings;
use overload ();

package Sub::Operable;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use constant PREFIX_OPS => map split(/ /, $overload::ops{$_}), qw(
	unary
	func
);

use constant INFIX_OPS => map split(/ /, $overload::ops{$_}), qw(
	with_assign
	num_comparison
	3way_comparison
	str_comparison
	binary
	matching
);

'overload'->import(
	(map {
		my $op = $_;
		$op => sub {
			my $next = $_[0]->can('do_prefix_op') or die;
			splice(@_, 1, 0, $op); goto $next;
		}
	} PREFIX_OPS),
	(map {
		my $op = $_;
		$op => sub {
			my $next = $_[0]->can('do_infix_op') or die;
			splice(@_, 1, 0, $op); goto $next;
		}
	} INFIX_OPS),
);

use isa __PACKAGE__;

use Exporter::Shiny qw( isa_Sub_Operable subop );

sub new {
	my ( $class, $coderef ) = ( shift, @_ );
	my $wrapped = $class->build_wrapped_coderef( $coderef );
	bless $wrapped, $class;
}

sub build_wrapped_coderef {
	my ( $class, $orig ) = ( shift, @_ );
	return sub {
		my $has_subops = grep isa_Sub_Operable($_), @_;
		if ( $has_subops ) {
			my @args = @_;
			my $new = sub {
				my @inner_args = @_;
				@_ = ();
				foreach my $arg ( @args ) {
					push @_, isa_Sub_Operable($arg) ? $arg->(@inner_args) : $arg;
				}
				local *_ = \$_[0];
				&$orig;
			};
			return $class->new($new);
		}
		else {
			local *_ = \$_[0];
			&$orig;
		}
	};
}

sub do_infix_op {
	my ( $x, $op, $y, $swap ) = @_;
	my $class = ref($x);
	( $x, $y ) = ( $y, $x ) if $swap;
	
	my $code;
	
	if ( isa_Sub_Operable $x ) {
		if ( isa_Sub_Operable $y ) {
			$code = sprintf( 'sub { $x->(@_) %s $y->(@_) }', $op );
		}
		else {
			$code = sprintf( 'sub { $x->(@_) %s $y }', $op );
		}
	}
	else {
		if ( isa_Sub_Operable $y ) {
			$code = sprintf( 'sub { $x %s $y->(@_) }', $op );
		}
		else {
			$code = sprintf( 'sub { $x %s $y }', $op );
		}
	}
	
	$class->new( scalar eval $code );
}

sub do_prefix_op {
	my ( $x, $op ) = @_;
	my $class = ref($x);
	
	if ( $op eq 'neg' ) {
		$op = '-';
	}
	
	my $code;
	
	if ( isa_Sub_Operable $x ) {
		$code = sprintf( 'sub { %s $x->(@_) }', $op );
	}
	else {
		$code = sprintf( 'sub { %s $x }', $op );
	}
	
	my $coderef = eval $code;
	$class->new( $coderef );
}

sub _generate_subop {
	my ( $class ) = ( shift );
	return sub (&) { $class->new(@_) };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Sub::Operable - apply Perl built-in operators to coderefs

=head1 SYNOPSIS

  use Sub::Operable 'subop';
  
  # f(x) = x²
  #
  my $f = subop { $_ ** 2 };
  
  # f(4) = 4²
  #      = 16
  #
  say $f->(4);   # ==> 16
  
  # g(x) = 2x
  #
  my $g = subop { 2 * $_ };
  
  # h = f + g + 3
  #
  my $h = $f + $g + 3;
  
  # h(10) = f(10) + g(10) + 3
  #       = 10²   + 2(10) + 3
  #       = 100   + 20    + 3
  #       = 123
  #
  say $h->(10);   # ==> 123

=head1 DESCRIPTION

Sub::Operator allows you to define functions and apply operations to the
functions like you can in algebra class.

All the standard built-in binary, string, numeric, and comparison operators
should work fine. Operators like C<< += >> which mutate their operands are
not supported.

Additionally if you call a Sub::Operator-enabled function passing another
Sub::Operator-enabled function as an argument, you get a composed
Sub::Operator-enabled function as the result.

  # Assume $f and $g defined as above.
  
  # m(x) = g( f(x) )
  #
  my $m = $g->( $f );
  
  # m(10) = g( f(10) )
  #       = g( 10² )
  #       = g( 100 )
  #       = 2 * 100
  #       = 200
  #
  say $m->(10);   # ==> 200

=head2 Object-Oriented Constructor

  use Sub::Operable;
  
  my $coderef = 'Sub::Operable'->new(sub { ... });

When the coderefs are called, C<< $_ >> will be an alias of C<< $_[0] >>.

=head2 Shortcut Constructor

  use Sub::Operable qw( subop );
  
  my $coderef = subop { ... };

When the coderefs are called, C<< $_ >> will be an alias of C<< $_[0] >>.

=head2 Utility Function

  use Sub::Operable qw( isa_Sub_Operable );
  
  my $bool = isa_Sub_Operable( $coderef );

=head2 Constants

You can get lists of supported operators:

  use Sub::Operable;
  
  my @prefix = Sub::Operable::PREFIX_OPS;
  my @infix  = Sub::Operable::INFIX_OPS;

=head2 Symbol Table Frickery

You don't have to just deal with coderefs. You can put these functions
into the symbol table.

  use Sub::Operable 'subop';
  
  # f(x) = x²
  #
  *f = subop { $_ ** 2 };
  
  # f(4) = 4²
  #      = 16
  #
  say f(4);   # ==> 16
  
  # g(x) = 2x
  #
  *g = subop { 2 * $_ };
  
  # h = f + g + 3
  #
  *h = \&f + \&g + 3;
  
  # h(10) = f(10) + g(10) + 3
  #       = 10²   + 2(10) + 3
  #       = 100   + 20    + 3
  #       = 123
  #
  say h(10);   # ==> 123

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Sub-Operable>.

=head1 SEE ALSO

L<curry>, I guess?

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2020 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

