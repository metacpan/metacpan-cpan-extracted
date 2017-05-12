package MooseX::ABCD::Trait::Class;

use 5.008;
use strict;
use warnings FATAL => qw[ all ];
no warnings qw[ void once uninitialized numeric ];

BEGIN {
	$MooseX::ABCD::Trait::Class::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::ABCD::Trait::Class::VERSION   = '0.003';
};

use Moose::Role;
 
has is_abstract => (
	is      => 'rw',
	isa     => 'Bool',
	default => 0,
);
 
has required_methods => (
	traits     => ['Array'],
	is         => 'ro',
	isa        => 'ArrayRef[Str]',
	default    => sub { [] },
	auto_deref => 1,
	handles    => {
		add_required_method  => 'push',
		has_required_methods => 'count',
	},
);

before make_immutable => sub
{
	my $self = shift;
	return if $self->is_abstract;
	my @supers = $self->linearized_isa;
	shift @supers;
	
	for my $superclass (@supers)
	{
		my $super_meta = Class::MOP::class_of($superclass);
		
		next unless $super_meta->meta->can('does_role')
			&& $super_meta->meta->does_role('MooseX::ABCD::Trait::Class');
		next unless $super_meta->is_abstract;
		
		for my $method ($super_meta->required_methods)
		{
			if (!$self->find_method_by_name($method))
			{
				my $classname = $self->name;
				$self->throw_error(
					"$superclass requires $classname to implement $method"
				);
			}
		}
	}
};
 
around _immutable_options => sub
{
	my $orig = shift;
	my $self = shift;
	my @options = $self->$orig(@_);
	my $constructor = $self->find_method_by_name('new');
	
	if ($self->is_abstract)
	{
		push @options, inline_constructor => 0;
	}
	# we know that the base class has at least our base class role applied,
	# so it's safe to replace it if there is only one wrapper.
	elsif ($constructor->isa('Class::MOP::Method::Wrapped')
	and $constructor->get_original_method == Class::MOP::class_of('Moose::Object')->get_method('new'))
	{
		push @options, replace_constructor => 1;
	}
	# if our parent has been inlined and we are not abstract, then it's
	# safe to inline ourselves
	elsif ($constructor->isa('Moose::Meta::Method::Constructor'))
	{
		push @options, replace_constructor => 1;
	}
	
	return @options;
};
 
no Moose::Role ;;; "Yeah, baby, yeah!"

__END__

=head1 NAME

MooseX::ABCD::Trait::Class - trait for abstract base class meta objects

=head1 DESCRIPTION

This is basically a copy of L<MooseX::ABC::Trait::Class>, but the
C<< after _superclasses_updated >> method modifier is replaced by a
C<< before make_immutable >> modifier.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-ABCD>.

=head1 SEE ALSO

L<MooseX::ABCD>, L<MooseX::ABC::Trait::Class>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>, though most of the code is stolen
from Jesse Luehrs. (But don't blame him is something goes wrong. For that
matter, don't blame me either - take a look at the disclaimer of warranties.)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

