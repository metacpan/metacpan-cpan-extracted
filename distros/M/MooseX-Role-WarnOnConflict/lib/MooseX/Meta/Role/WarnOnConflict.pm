package MooseX::Meta::Role::WarnOnConflict;

# ABSTRACT: metaclass for Moose::Meta::Role

use Moose;
extends 'Moose::Meta::Role';

our $VERSION = '0.01';

override apply => sub {
    my ( $self, $other, @args ) = @_;

    if ( blessed($other) && $other->isa('Moose::Meta::Class') ) {
        # already loaded
        return MooseX::Meta::Role::Application::ToClass::WarnOnConflig->new(@args)
          ->apply( $self, $other );
    }

    super;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Meta::Role::WarnOnConflict - metaclass for Moose::Meta::Role

=head1 VERSION

version 0.01

=head1 DESCRIPTION

This is the metaclass for C<MooseX::Role::WarnOnConflict>.  For internal use only.

=head1 AUTHOR

Curtis "Ovid" Poe <curtis.poe@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Curtis "Ovid" Poe.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
