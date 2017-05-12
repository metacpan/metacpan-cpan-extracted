package MooseX::Privacy::Meta::Class::Role;
BEGIN {
  $MooseX::Privacy::Meta::Class::Role::VERSION = '0.05';
}

# ABSTRACT: Private and Protected parameterized roles

use MooseX::Role::Parameterized;
use Scalar::Util;
use Carp qw/confess/;
use MooseX::Types::Moose qw/Str ArrayRef/;

use MooseX::Privacy::Meta::Method::Protected;
use MooseX::Privacy::Meta::Method::Private;

parameter name => ( isa => 'Str', required => 1, );

role {
    my $p = shift;

    my $name             = $p->name;
    my $local_methods        = "local_" . $name . "_methods";
    my $local_attributes     = "local_" . $name . "_attributes";
    my $push_method          = "_push_" . $name . "_method";
    my $push_attribute       = "_push_" . $name . "_attribute";
    my $count_methods        = "_count_" . $name . "_methods";
    my $count_attributes     = "_count_" . $name . "_attributes";
    my $get_method           = 'get_' . $name . '_method';
    my $get_all_mehods       = 'get_all_' . $name . '_methods';
    my $get_all_methods_name = 'get_all_' . $name . '_method_names';
    my $meta_method          = "add_" . $name . "_method";

    has $local_methods => (
        traits     => ['Array'],
        is         => 'ro',
        isa        => ArrayRef [Str],
        required   => 1,
        default    => sub { [] },
        auto_deref => 1,
        handles    => { $push_method => 'push', $count_methods => 'count' },
    );

    has $local_attributes => (
        traits     => ['Array'],
        is         => 'ro',
        isa        => ArrayRef [Str],
        required   => 1,
        default    => sub { [] },
        auto_deref => 1,
        handles =>
            { $push_attribute => 'push', $count_attributes => 'count' },
    );

    method $meta_method => sub {
        my ( $self, $method_name, $body ) = @_;

        my $class = "MooseX::Privacy::Meta::Method::" . ( ucfirst $name );

        my $method = blessed $body ? $body : $class->wrap(
            name         => $method_name,
            package_name => $self->name,
            body         => $body
        );

        confess $method_name . " is not a " . $name . " method"
            unless $method->isa($class);

        $self->add_method( $method->name, $method );
        $self->$push_method( $method->name );
    };
};

1;


__END__
=pod

=head1 NAME

MooseX::Privacy::Meta::Class::Role - Private and Protected parameterized roles

=head1 VERSION

version 0.05

=head1 AUTHOR

franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by franck cuny.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

