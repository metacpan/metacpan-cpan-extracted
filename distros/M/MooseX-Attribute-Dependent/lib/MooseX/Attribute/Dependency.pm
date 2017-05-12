#
# This file is part of MooseX-Attribute-Dependent
#
# This software is Copyright (c) 2016 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package MooseX::Attribute::Dependency;
$MooseX::Attribute::Dependency::VERSION = '1.1.3';
use Moose;
has [qw(parameters message constraint name)] => ( is => 'ro' );

sub get_message {
    my ($self) = @_;
    sprintf( $self->message, join( ', ', @{ $self->parameters } ) );
}

use overload( bool => sub {1} );

my $meta = Class::MOP::Class->initialize('MooseX::Attribute::Dependencies');

sub register {
    my ($args) = @_;
    no strict 'refs';
    my $name = 'MooseX::Attribute::Dependencies::' . $args->{name};
    my $code = sub {
        my $params = shift;
        my $dep = MooseX::Attribute::Dependency->new(
            %$args,
            name       => $name,
            parameters => $params
        );
        return @_ ? ($dep, @_) : $dep;
    };
    $meta->add_method( $args->{name}, $code );
}

__PACKAGE__->meta->make_immutable;

package MooseX::Attribute::Dependencies;
$MooseX::Attribute::Dependencies::VERSION = '1.1.3';
use strict;
use warnings;
use List::MoreUtils ();

MooseX::Attribute::Dependency::register(
    {   name       => 'All',
        message    => 'The following attributes are required: %s',
        constraint => sub {
            my ( $attr_name, $params, @related ) = @_;
            return List::MoreUtils::all { exists $params->{$_} } @related;
            }
    }
);

MooseX::Attribute::Dependency::register(
    {   name    => 'Any',
        message => 'At least one of the following attributes is required: %s',
        constraint => sub {
            my ( $attr_name, $params, @related ) = @_;
            return List::MoreUtils::any { exists $params->{$_} } @related;
            }
    }
);

MooseX::Attribute::Dependency::register(
    {   name       => 'None',
        message    => 'None of the following attributes can have a value: %s',
        constraint => sub {
            my ( $attr_name, $params, @related ) = @_;
            return List::MoreUtils::none { exists $params->{$_} } @related;
            }
    }
);

MooseX::Attribute::Dependency::register(
    {   name => 'NotAll',
        message =>
            'At least one of the following attributes cannot have a value: %s',
        constraint => sub {
            my ( $attr_name, $params, @related ) = @_;
            return List::MoreUtils::notall { exists $params->{$_} } @related;
            }
    }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MooseX::Attribute::Dependency

=head1 VERSION

version 1.1.3

=head1 AUTHOR

Moritz Onken

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
