package OX::RouteBuilder;
BEGIN {
  $OX::RouteBuilder::AUTHORITY = 'cpan:STEVAN';
}
$OX::RouteBuilder::VERSION = '0.14';
use Moose::Role;
use namespace::autoclean;
# ABSTRACT: abstract role for classes that turn configuration into a route



requires 'compile_routes', 'parse_action_spec';


has path => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);


has route_spec => (
    is       => 'ro',
    required => 1,
);


has params => (
    is       => 'ro',
    isa      => 'HashRef',
    required => 1,
);


sub extract_defaults_and_validations {
    my $self = shift;
    my ($params) = @_;

    my ($defaults, $validations) = ({}, {});

    for my $key (keys %$params) {
        if (ref $params->{$key}) {
            $validations->{$key} = $params->{$key}->{'isa'};
        }
        else {
            $defaults->{$key} = $params->{$key};
        }
    }

    return ($defaults, $validations);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OX::RouteBuilder - abstract role for classes that turn configuration into a route

=head1 VERSION

version 0.14

=head1 DESCRIPTION

This is an abstract role which is used to turn simplified and easy to
understand routing descriptions into actual routes that the router understands.
Currently, the API is a bit specific to L<Path::Router>.

For usable examples, see L<OX::RouteBuilder::ControllerAction>,
L<OX::RouteBuilder::HTTPMethod>, and L<OX::RouteBuilder::Code>.

=head1 ATTRIBUTES

=head2 path

The path that this route is for. Required.

=head2 route_spec

The C<route_spec> that describes how this path should be routed. See
L<OX::Application::Role::RouteBuilder>. Required.

=head2 params

The C<defaults> and C<validations> for this path. See L<Path::Router> for more
information. Required.

=head1 METHODS

=head2 compile_routes($app)

This is a required method which should generate a list of routes based on the
contents of the object. Each route should be a hashref with these keys:

=over 4

=item path

Path specification for the route.

=item target

Coderef to call to handle the request.

=item defaults

Extra values which will be included in the resulting match.

=item validations

Validation rules for variable path components. See L<Path::Router> for more
information.

=back

=head2 parse_action_spec($action_spec)

Required class method which should take the actual action specification
provided in the user's router description and return either a C<route_spec>
that can be understood by L<OX::Application::Role::RouteBuilder> or undef (if the action spec wasn't of the form that could be understood by this class).

=head2 extract_defaults_and_validations

Helper method which sorts the C<params> into C<defaults> and C<validations>.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Jesse Luehrs <doy@tozt.net>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
