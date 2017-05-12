#
# This file is part of MooseX-Attribute-Deflator
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::LazyInflator::Meta::Role::Role;
{
  $MooseX::Attribute::LazyInflator::Meta::Role::Role::VERSION = '2.2.2';
}
use Moose::Role;

sub composition_class_roles {
    'MooseX::Attribute::LazyInflator::Meta::Role::Composite'
}

no Moose::Role;

1;

__END__
=pod

=head1 NAME

MooseX::Attribute::LazyInflator::Meta::Role::Role

=head1 VERSION

version 2.2.2

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

