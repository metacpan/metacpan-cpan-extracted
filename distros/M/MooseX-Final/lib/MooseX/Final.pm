use 5.008;
use strict;
use warnings;

package MooseX::Final;

use Exporter::Tiny ();

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';
our @ISA       = qw(Exporter::Tiny);
our @EXPORT    = qw(assert_final);

sub _generate_assert_final {
	my $me = shift;
	my ($name, $args, $globals) = @_;
	
	my $final_package = exists($args->{package})
		? $args->{package}
		: $globals->{into};
	die "cannot bless things into references"
		if ref $final_package;
	
	return sub {
		my $class = ref shift;
		return if $class eq $final_package;
		
		require Carp;
		our @CARP_NOT = ($final_package);
		Carp::croak(sprintf '%s is final; %s should not inherit from it', $final_package, $class);
	};
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::Final - mark a class as "final" (cannot be inherited from)

=head1 SYNOPSIS

 package Example::Phone {
   use Moose;
   use MooseX::Final;
   has number => (is => 'ro', required => 1);
   sub call { ... }
   sub BUILD {
     assert_final( my $self = shift );
     ...;   # do other stuff here if required
   }
 }
 
 package Example::Phone::Mobile {
   use Moose;
   extends "Example::Phone";
   sub send_sms { ... }
 }
 
 my $friend = Example::Phone::Mobile->new(number => 123);  # dies

=head1 DESCRIPTION

This package allows you to mark a class as being "final". A final class
is at the top of the inheritance hierarchy. It cannot be inherited from.
You almost certainly don't want this. Why prevent people from inheriting
from your class? There's no good reason.

Nevertheless, if you have a bad reason, you can use this module to do it.
Despite the name, this module should work fine with L<Moose>, L<Moo>,
L<Mouse>, L<Class::Tiny>, and any other class builder that properly
supports the concept of C<BUILD> methods.

This is not 100% foolproof. Subclasses can probably work around it
without a massive amount of difficulty. But if you're trying to subclass
a class that has indicated it should be final, perhaps you should think
of another way of achieving your aims. (Hint: delegation.)

Note that the exception is thrown when you try to I<instantiate> the
subclass, not when you try to define the subclass.

=head2 Functions

=over

=item C<< assert_final($object) >>

Dies if C<< $object >> isn't an instance of the calling class, and does
not respect inheritance when checking.

Call this in your C<BUILD> method.

(Technically, this doesn't check C<caller>, but instead figures out which
class to be testing against at C<import> time.)

=back

=head2 Alternative Invocation Style

The C<BUILD> method in the L</SYNOPSIS> could have been written as:

   sub BUILD {
     &assert_final;
     my $self = shift;
     ...;   # do other stuff here if required
   }

Note the ampersand before the function call and the lack of parentheses
afterwards. This syntax may be less familiar to new Perl users, but is
slightly more efficient because the Perl interpreter can avoid setting
up a new C<< @_ >> array when it calls the function. See L<perlsub> for
details.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-Final>.

=head1 SEE ALSO

L<Moose>, L<Moo>, L<Class::Tiny>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2017-2018 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
