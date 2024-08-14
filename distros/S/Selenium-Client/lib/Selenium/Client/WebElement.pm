package Selenium::Client::WebElement;
$Selenium::Client::WebElement::VERSION = '2.01';
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

version 2.01

=head1 DESCRIPTION

Subclass of Selenium::Remote::WebElement.

Implements the bare minimum to shim in Selenium::Client as a backend for talking to selenium 4 servers.

See the documentation for L<Selenium::Remote::WebElement> for details about methods, unless otherwise noted below.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Selenium::Client|Selenium::Client>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/troglodyne-internet-widgets/selenium-client-perl/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHORS

Current Maintainers:

=over 4

=item *

George S. Baugh <george@troglodyne.net>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2024 Troglodyne LLC


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut
