package Selenium::Client::WebElement;
$Selenium::Client::WebElement::VERSION = '2.00';
# ABSTRACT: Representation of an HTML Element used by Selenium Client Driver

use strict;
use warnings;

use parent qw{Selenium::Remote::WebElement};

no warnings qw{experimental};
use feature qw{signatures};

use Carp::Always;


sub _param ( $self, $default, $param, $value = undef ) {
    $self->{$param} //= $default;
    $self->{$param} = $value if defined $value;
    return $self->{$param};
}

sub element ( $self, $element = undef ) {
    return $self->_param( undef, 'element', $element );
}

sub driver ( $self, $driver = undef ) {
    return $self->_param( undef, 'driver', $driver );
}

sub session ( $self, $session = undef ) {
    return $self->_param( undef, 'session', $session );
}

sub new ( $class, %options ) {
    my $self = bless( $options{id}, $class );
    $self->id( $self->{elementid} );
    $self->driver( $options{driver} );
    $self->session( $options{driver}->session );
    return $self;
}

sub id ( $self, $value = undef ) {
    return $self->_param( undef, 'id', $value );
}

# We need to inject the element ID due to this nonstandard wrapper.
sub _execute_command ( $self, $res, $params = {} ) {

    #XXX sigh, some day spec authors will stop LYING
    $params->{propertyname} //= delete $params->{property_name} // delete $res->{property_name};

    my $params_modified = {
        %$params,
        elementid => $self->id,
    };
    return $self->driver->_execute_command( $res, $params_modified );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Client::WebElement - Representation of an HTML Element used by Selenium Client Driver

=head1 VERSION

version 2.00

=head1 DESCRIPTION

Subclass of Selenium::Remote::WebElement.

Implements the bare minimum to shim in Selenium::Client as a backend for talking to selenium 4 servers.

See the documentation for L<Selenium::Remote::WebElement> for details about methods, unless otherwise noted below.

=head1 AUTHOR

George S. Baugh <george@troglodyne.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023 by George S. Baugh.

This is free software, licensed under:

  The MIT (X11) License

=cut
