package MooseX::MultiInitArg::Attribute;
use Moose;

extends q(Moose::Meta::Attribute);
with q(MooseX::MultiInitArg::Trait);

no Moose;

package # Move along, PAUSE...
	Moose::Meta::Attribute::Custom::MultiInitArg;

sub register_implementation { q(MooseX::MultiInitArg::Attribute) }

1;

__END__

=pod

=head1 NAME

MooseX::MultiInitArg::Attribute - A custom attribute metaclass to add multiple init arguments to your attributes.

=head1 DESCRIPTION

This is a custom attribute metaclass which you can add to an attribute so that 
you can specify a list of aliases for your attribute to be recognized as 
constructor arguments.  Use L<MooseX::MultiInitArg::Trait> for a way to use
this with other attribute modifiers.

=head1 AUTHOR

Paul Driver, C<< <frodwith at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2008 by Paul Driver.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

