#
# This file is part of MooseX-Attribute-Deflator
#
# This software is Copyright (c) 2012 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::Deflator::Registry;
{
  $MooseX::Attribute::Deflator::Registry::VERSION = '2.2.2';
}

# ABSTRACT: Registry class for attribute deflators
use Moose;

has deflators => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[CodeRef]',
    default => sub { {} },
    handles => {
        has_deflator  => 'get',
        get_deflator  => 'get',
        set_deflator  => 'set',
        _add_deflator => 'set',
    }
);

has inlined_deflators => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[CodeRef]',
    default => sub { {} },
    handles => {
        has_inlined_deflator  => 'get',
        get_inlined_deflator  => 'get',
        set_inlined_deflator  => 'set',
        _add_inlined_deflator => 'set',
    }
);

has inflators => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[CodeRef]',
    default => sub { {} },
    handles => {
        has_inflator  => 'get',
        get_inflator  => 'get',
        set_inflator  => 'set',
        _add_inflator => 'set',
    }
);

has inlined_inflators => (
    traits  => ['Hash'],
    is      => 'rw',
    isa     => 'HashRef[CodeRef]',
    default => sub { {} },
    handles => {
        has_inlined_inflator  => 'get',
        get_inlined_inflator  => 'get',
        set_inlined_inflator  => 'set',
        _add_inlined_inflator => 'set',
    }
);

sub add_deflator {
    my ( $self, $name, $deflator, $inlined ) = @_;
    $self->_add_inlined_deflator( $name, $inlined ) if ($inlined);
    return $self->_add_deflator( $name, $deflator );
}

sub find_deflator {
    my ( $self, $constraint, $norecurse ) = @_;
    ( my $name = $constraint->name ) =~ s/\[.*\]/\[\]/;
    my $sub = $self->get_deflator($name);
    return ( $constraint, $sub, $self->get_inlined_deflator($name) )
        if ($sub);
    return undef if ($norecurse);
    return $self->find_deflator( $constraint->parent )
        if ( $constraint->has_parent );
}

sub add_inflator {
    my ( $self, $name, $inflator, $inlined ) = @_;
    $self->_add_inlined_inflator( $name, $inlined ) if ($inlined);
    return $self->_add_inflator( $name, $inflator );
}

sub find_inflator {
    my ( $self, $constraint, $norecurse ) = @_;
    ( my $name = $constraint->name ) =~ s/\[.*\]/\[\]/;
    my $sub = $self->get_inflator($name);
    return ( $constraint, $sub, $self->get_inlined_inflator($name) )
        if ($sub);
    return undef if ($norecurse);
    return $self->find_inflator( $constraint->parent )
        if ( $constraint->has_parent );
}

1;



=pod

=head1 NAME

MooseX::Attribute::Deflator::Registry - Registry class for attribute deflators

=head1 VERSION

version 2.2.2

=head1 DESCRIPTION

This class contains a registry for deflator and inflator functions.

=head1 ATTRIBUTES

=over 4

=item B<< inflators ( isa => HashRef[CodeRef] ) >>

=item B<< deflators ( isa => HashRef[CodeRef] ) >>

=back

=head1 METHODS

=over 4

=item B<< add_inflator( $type_constraint, $coderef ) >>

=item B<< add_deflator( $type_constraint, $coderef ) >>

=item B<< set_inflator( $type_constraint, $coderef ) >>

=item B<< set_deflator( $type_constraint, $coderef ) >>

Add a inflator/deflator function for C<$type_constraint>. Existing functions
are overwritten.

=item B<< has_inflator( $type_constraint ) >>

=item B<< has_deflator( $type_constraint )  >>

Predicate methods.

=item B<< find_inflator( $type_constraint ) >>

=item B<< find_deflator( $type_constraint )  >>

Finds a suitable deflator/inflator by bubbling up the type hierarchy.
it returns the matching type constraint, its deflator an optionally
its inlined deflator if it exists.

=back

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

