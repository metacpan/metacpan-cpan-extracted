package Sub::Lazy;

use 5.008;
use strict;
use warnings;

BEGIN {
	$Sub::Lazy::AUTHORITY = 'cpan:TOBYINK';
	$Sub::Lazy::VERSION   = '0.002';
}

use constant ENABLED => !$ENV{PERL_SUB_LAZY_DISABLE};

use Attribute::Handlers;
use if ENABLED, 'Data::Thunk';

sub UNIVERSAL::Lazy :ATTR(CODE)
{
	if (ENABLED)
	{
		no warnings qw(redefine);
		my ($package, $symbol, $referent, $attr, $data) = @_;
		my %args = @{ $data || [] };
		$$symbol = $args{class}
			? sub {
				my @args = @_;
				Data::Thunk::lazy_object { $referent->(@args) } %args;
			}
			: sub {
				my @args = @_;
				Data::Thunk::lazy { $referent->(@args) };
			};
	}
	1;
}

ENABLED or not ENABLED # that is the question

__END__

=head1 NAME

Sub::Lazy - defer calculating subs until necessary

=head1 SYNOPSIS

   use strict;
   use Test::More;
   use Sub::Lazy;
   
   my $it_happens = 0;
   
   sub double :Lazy {
      $it_happens++;  # side-effect
      
      my $n = shift;
      return $n * 2;
   }
   
   my $eight = double(4);
   
   # The 'double' function hasn't been executed yet.
   is($it_happens, 0);
   
   # The correct answer was calculated.
   is($eight, 8);
   
   # The 'double' function was executed when necessary.
   is($it_happens, 1);
   
   done_testing;

=head1 DESCRIPTION

Sub::Lazy allows you to mark subs as candidates for lazy evaluation.
Good candidates for lazy evaluation:

=over

=item *

Have no side-effects. They don't alter global variables; they don't
make use of any closed-over lexical variables; they don't do IO or
make system calls.

=item *

Are only called in scalar context. This module always imposes a
scalar context on subs. (Of course the sub can return an arrayref.)

=back

The actual work is done by L<Data::Thunk>. Data::Thunk is awesome but
it does have its limitations. It's not completely transparent (if you
try hard enough, you can tell the difference between a value that has
not been calculated yet and one that has) and it will sometimes be
over-eager to calculate a value. But it's probably the best solution
for lazy scalars on CPAN, so I've reused it rather than writing a
half-arsed replacement for it.

This module defines an atttribute (C<< :Lazy >>) to allow you to wrap
a sub with Data::Thunk, making the whole business a little easier.

If your function is known to always return an instance of a particular
class, then you can specify that:

   sub get_manager :Lazy(class=>Person) {
      ...;
   }

Sub::Lazy will then use Data::Thunk's C<lazy_object> feature, which
allows Data::Thunk to further postpone evaluation of the sub in some
cases.

You can even patch in further details about the object you are
returning:

   sub get_manager :Lazy(class=>Person,job_title=>"Manager") {
      ...;
   }

Now C<< get_manager(...)->job_title >> will return C<< "Manager" >>
without needing to evaluate C<get_manager>.

=head1 ENVIRONMENT

Setting the C<PERL_SUB_LAZY_DISABLE> environment variable to true
allows you to disable the effects of this module. Subs will be run
eagerly. This environment variable needs to be set I<prior> to
loading Sub::Lazy. It is a global off switch. 

=over

=item C<< Sub::Lazy::ENABLED >>

Checks the status of the global off switch.

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Sub-Lazy>.

=head1 SEE ALSO

L<Data::Thunk>.

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

