#
# This file is part of MooseX-Attribute-Deflator
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::LazyInflator::Meta::Role::ApplicationToRole;
{
  $MooseX::Attribute::LazyInflator::Meta::Role::ApplicationToRole::VERSION = '2.2.2';
}
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
            application_to_class => [
'MooseX::Attribute::LazyInflator::Meta::Role::ApplicationToClass'
            ],
        } );
    $self->$orig( $role, $class );
};

1;

__END__
=pod

=head1 NAME

MooseX::Attribute::LazyInflator::Meta::Role::ApplicationToRole

=head1 VERSION

version 2.2.2

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

