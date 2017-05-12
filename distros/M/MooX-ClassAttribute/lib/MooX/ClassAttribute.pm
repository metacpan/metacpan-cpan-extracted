package MooX::ClassAttribute;

use 5.008;
use strict;
use warnings;

BEGIN {
	$MooX::ClassAttribute::AUTHORITY = 'cpan:TOBYINK';
	$MooX::ClassAttribute::VERSION   = '0.011';
}

use Carp;
use Moo ();
use Moo::Role ();
use MooX::CaptainHook qw( on_application on_inflation is_role );

BEGIN { *ROLE = \%Role::Tiny::INFO }
our %ROLE;
BEGIN { *CLASS = \%Moo::MAKERS }
our %CLASS;
our %ATTRIBUTES;

sub import
{
	my $me     = shift;
	my $target = caller;
	
	my $install_tracked;
	{
		no warnings;
		if ($CLASS{$target})
		{
			$install_tracked = \&Moo::_install_tracked;
		}
		elsif ($ROLE{$target})
		{
			$install_tracked = \&Moo::Role::_install_tracked;
		}
		else
		{
			croak "MooX::ClassAttribute applied to a non-Moo package"
				. "(need: use Moo or use Moo::Role)";
		}
	}

	my $is_role = is_role($target);
	
	$install_tracked->(
		$target, class_has => sub
		{
			my ($proto, %spec) = @_;
			for my $name (ref $proto ? @$proto : $proto)
			{
				my $spec = +{ %spec }; # shallow clone
				$is_role
					? $me->_process_for_role($target, $name, $spec)
					: $me->_class_accessor_maker_for($target)->generate_method($target, $name, $spec);
				push @{$ATTRIBUTES{$target}||=[]}, $name, $spec;
			}
			return;
		},
	);
	
	$me->_setup_inflation($target);
}

sub _process_for_role
{
	my ($me, $target, $name, $spec) = @_;
	on_application {
		my $applied_to = $_;
		$me
			-> _class_accessor_maker_for($applied_to)
			-> generate_method($applied_to, $name, $spec);
	} $target;
	'Moo::Role'->_maybe_reset_handlemoose($target);
}

sub _class_accessor_maker_for
{
	my ($me, $target) = @_;
	$CLASS{$target}{class_accessor} ||= do {
		require Method::Generate::ClassAccessor;
		'Method::Generate::ClassAccessor'->new;
	};
}

sub _setup_inflation
{
	my ($me, $target) = @_;
	on_inflation {
		require MooX::ClassAttribute::HandleMoose;
		$me->_on_inflation($target, @_)
	} $target;
}

1;

__END__

=head1 NAME

MooX::ClassAttribute - declare class attributes Moose-style... but without Moose

=head1 SYNOPSIS

   {
      package Foo;
      use Moo;
      use MooX::ClassAttribute;
      class_has ua => (
         is      => 'rw',
         default => sub { LWP::UserAgent->new },
      );
   }
   
   my $r = Foo->ua->get("http://www.example.com/");

=head1 DESCRIPTION

This module adds support for class attributes to L<Moo>. Class attributes
are attributes whose values are not associated with any particular instance
of the class.

For example, the C<Person> class might have a class attribute "binomial_name";
its value "Homo sapiens" is not associated with any particular individual, but
the class as a whole.

   say Person->binomial_name;   # "Homo sapiens"
   my $bob = Person->new;
   say $bob->binomial_name;     # "Homo sapiens"
   
   my $alice = Person->new;
   $alice->binomial_name("H. sapiens");
   say $bob->binomial_name;     # "H. sapiens"

Class attributes may be defined in roles, however they cannot be called as
methods using the role package name. Instead the role must be composed with
a class; the class attributes will be installed into that class.

This module mostly tries to behave like L<MooseX::ClassAttribute>.

=head1 CAVEATS

=over

=item *

Overriding class attributes and their accessors in subclasses is not yet
supported. The implementation, and expected behaviour hasn't been figured
out yet.

=item *

When Moo classes are inflated to Moose classes, this module will I<attempt>
to load MooseX::ClassAttribute, and use that to provide class attribute
meta objects.

If MooseX::ClassAttribute cannot be loaded, a loud warning will be printed,
and the inflation will fall back to representing class attribute accessors
as plain old class methods.

=item *

This module uses some pretty experimental techniques, especially to handle
inflation. There are probably all sorts of bugs lurking. Don't let that
scare you though; I'm usually pretty quick to fix bugs once they're reported.
;-)

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooX-ClassAttribute>.

See also: L<Method::Generate::ClassAccessor/CAVEATS>.

=head1 SEE ALSO

L<Moo>,
L<MooseX::ClassAttribute>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

