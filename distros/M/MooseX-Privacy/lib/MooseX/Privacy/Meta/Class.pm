package MooseX::Privacy::Meta::Class;
BEGIN {
  $MooseX::Privacy::Meta::Class::VERSION = '0.05';
}

#ABSTRACT: Meta Class for your privacy

use Moose::Role;
use Moose::Meta::Class;

with(
    'MooseX::Privacy::Meta::Class::Role' => { name => 'protected' },
    'MooseX::Privacy::Meta::Class::Role' => { name => 'private' },
);

package Moose::Meta::Attribute::Custom::Trait::Private;
BEGIN {
  $Moose::Meta::Attribute::Custom::Trait::Private::VERSION = '0.05';
}
sub register_implementation {'MooseX::Privacy::Trait::Private'}

package Moose::Meta::Attribute::Custom::Trait::Protected;
BEGIN {
  $Moose::Meta::Attribute::Custom::Trait::Protected::VERSION = '0.05';
}
sub register_implementation {'MooseX::Privacy::Trait::Protected'}

1;



=pod

=head1 NAME

MooseX::Privacy::Meta::Class - Meta Class for your privacy

=head1 VERSION

version 0.05

=head1 METHODS

=head2 local_private_attributes

Arrayref of all private attributes

    my $private_attributes = $self->meta->local_private_attributes;

=head2 local_private_methods

Arrayref of all private methods

    my $private_methods = $self->meta->local_private_methods;

=head2 add_private_method

Add a private method to your object.

    $object->meta->add_private_method('foo', sub { return 23 });

or

    $object->meta->add_private_method(
        'foo',
        MooseX::Privacy::Meta::Method::Private->wrap(
            name         => 'foo',
            package_name => 'Foo',
            body         => sub { return 23 }
        )
    );

=head2 local_protected_attributes

Arrayref of all protected attributes

    my $protected_attributes = $self->meta->local_protected_attributes;

=head2 local_protected_methods

Arrayref of all protected methods

    my $private_methods = $self->meta->local_protected_methods;

=head2 add_protected_method

Add a protected method to your object.

    $object->meta->add_protected_method('foo', sub { return 23 });

or

    $object->meta->add_protected_method(
        'foo',
        MooseX::Privacy::Meta::Method::Protected->wrap(
            name         => 'foo',
            package_name => 'Foo',
            body         => sub { return 23 }
        )
    );

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

