package MooseX::Lexical::Types::TypeDecorator;
our $VERSION = '0.01';


use Moose;
use MooseX::Types::Moose qw/Str/;
use namespace::autoclean;

use overload '""' => \&type_package;

extends 'MooseX::Types::TypeDecorator';

has type_namespace => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { 'MooseX::Lexical::Types::' },
);

sub type_package {
    my ($self) = @_;
    if (blessed $self) {
        return $self->type_namespace . $self->__type_constraint->name;
    }
    else {
        return "$self";
    }
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__
=head1 NAME

MooseX::Lexical::Types::TypeDecorator

=head1 VERSION

version 0.01

=head1 AUTHOR

  Florian Ragwitz <rafl@debian.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Florian Ragwitz.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

