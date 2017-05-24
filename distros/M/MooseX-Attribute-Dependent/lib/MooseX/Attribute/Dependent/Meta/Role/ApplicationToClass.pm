#
# This file is part of MooseX-Attribute-Dependent
#
# This software is Copyright (c) 2017 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::Dependent::Meta::Role::ApplicationToClass;
$MooseX::Attribute::Dependent::Meta::Role::ApplicationToClass::VERSION = '1.1.4';
use Moose::Role;

around apply => sub {
    my $orig  = shift;
    my $self  = shift;
    my $role  = shift;
    my $class = shift;
    $class =
      Moose::Util::MetaRole::apply_metaroles(
        for             => $class,
        class_metaroles => {
            (Moose->VERSION >= 1.9900
                ? (class =>
                    ['MooseX::Attribute::Dependent::Meta::Role::Class'])
                : (constructor =>
                    ['MooseX::Attribute::Dependent::Meta::Role::Method::Constructor'])),
        });
    $self->$orig( $role, $class );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Attribute::Dependent::Meta::Role::ApplicationToClass

=head1 VERSION

version 1.1.4

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
