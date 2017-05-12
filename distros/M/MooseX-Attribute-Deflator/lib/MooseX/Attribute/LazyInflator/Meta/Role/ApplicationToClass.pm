#
# This file is part of MooseX-Attribute-Deflator
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::LazyInflator::Meta::Role::ApplicationToClass;
{
  $MooseX::Attribute::LazyInflator::Meta::Role::ApplicationToClass::VERSION = '2.2.2';
}
use Moose::Role;
use MooseX::Attribute::LazyInflator::Role::Class;

around apply => sub {
    my $orig  = shift;
    my $self  = shift;
    my $role  = shift;
    my $class = shift;
    $class =
      Moose::Util::MetaRole::apply_metaroles(
        for             => $class,
        class_metaroles => {
            constructor => [
'MooseX::Attribute::LazyInflator::Meta::Role::Method::Constructor'
            ],
        } ) if ( Moose->VERSION < 1.9900 );

    Moose::Util::MetaRole::apply_base_class_roles(
                       for   => $class->name,
                       roles => ['MooseX::Attribute::LazyInflator::Role::Class']
    );

    $self->$orig( $role, $class );
};

1;

__END__
=pod

=head1 NAME

MooseX::Attribute::LazyInflator::Meta::Role::ApplicationToClass

=head1 VERSION

version 2.2.2

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

