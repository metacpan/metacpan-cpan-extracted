use 5.008;
use strict;
use warnings;

package Return::Type;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.005';

use Attribute::Handlers;
use Eval::TypeTiny qw( eval_closure );
use Sub::Util qw( subname set_subname );
use Types::Standard qw( Any ArrayRef HashRef Int );
use Types::TypeTiny qw( to_TypeTiny );

sub _inline_type_check
{
	my $class = shift;
	my ($type, $var, $env, $suffix) = @_;
	
	return $type->inline_assert($var) if $type->can_be_inlined;
	
	$env->{'$type_'.$suffix} = \$type;
	return sprintf('$type_%s->assert_return(%s);', $suffix, $var);
}

sub _inline_type_coerce_and_check
{
	my $class = shift;
	my ($type, $var, $env, $suffix) = @_;
	
	my $coerce = '';
	if ($type->has_coercion and $type->coercion->can_be_inlined)
	{
		$coerce = sprintf('%s = %s;', $var, $type->coercion->inline_coercion($var));
	}
	elsif ($type->has_coercion)
	{
		$env->{'$coercion_'.$suffix} = \( $type->coercion );
		$coerce = sprintf('%s = $coercion_%s->coerce(%s);', $var, $suffix, $var);
	}
	
	return $coerce . $class->_inline_type_check(@_);
}

sub wrap_sub
{
	my $class = shift;
	my $sub   = $_[0];
	local %_  = @_[ 1 .. $#_ ];
	
	$_{$_}     &&= to_TypeTiny($_{$_}) for qw( list scalar );
	$_{scalar} ||= Any;
	$_{list}   ||= ($_{scalar} == Any ? Any : ArrayRef[$_{scalar}]);
	
	my $prototype = prototype($sub);
	$prototype = defined($prototype) ? "($prototype)" : "";
	
	my %env  = ( '$sub' => \$sub );
	my @src  = sprintf('sub %s { my $wa = wantarray;', $prototype);
	my $call = '$sub->(@_)';
	
	if ($_{scope_upper})
	{
		require Scope::Upper;
		$call = '&Scope::Upper::uplevel($sub => (@_) => &Scope::Upper::SUB(&Scope::Upper::SUB))';
	}
	
	exists($_{$_}) || ($_{$_} = $_{coerce}) for qw( coerce_list coerce_scalar );
	my $inline_list   = $_{coerce_list}   ? '_inline_type_coerce_and_check' : '_inline_type_check';
	my $inline_scalar = $_{coerce_scalar} ? '_inline_type_coerce_and_check' : '_inline_type_check';
		
	# List context
	push @src, 'if ($wa) {';
	if ( $_{list}->is_a_type_of(HashRef) )
	{
		push @src, 'my $rv = do { use warnings FATAL => qw(misc); +{' . $call . '} };';
		push @src, $class->$inline_list($_{list}, '$rv', \%env, 'l');
		push @src, 'return %$rv;';
	}
	else
	{
		push @src, 'my $rv = [' . $call . '];';
		push @src, $class->$inline_list($_{list}, '$rv', \%env, 'l');
		push @src, 'return @$rv;';
	}
	push @src, '}';
	
	# Scalar context
	push @src, 'elsif (defined $wa) {';
	push @src, 'my $rv = ' . $call . ';';
	push @src, $class->$inline_scalar($_{scalar}, '$rv', \%env, 's');
	push @src, 'return $rv;';
	push @src, '}';
	
	# Void context - cannot request a value to check, so check must be skipped
	push @src, "$call;";
	
	push @src, '}';
	
	my $rv = eval_closure(
		source       => \@src,
		environment  => \%env,
	);
	return set_subname(subname($sub), $rv);
}

sub UNIVERSAL::ReturnType :ATTR(CODE)
{
	my ($package, $symbol, $referent, $attr, $data) = @_;
	
	no warnings qw(redefine);
	my %args = (@$data % 2) ? (scalar => @$data) : @$data;
	*$symbol = __PACKAGE__->wrap_sub($referent, %args);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Return::Type - specify a return type for a function (optionally with coercion)

=head1 SYNOPSIS

   use Return::Type;
   use Types::Standard qw(Int);
   
   sub first_item :ReturnType(Int) {
      return $_[0];
   }
   
   my $answer = first_item(42, 43, 44);     # returns 42
   my $pie    = first_item(3.141592);       # throws an error!

=head1 DESCRIPTION

Return::Type allows you to specify a return type for your subs. Type
constraints from any L<Type::Tiny>, L<MooseX::Types> or L<MouseX::Types>
type library are supported.

The simple syntax for specifying a type constraint is shown in the
L</SYNOPSIS>. If the attribute is passed a single type constraint as shown,
this will be applied to the return value if called in scalar context, and
to each item in the returned list if called in list context. (If the sub
is called in void context, type constraints are simply ignored.)

It is possible to specify different type constraints for scalar and
list context:

   sub foo :ReturnType(scalar => Int, list => HashRef[Num]) {
      if (wantarray) {
         return (pie => 3.141592);
      }
      else {
         return 42;
      }
   }

Note that because type constraint libraries are really aimed at
validating scalars, the type constraint for the list is specified as
a I<hashref> of numbers and not a hash of numbers! For the purposes
of validation against the type constraint, we slurp the returned list
into a temporary arrayref or hashref.

For type constraints with coercions, you can also pass the option
C<< coerce => 1 >>:

   use Return::Type;
   use Types::Standard qw( Int Num );
   
   # Define a subtype of "Int" at compile time, which can
   # coerce from "Num" by rounding to nearest integer.
   use constant Rounded => Int->plus_coercions(Num, sub { int($_) });
   
   sub first_item :ReturnType(scalar => Rounded, coerce => 1) {
      return $_[0];
   }
   
   my $answer = first_item(42, 43, 44);     # returns 42
   my $pie    = first_item(3.141592);       # returns 3

The options C<coerce_scalar> and C<coerce_list> are also available if
you wish to enable coercion only in particular contexts.

=head2 Power-user Inferface

Rather than using the C<< :ReturnType >> attribute, it's possible to
wrap a coderef like this:

   my $wrapped = Return::Type->wrap_sub($orig, %options);

The accepted options are C<scalar>, C<list>, C<coerce>, C<coerce_list>,
and C<coerce_scalar>, as per the attribute-based interface.

There is an additional option C<scope_upper> which will load and use
L<Scope::Upper> so that things like C<caller> used within the wrapped
sub are unaware of being wrapped. This behaviour was the default
prior to Return::Type 0.004, but is now optional and disabled by
default.

=begin trustme

=item wrap_sub

=end trustme

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Return-Type>.

=head1 SUPPORT

B<< IRC: >> support is available through in the I<< #moops >> channel
on L<irc.perl.org|http://www.irc.perl.org/channels.html>.

=head1 SEE ALSO

L<Attribute::Contract>,
L<Sub::Filter>,
L<Sub::Contract>.

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

