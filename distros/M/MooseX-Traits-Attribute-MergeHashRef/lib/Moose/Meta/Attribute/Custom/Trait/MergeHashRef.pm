#
# This file is part of MooseX-Traits-Attribute-MergeHashRef
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package Moose::Meta::Attribute::Custom::Trait::MergeHashRef;
BEGIN {
  $Moose::Meta::Attribute::Custom::Trait::MergeHashRef::VERSION = '1.002';
} 
use Moose::Role;
use MooseX::Traits::Attribute::MergeHashRef;

has 'clearer' => (is => 'rw', default => sub { 'clear_' . $_[0]->name } );

sub accessor_metaclass { 'MooseX::Traits::Attribute::MergeHashRef' }

after 'install_accessors' => sub { 
    my $attr  = shift;
    my $class = $attr->associated_class;
    my $method = sub { $_[0]->${\('clear_'.$attr->name)}; shift->${\($attr->name)}(@_); };
    $class->add_method( 'set_' . $attr->name, $method );
};

1;
__END__
=pod

=head1 NAME

Moose::Meta::Attribute::Custom::Trait::MergeHashRef

=head1 VERSION

version 1.002

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

