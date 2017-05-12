package MooseX::LvalueAttribute::Trait::Attribute;

our $VERSION   = '0.981';
our $AUTHORITY = 'cpan:TOBYINK';

use Moose::Role;

has lvalue => (
	is        => 'rw',
	isa       => 'Bool',
	predicate => 'has_lvalue',
	trigger   => sub { require Carp; Carp::carp('setting lvalue=>1 on the attribute is deprecated') },
);

around accessor_metaclass => sub
{
	my $next = shift;
	my $self = shift;
	my $metaclass = $self->$next(@_);
	return Moose::Util::with_traits($metaclass, 'MooseX::LvalueAttribute::Trait::Accessor');
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

MooseX::LvalueAttribute::Trait::Attribute - internals for MooseX::LvalueAttribute

=head1 DESCRIPTION

This attribute trait applies the L<MooseX::LvalueAttribute::Trait::Accessor>
trait to your attribute's accessors.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-LvalueAttribute>.

=head1 SEE ALSO

L<MooseX::LvalueAttribute>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Based on work by
Christopher Brown, C<< <cbrown at opendatagroup.com> >>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2013-2014 by Toby Inkster;
2008 by Christopher Brown.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

