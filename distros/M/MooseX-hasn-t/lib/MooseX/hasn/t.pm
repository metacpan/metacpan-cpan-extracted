package MooseX::hasn::t;

BEGIN {
	$MooseX::hasn::t::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::hasn::t::VERSION   = '0.003';
}

use 5.010;
use strict qw(subs vars);
no warnings;

our @CARP_NOT = qw(Moose::Meta::Method::Overridden);

use Carp qw/croak/;
use Scalar::Util qw/blessed/;

sub hasn::t
{
	my $opts   = ref($_[0]) eq 'HASH' ? shift : {};
	my ($symbol, %args) = @_;
	my $caller = $opts->{caller} || caller;
	
	if (ref $symbol eq 'ARRAY')
	{
		hasn::t({caller=>$caller}, $_, %args) for @$symbol;
		return;
	}
	
	my $ERROR = q(Can't locate object method "%s" via package "%s");
	
	my @subs;
	if (my $attr = $caller->meta->find_attribute_by_name($symbol))
	{
		foreach my $role (qw(accessor reader writer predicate clearer initializer))
		{
			my $sub = $attr->$role;
			push @subs, $sub if defined $sub && !ref $sub;
		}
		
		if ($attr->is_required and $attr->has_default)
		{
			# OK
		}
		elsif ($attr->is_required and exists $args{default})
		{
			my $init_arg = $attr->init_arg || $symbol;
			
			unless ($caller->can('BUILDARGS'))
			{
				*{"$caller\::BUILDARGS"} = sub { shift; @_ };
			}
			
			$caller->meta->add_around_method_modifier(BUILDARGS => sub
			{
				my ($orig, $class, @args) = @_;
				my $d = ref $args{default} eq 'CODE' ? $args{default}->() : $args{default};
				if (@args==1 and ref $args[0] eq 'HASH')
				{
					$args[0]{$init_arg} //= $d;
				}
				else
				{
					push @args, $init_arg, $d;
				}
				
				$class->$orig(@args);
			});
		}
		elsif ($attr->is_required)
		{
			croak "can't \"hasn't $symbol\", because $symbol is required and has no default";
		}
	}
	else
	{
		@subs = $symbol;
	}
	
	foreach my $sub (@subs)
	{
		$caller->meta->add_override_method_modifier($sub => sub
		{
			my ($invocant, @args) = @_;
			croak sprintf($ERROR, $sub, (blessed $invocant or $caller));
		});
 	}
	
	my $can = $caller->can('can');
	*{"$caller\::can"} = sub {
		my ($invocant, $m) = @_;
		return if $m ~~ [@subs];
		goto $can;
	}
}

__PACKAGE__
__END__

=head1 NAME

MooseX::hasn't - syntactic sugar to complement "has"

=head1 SYNOPSIS

 {
   package Person;
   use Moose;
   has name => (is => "ro", writer => "_rename", required => 1);
 }
 
 {
   package AnonymousPerson;
   use Moose;
   use MooseX::hasn't;
   extends "Person";
   hasn't name => ();
 }
 
 my $dude  = AnonymousPerson->new;
 say($dude->can('_rename') ? 'true' : 'false');  # false
 say($dude->name);                               # croaks

=head1 DESCRIPTION

C<< hasn't >> is a counter-part for Moose's C<< has >>.

It tries to stop a child class inheriting something (an attribute or a
method) from its parent class - though it's not always 100% successful.

=head1 FAQ

=head2 Doesn't this break polymorphism?

The idea behind polymorphism is that if I<Bar> inherits from I<Foo>,
then I should be able to use an object of type I<Bar> wherever I'd
normally use I<Foo>.

In particular, if I can do:

 Foo->new()->some_method();

then I should be able to do:

 Bar->new()->some_method();

But if I<Bar> can explicitly indicate that it hasn't got method
C<some_method> then this breaks. So, yes, this module does break
polymorphism.

But observe that it's not especially difficult to break polymorphism
manually:

 {
   package Foo;
   use Moose;
   sub some_method {}
 }
 
 {
   package Bar;
   use Moose;
   extends 'Foo';
   sub some_method { die "some_method not found in package Bar" }
 }

This module just makes it easier and more declarative.

=head2 How exactly is this achieved?

For C<< hasn't $method >>, it simply adds an override method modifier
to the given method that croaks.

For C<< hasn't $attribute >>, it finds the names of the accessor, reader,
writer, clearer, predicate and initializer methods for that attribute
(if any) and overrides them all. 

In both cases, it overrides the class' C<can> method too.

=head2 What about required attributes?

If the parent class has an attribute which is required and has a default,
then you can use C<< hasn't >> in a child class safely.

If the parent class has an attribute which is required but has no default,
then you must explicitly specify a default in the child class:

 hasn't name => (default => 'anon');

This latter technique is probably not foolproof. Defaults may be coderefs,
like in C<has>.

=head1 BUGS AND LIMITATIONS

=over 

=item * C<< hasn't $attr (default => sub {}) >> will execute the coderef
as a function with no arguments, not as a method.

=item * C<< $object->meta >> can still see attributes and methods
which have been "hasn'ted". Some serious Class::MOP fu is needed to
fix this.

=back

Report anything else here:

L<http://rt.cpan.org/Dist/Display.html?Queue=Moose-hasn-t>.

=head1 SEE ALSO

L<Moose>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
