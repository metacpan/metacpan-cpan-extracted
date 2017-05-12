package MooseX::RoleFor::Meta::Role::Trait::RoleFor;

use 5.010;
use strict;
use utf8;

BEGIN
{
	$MooseX::RoleFor::Meta::Role::Trait::RoleFor::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::RoleFor::Meta::Role::Trait::RoleFor::VERSION   = '0.003';
}

use Moose::Role;
use Moose::Util::TypeConstraints;
use Carp qw[croak carp];
use Scalar::Util qw[blessed];
use namespace::autoclean;

has role_is_for => (
	is      => 'rw',
	isa     => 'Undef|Str|ArrayRef[Str]',
);

has role_misapplication_consequence => (
	is      => 'rw',
	isa     => enum([qw/croak carp/]),
	default => 'carp',
);

before apply => sub
{
	my ($meta, $thing, @options) = @_;

	my $applying_to = $thing;
	if ($applying_to->isa('Moose::Meta::Class'))
	{
		$applying_to = $thing->name;
	}
	
	my @targets;
	@targets = ref $meta->role_is_for
		? @{$meta->role_is_for}
		: ($meta->role_is_for)
		if defined $meta->role_is_for;
	
	return unless @targets;
	
	my $compliance = 0;
	TARGET: foreach (@targets)
	{
		if ($applying_to->DOES($_))
		{
			$compliance = 1;
			last TARGET;
		}
	}
	
	return if $compliance;
	
	my $message = sprintf(
		"Role '%s' must only be applied to classes %s (not '%s')",
		$meta->name,
		(join '|', map {"'$_'"} @targets),
		(ref $applying_to || $applying_to),
	);
	
	foreach (keys %INC)
	{
		s{\.pm$}{};
		s{[/\\]}{::}g;
		$Carp::Internal{$_}++ if /^(?:Class::MOP|Moose|MooseX)\b/
	}
	
	$meta->role_misapplication_consequence eq 'croak'
		? croak($message)
		: carp($message);
	
	foreach (keys %INC)
	{
		s{\.pm$}{};
		s{[/\\]}{::}g;
		$Carp::Internal{$_}-- if /^(?:Class::MOP|Moose|MooseX)\b/
	}
};

'Yay!';

__END__

=head1 NAME

MooseX::RoleFor::Meta::Role::Trait::RoleFor - Moose::Meta::Role trait

=head1 DESCRIPTION

This trait provides two attributes:

=over

=item C<< role_is_for >>

An arrayref of class names, or a single class name as a string,
or undef. Indicates which classes this role may be composed
with. (Actually these may be classes B<< or roles >>!)

=item C<< role_misapplication_consequence >>

Either "croak" or "carp" (the default). Indicates the
consequences of applying the role to the wrong class.

=back

This trait hooks onto the C<apply> method to enforce the
consequences.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-RoleFor>.

=head1 SEE ALSO

L<MooseX::RoleFor>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011-2012 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

