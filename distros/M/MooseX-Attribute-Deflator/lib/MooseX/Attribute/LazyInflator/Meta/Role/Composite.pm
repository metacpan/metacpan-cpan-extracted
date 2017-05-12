#
# This file is part of MooseX-Attribute-Deflator
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::LazyInflator::Meta::Role::Composite;
{
  $MooseX::Attribute::LazyInflator::Meta::Role::Composite::VERSION = '2.2.2';
}
use Moose::Role;

around apply_params => sub {
    my $orig = shift;
    my $self = shift;

    $self->$orig(@_);

    $self = Moose::Util::MetaRole::apply_metaroles(
        for            => $self,
        role_metaroles => {
            application_to_class => ['MooseX::Attribute::LazyInflator::Meta::Role::ApplicationToClass'],
            application_to_role => ['MooseX::Attribute::LazyInflator::Meta::Role::ApplicationToRole'],
        },
    );

    return $self;
};


no Moose::Role;

1;

__END__
=pod

=head1 NAME

MooseX::Attribute::LazyInflator::Meta::Role::Composite

=head1 VERSION

version 2.2.2

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

