#
# This file is part of MooseX-Attribute-Dependent
#
# This software is Copyright (c) 2016 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::Dependent::Meta::Role::ApplicationToRole;
$MooseX::Attribute::Dependent::Meta::Role::ApplicationToRole::VERSION = '1.1.3';
use Moose::Role;

around apply => sub {
    my $orig  = shift;
    my $self  = shift;
    my $role  = shift;
    my $class = shift;
    $class =
      Moose::Util::MetaRole::apply_metaroles(
        for            => $class,
        role_metaroles => {
            application_to_class => ['MooseX::Attribute::Dependent::Meta::Role::ApplicationToClass'],
            application_to_role => ['MooseX::Attribute::Dependent::Meta::Role::ApplicationToRole'],

        },);
    $self->$orig( $role, $class );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Attribute::Dependent::Meta::Role::ApplicationToRole

=head1 VERSION

version 1.1.3

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
