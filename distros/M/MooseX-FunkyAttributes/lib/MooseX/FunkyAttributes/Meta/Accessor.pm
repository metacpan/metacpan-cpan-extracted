package MooseX::FunkyAttributes::Meta::Accessor;

use 5.008;
use strict;
use warnings;

BEGIN {
	$MooseX::FunkyAttributes::Meta::Accessor::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::FunkyAttributes::Meta::Accessor::VERSION   = '0.003';
}

use Moose;
use namespace::autoclean;

extends qw(Moose::Meta::Method::Accessor);

around _instance_is_inlinable => sub
{
	my $orig = shift;
	my $self = shift;
	my $attr = $self->associated_attribute;
	return $attr->accessor_should_be_inlined
		if $attr->does('MooseX::FunkyAttributes::Role::Attribute');
	$self->$orig(@_);
};

1;

__END__

=head1 NAME

MooseX::FunkyAttributes::Meta::Accessor - shim for inlining

=head1 DESCRIPTION

This is a small subclass of L<Moose::Meta::Method::Accessor> which defers
to the attribute the decision on whether the accessor should be inlined.

This is quite uninteresting.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-FunkyAttributes>.

=head1 SEE ALSO

L<MooseX::FunkyAttributes>, L<Moose::Meta::Method::Accessor>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

