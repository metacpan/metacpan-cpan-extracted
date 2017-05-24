#
# This file is part of MooseX-Attribute-Dependent
#
# This software is Copyright (c) 2017 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::Dependent::Meta::Role::Composite;
$MooseX::Attribute::Dependent::Meta::Role::Composite::VERSION = '1.1.4';
use Moose::Role;

around apply_params => sub {
    my $orig = shift;
    my $self = shift;

    $self->$orig(@_);

    $self = Moose::Util::MetaRole::apply_metaroles(
        for            => $self,
        role_metaroles => {
            application_to_class => ['MooseX::Attribute::Dependent::Meta::Role::ApplicationToClass'],
            application_to_role => ['MooseX::Attribute::Dependent::Meta::Role::ApplicationToRole'],
        },
    );

    return $self;
};

no Moose::Role;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Attribute::Dependent::Meta::Role::Composite

=head1 VERSION

version 1.1.4

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
