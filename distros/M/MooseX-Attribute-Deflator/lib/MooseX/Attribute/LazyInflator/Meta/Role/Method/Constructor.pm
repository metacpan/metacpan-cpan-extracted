#
# This file is part of MooseX-Attribute-Deflator
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::LazyInflator::Meta::Role::Method::Constructor;
{
  $MooseX::Attribute::LazyInflator::Meta::Role::Method::Constructor::VERSION = '2.2.2';
}

# ABSTRACT: Lazy inflate attributes
use Moose::Role;
use strict;
use warnings;

override _generate_type_constraint_check => sub {
    my $self = shift;
    return $self->_generate_skip_coercion_and_constraint($_[0], super);
};

sub _generate_skip_coercion_and_constraint {
    my ($self, $attr, $code) = @_;
    if($attr->does('MooseX::Attribute::LazyInflator::Meta::Role::Attribute')) {
        return '';
    }
    return $code;
}

1;



=pod

=head1 NAME

MooseX::Attribute::LazyInflator::Meta::Role::Method::Constructor - Lazy inflate attributes

=head1 VERSION

version 2.2.2

=head1 METHODS

=over 8

=item override B<_generate_type_constraint_check>

=item B<_generate_skip_coercion_and_constraint>

Type constraint verification is not processed if the
attribute has not been inflated yet.

=back

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

