use 5.008;
use strict;
use warnings;

package Role::Commons;

use Carp qw[ carp croak ];
use Module::Runtime qw[ use_package_optimistically ];
use Moo::Role qw[];
use Types::TypeTiny qw[ HashLike ArrayLike ];

BEGIN {
	$Role::Commons::AUTHORITY = 'cpan:TOBYINK';
	$Role::Commons::VERSION   = '0.104';
}

my @ALL = qw(
	Authority
	ObjectID
	Tap
);

sub parse_arguments
{
	my $class = shift;
	
	# Translate "-all".
	my $all = 0;
	my @args = grep { /^\-all$/i ? do { $all++; 0 } : 1 } @_;
	unshift @args, @ALL if $all;
	
	my %roles;
	my %options;
	while (my $name = shift @args)
	{
		my $details;
		if ($name =~ /^-/ or ref $args[0])
			{ $details = shift @args }
		
		if ($name =~ /^\-(.+)$/i)
			{ $options{ lc $1 } = $details }
		else
			{ $roles{ $name } = $details }
	}
	
	carp "Role::Commons - no roles specified"
		if keys %options && !keys %roles;
	
	return(\%roles, \%options);
}

sub import
{
	my $class  = shift;
	my ($roles, $options) = $class->parse_arguments(@_);
	$options->{into} = caller unless exists $options->{into};
	
	foreach my $role (sort keys %$roles)
	{
		use_package_optimistically( join q[::], $class, $role );
	}
	
	'Moo::Role'->apply_roles_to_package(
		$options->{into},
		map { join q[::], $class, $_ } sort keys %$roles,
	);
	
	foreach my $role (sort keys %$roles)
	{
		my $role_pkg = join q[::], $class, $role;
		my $details  = $roles->{$role};
		my $setup_method = do {
			no strict 'refs';
			${"$role_pkg\::setup_for_class"};
		} or next;
		$role_pkg->$setup_method(
			$options->{into},
			HashLike->check($details)
				? %$details
				: ( ArrayLike->check($details) ? @$details : (option => $details) ),
		);
	}
}

sub apply_roles_to_object
{
	my $class  = shift unless blessed($_[0]);
	my $object = shift;
	my ($roles, $options) = $class->parse_arguments(@_);
	
	foreach my $role (sort keys %$roles)
	{
		use_package_optimistically( join q[::], $class, $role );
	}
	
	'Moo::Role'->apply_roles_to_object(
		$object,
		map { join q[::], $class, $_ } sort keys %$roles,
	);
	
	foreach my $role (sort keys %$roles)
	{
		my $role_pkg = join q[::], $class, $role;
		my $details  = $roles->{$role};
		my $setup_method = do {
			no strict 'refs';
			${"$role_pkg\::setup_for_class"};
		} || sub { 0 };
		$role_pkg->$setup_method(
			ref($object),
			HashLike->check($details)
				? %$details
				: ( ArrayLike->check($details) ? @$details : (option => $details) ),
		);
		$setup_method = do {
			no strict 'refs';
			${"$role_pkg\::setup_for_object"};
		} or next;
		$role_pkg->$setup_method(
			$object,
			HashLike->check($details)
				? %$details
				: ( ArrayLike->check($details) ? @$details : (option => $details) ),
		);
	}
}

1;

__END__

=head1 NAME

Role::Commons - roles that can be commonly used, for the mutual benefit of all

=head1 SYNOPSIS

 use 5.010;
 
 {
   package Local::Class;
   use Moo;
   use Role::Commons -all;
   our $AUTHORITY = 'cpan:JOEBLOGGS';
   our $VERSION   = '1.000';
 }
 
 say Local::Class->AUTHORITY
   if Local::Class->DOES('Role::Commons::Authority');
 
 my $obj = Local::Class->new;
 say $obj->object_id
   if $obj->DOES('Role::Commons::ObjectID');

=head1 DESCRIPTION

Role-Commons is not yet another implementation of roles. It is a collection
of generic, reusable roles that hopefully you will love to apply to your
classes. These roles are built using L<Moo::Role>, so automatically
integrate into the L<Moose> object system if you're using it, but they
do not require Moose.

The Role::Commons module itself provides shortcuts for applying roles to
your package, so that instead of doing:

 {
   package Local::Class;
   
   use Moo;  # or "use Moose"
   with qw( Role::Commons::Authority Role::Commons::ObjectID );
 }

You can just do this:

 {
   package Local::Class;
   
   use Moo;
   use Role::Commons qw( Authority ObjectID );
 }

It also handles passing some simple parameters through to the role
from the consuming class. (Because Moo doesn't have anything like
L<MooseX::Role::Parameterized>.)

=begin trustme

Not sure if these should be documented or not...

=item parse_arguments

=item apply_roles_to_object

=end trustme

=head2 Roles

=over

=item L<Role::Commons::Authority>

Sets up a C<AUTHORITY> method for your class which is conceptually a
little like C<VERSION>.

=item L<Role::Commons::ObjectID>

Provides an C<object_id> method for your class which returns a unique
identifier for each object.

=item L<Role::Commons::Tap>

Provides a C<tap> method for your class, inspired by Ruby's method
of the same name. Helpful for writing chained method calls.

=back

=head2 Obsolescence

Role-Commons is the successor for my older projects:
authority-shared,
Object-AUTHORITY,
Object-DOES,
Object-Role, and
Object-Tap.

Role-Commons bundles L<Object::AUTHORITY> for the sake of backwards
compatibility. This is being phased out.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Role-Commons>.

=head1 SEE ALSO

L<Role::Commons::Authority>,
L<Role::Commons::ObjectID>,
L<Role::Commons::Tap>.

L<Role::Tiny>,
L<Moo::Role>,
L<Moose::Role>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012, 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

