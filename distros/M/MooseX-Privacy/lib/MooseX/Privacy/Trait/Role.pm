package MooseX::Privacy::Trait::Role;
BEGIN {
  $MooseX::Privacy::Trait::Role::VERSION = '0.05';
}

use MooseX::Role::Parameterized;

parameter name => ( isa => 'Str', required => 1, );

role {
    my $p         = shift;
    my $role_name = "MooseX::Privacy::Meta::Attribute::" . $p->name;

    around accessor_metaclass => sub {
        my ( $orig, $self, @rest ) = @_;

        return Moose::Meta::Class->create_anon_class(
            superclasses => [ $self->$orig(@_) ],
            roles        => [$role_name],
            cache        => 1
        )->name;
    };
};

1;

__END__
=pod

=head1 NAME

MooseX::Privacy::Trait::Role

=head1 VERSION

version 0.05

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

