package OX::RouteBuilder::REST;
use Moose;
use namespace::autoclean;

our $VERSION = 0.003;

# ABSTRACT: OX::RouteBuilder which routes to an action method in a controller class based on HTTP verbs

use Try::Tiny;

with 'OX::RouteBuilder';

sub import {
    my $caller = caller;
    my $meta   = Moose::Util::find_meta($caller);
    $meta->add_route_builder('OX::RouteBuilder::REST');
}

sub compile_routes {
    my $self = shift;
    my ($app) = @_;

    my $spec   = $self->route_spec;
    my $params = $self->params;
    my ( $defaults, $validations ) =
        $self->extract_defaults_and_validations($params);
    $defaults = { %$spec, %$defaults };

    my $target = sub {
        my ($req) = @_;

        my $match = $req->mapping;
        my $c     = $match->{controller};
        my $a     = $match->{action};

        my $err;
        my $s = try { $app->fetch($c) } catch { ($err) = split "\n"; undef };
        return [
            500, [], [ "Cannot resolve $c in " . blessed($app) . ": $err" ]
            ]
            unless $s;

        my $component = $s->get;
        my $method    = uc( $req->method );
        my $action    = $a . '_' . $method;

        if ( $component->can($action) ) {
            return $component->$action(@_);
        }
        else {
            return [ 500, [],
                ["Component $component has no method $action"] ];
        }
    };

    return {
        path        => $self->path,
        defaults    => $defaults,
        target      => $target,
        validations => $validations,
    };
}

sub parse_action_spec {
    my $class = shift;
    my ($action_spec) = @_;

    return if ref($action_spec);
    return unless $action_spec =~ /^REST\.(\w+)\.(\w+)$/;

    return {
        controller => $1,
        action     => $2,
        name       => $action_spec,
    };
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

OX::RouteBuilder::REST - OX::RouteBuilder which routes to an action method in a controller class based on HTTP verbs

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  package MyApp;
  use OX;
  use OX::RouteBuilder::REST;

  has thing => (
      is  => 'ro',
      isa => 'MyApp::Controller::Thing',
  );

  router as {
      route '/thing'     => 'REST.thing.root';
      route '/thing/:id' => 'REST.thing.item';
  };


  package MyApp::Controller::Thing;
  use Moose;

  sub root_GET {
      my ($self, $req) = @_;
      ... # return a list if things
  }

  sub root_PUT {
      my ($self, $req) = @_;
      ... # create a new thing
  }

  sub item_GET {
      my ($self, $req, $id) = @_;
      ... # view a thing
  }

  sub item_POST {
      my ($self, $req, $id) = @_;
      ... # update a thing
  }

=head1 DESCRIPTION

This is an L<OX::RouteBuilder> which routes to an action method in a
controller class based on HTTP verbs. It's a bit of a mixture between
L<OX::RouteBuilder::ControllerAction> and
L<OX::RouteBuilder::HTTPMethod>.

To enable this RouteBuilder, you need to C<use OX::RouteBuilder::REST>
in your main application class.

The C<action_spec> should be a string in the form
C<"REST.$controller.$action">, where C<$controller> is the name of a
service which provides a controller instance. For each HTTP verb you
want to support you will need to set up an action with the name
C<$action_$verb> (e.g. C<$action_GET>, C<$action_PUT>, etc). If no
matching action-verb-method is found, a 404 error will be returned.

C<controller> and C<action> will also be automatically added as
defaults for the route, as well as C<name> (which will be set to
C<"REST.$controller.$action">).

To generate a link to an action, use C<uri_for> with either the name
(eg C<"REST.$controller.$action">), or by passing a HashRef C<{
    controller => $controller, action => $action }>. See F<t/test.t>
    for some examples.

=for Pod::Coverage import
  compile_routes
  parse_action_spec

=head1 AUTHORS

=over 4

=item *

Thomas Klausner <domm@cpan.org>

=item *

Validad GmbH http://validad.com

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
