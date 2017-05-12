package Pointy::Counter;

use 5.006;
use strict;

our (@EXPORT, @ISA);
BEGIN
{
	require Exporter;
	@ISA    = qw/Exporter/;
	@EXPORT = qw/counter/;
	
	$Pointy::Counter::AUTHORITY = 'cpan:TOBYINK';
	$Pointy::Counter::VERSION   = '0.002';
	
	eval { require Object::AUTHORITY and import Object::AUTHORITY };
}

use overload 
	'--' => sub { my ($self) = @_; $$self++ },
	'>'  => sub { my ($self, $other) = @_; $$self < $other },
	'""' => sub { my ($self) = @_; $$self },
	'+0' => sub { my ($self) = @_; $$self },
	fallback => 1,
	;

sub new
{
	my ($class, $initial) = @_;
	$initial = 0 unless defined $initial;
	bless \$initial, $class;
}

sub counter
{
	__PACKAGE__->new(@_);
}

sub continue
{
	my ($self) = @_;
	--$$self;
}

sub value :lvalue
{
	my ($self) = shift;
	$$self = shift if scalar @_;
	$$self;
}

__FILE__
__END__

=head1 NAME

Pointy::Counter - funny syntax for loops

=head1 SYNOPSIS

  use Pointy::Counter;

  my $i = counter;
  while ($i --> 10)
  {
    say "\$i is $i";
  }
  
  # says $i is 1
  # says $i is 2
  # ...
  # says $i is 10

=head1 DESCRIPTION

Pointy::Counter is a class that provides objects which seem to act like
numbers, but have a special C<< --> >> operator to count up to a particular
value.

OK, confession time... C<< --> >> is not really an operator. It's a
post-increment followed by a greater than sign.

  $i --> 10

is parsed by Perl like:

  ($i--) > 10

Then the Pointy::Counter class overloads C<< -- >> to increment rather than
decrement, and overloads C<< > >> to act as a less-than. If you try to
perform any other maths, it should just act as a normal scalar. In
particular, note that this means that while C<< $i-- >> will do a counter
increment; C<< $i -= 1 >> will act completely differently, decrementing the
counter and restoring it to a normal Perl scalar.

=head2 Constructor

=over

=item C<< Pointy::Counter->new($initial) >>

Creates a new counter, with the initial value (defaults to 0). Note that
the counter will have value C<< $initial >> before the loop starts, but
within the body of the loop, it will be C<< $initial+1 >>, C<< $initial+2 >>,
etc.

=item C<< counter $initial >>

This module exports a function which can be called as a shortcut for the
constructor.

=back

=head2 Methods

=over

=item C<< value >>

Returns current value as a plain old Perl scalar. This is an lvalue
subroutine, so you can, for example, reset a counter using:

 $i->value = 0;

=item C<< continue >>

Really does decrement the counter. This is used to solve a small niggling
problem:

 my $x = counter;	
 while ($x --> 2)
 {
   say "Counter is $x (loop A)";
 }
 while ($x --> 4)
 {
   say "Counter is $x (loop B)";
 }

Will output:

 Counter is 1 (loop A)
 Counter is 2 (loop A)
 Counter is 4 (loop B)

Why doesn't it output a line for when its value is 3? That's because it only
takes the value 3 I<between> the two loops. The solution is to decrement the
counter before starting loop B:

 my $x = counter;	
 while ($x --> 2)
 {
   say "Counter is $x (loop A)";
 }
 $x -> continue;
 while ($x --> 4)
 {
   say "Counter is $x (loop B)";
 }

This gives you:

 Counter is 1 (loop A)
 Counter is 2 (loop A)
 Counter is 3 (loop B)
 Counter is 4 (loop B)

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Pointy-Counter>.

=head1 SEE ALSO

L<overload>, L<perlsyn>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

