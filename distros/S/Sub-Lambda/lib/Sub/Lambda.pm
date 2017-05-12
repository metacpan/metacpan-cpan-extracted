# (hack) the next line produces an eval that works in *main::* lexical scope:
*Sub::Lambda::evaluate = sub { eval $_[0] };

use strict;

package Sub::Lambda;
use Memoize;

use base qw(Exporter);
our @EXPORT = qw(fn ap);

use vars qw($VERSION);
$VERSION = '0.02';

=head1 NAME

Sub::Lambda - syntactic sugar for lambdas in Perl


=head1 SYNOPSIS

  use Sub::Lambda;

  *plus     = fn a => fn b => '$a + $b';
  my $minus = fn a => fn b => q{ $a - $b };
  *flip     = fn f => fn a => fn b => ap qw(f b a);
  *sum      = fn h => -t => q{ @t ? $h+sum(@t) : ($h || 0) };

  print plus(1)->(2)            . "\n";  # 3  = 1 + 2
  print $minus->(10)->(5)       . "\n";  # 5  = 10 - 5
  print flip($minus)->(10)->(5) . "\n";  # -5 = 5 - 10
  print sum(1,2,3,4)            . "\n";  # 10 = 1+2+3+4

  my $fac = fn f => fn n => q{ ($n<1) ? 1 : $n*$f->($n-1) };

  my $Y   = fn m => ap(
   (fn f => ap m => fn a => ap f => f => a => ()) =>
   (fn f => ap m => fn a => ap f => f => a => ())
  );

  print $Y->($fac)->(5) . "\n";  # 120 = 5!


=head1 DESCRIPTION

This module provides syntactic sugar for lambda abstractions and 
applications. Perl supports lambdas through subroutine 
references. You can write things like the curried addition:

  sub { my ($x) = @_; sub { my ($y) = @_; $x + $y } }

However, this is not very convenient nor readable for more involved lambda
expressions. Contrast this with the sugared syntax for the same function:

  fn x => fn y => q{ $x + $y }

If you would like even more convenience at the expense of somewhat unclear
semantics, check out the experimental L<Sub::Lambda::Filter> module, with
which you could write:

  ( \x -> \y -> {$x+$y} )
   


=head2 METHODS

=over
=cut 

sub _neat ($) { /^\-?[a-zA-Z]\w*$/ }; 
sub _var ($)  { local $_=$_[0]; s/^/\$/; s/^\$\-/@/; $_ }
sub _vars (@) { map {_var $_} grep {_neat $_} @_ }
sub _expr (@) { '(' . (join ',', @_) . ')' }

=item fn(pattern => q{ body })

Models lambda abstraction. In list context, outputs the Perl code for
a lambda with a given pattern and body. In scalar context, returns a 
subroutine reference. This context trick allows the sub to be compiled in a 
one-step B<eval>, which appears to be necessary to make sure Perl 
gets the variable scoping right. Note that this means the end user has 
to make sure that the functions are called in 
a scalar context! When in doubt, use C<scalar()>. 

The basic pattern is just a single variable name; an incrementor can
be written as:
  
  fn(x => '$x + 1')->(1) # =2

Prefixing with a dash captures lists of arguments:

  fn(-x => 'scalar(@x)')->(1,2,3,4,5) #= 5

Multiple arguments are allowed too:

  (fn qw(a b)  => '$a+$b')->(1, 2)          #= 3
  (fn qw(h -t) => '{$h=>[@t]}')->(1,2,3,4)  #= {1 => [2,3,4]}

Currying is possible too:

  (fn a => fn b => '$a+$b')->(1)->(2)       #= 3

Here are some translation examples:

   Scheme                      Perl                                  

   (lambda (x) (f x))          (fn  x => 'f($x)')

   (lambda x (f x))            (fn -x => 'f(\@x)')

   (lambda (x y z) (f x y z))  (fn  x => y => z => q{ f($x,$y,$z) }) 

   (lambda (h . t) (f h t))    (fn  h => -t => q{ f($h, \@t) })      

   ...

   Haskell

   \f -> \a -> \b -> f b a     (fn f=>fn a=>fn b=>q{$f->($b)->($a)})

B<AVOID> nesting in the following way:

   fn a => q{ fn b => '$a+$b' } 

In this example C<$a+$b> will be compiled outside of the lexical scope
where C<a> was defined, hence the function will not work.

=cut

sub fn (@) {
    my $body = pop;
    my $tmpl = _expr _vars @_;
    my $code = qq{sub { my $tmpl = \@_; $body }};
    return wantarray ? $code : evaluate($code);
}


=item ap(@expressions) 

Models application. Applies the given expressions to the left,
as if with Haskell C<foldl1 ($)>. In list context, it generates Perl code,
while in scalar context it B<eval>'s it:

  print ap(qw(a b c)) # ($a)->($b)->(scalar($c));

The expressions can be pieces of Perl code or neat variable names
(C<x> standing for C<$x> and C<-x> for C<@x>).

C<ap> is useful as a shorthand in cases like this:

  fn f => fn a => fn b => q{ $f->($b)->($a) }

Expressed with C<ap> it reads:

  fn f => fn a => fn b => ap qw(f b a)

With B<ap> and parentheses one can write arbitrarily complex
lambda expressions. 

=cut 

sub ap (@) {
    my @args  = map {_neat $_ ? _var $_ : $_} @_;
    $args[-1] = "scalar" . _expr $args[-1];
    my $code  = join "->", map { _expr $_ } @args;
    return wantarray ? $code : evaluate($code);
}

memoize('fn'); # speedup re-compilations

1;

__END__

=back 

=head2 THE Y COMBINATOR

To take a large example, let us write down the applicative-order
Y combinator and a factorial function (for derivation and rationale 
see Richard P. Gabriel's I<The Why of Y>, available online 
L<http://www.dreamsongs.com/NewFiles/WhyOfY.pdf>).

In pseudo-Haskell (Haskell's type system prohibits Y):

  Y = \m -> (\f -> m (\a -> f f a)) (\f -> m (\a -> f f a))

In Perl with B<Sub::Lambda>:

  my $Y = fn m => ap(
   (fn f => ap m => fn a => ap qw(f f a)) =>
   (fn f => ap m => fn a => ap qw(f f a))
  );

In standard Perl (compare with the above):

  my $Y = sub {
      my ($m) = @_;
      ( sub { my ($f) = @_; 
	      $m->(sub { my ($a) = @_;
			 $f->($f)->($a);
		   }) } )->(
        sub { my ($f) = @_; 
	      $m->(sub { my ($a) = @_;
			 $f->($f)->($a); })})};

Factorial function:

 my $fac = fn f => fn n => q{ ($n<1) ? 1 : $n*$f->($n-1) };

Testing it:

 print $Y->($fac)->(5);  # prints 120=5!

=head2 SPEED

To avoid repeated compilations B<fn> is memoized. This
only improves performance where lambdas are constructed repeatedly,
as in loops. The performance gains are modest.

=head1 EXPORT

fn ap

=head1 AUTHOR

Anton Tayanovskyy <anton.tayanovskyy at gmail.com>

=head1 ACKNOWLEDGEMENTS

Big thanks to Eugene Grigoriev <eugene.grigoriev at gmail.com> for his
help, ideas and feedback. 

=head1 COPYRIGHT & LICENSE

Copyright 2008 Anton Tayanovskyy. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Acme::Lambda>, L<Language::Functional>, L<Memoize>


=cut
