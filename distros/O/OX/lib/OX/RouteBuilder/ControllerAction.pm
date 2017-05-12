package OX::RouteBuilder::ControllerAction;
BEGIN {
  $OX::RouteBuilder::ControllerAction::AUTHORITY = 'cpan:STEVAN';
}
$OX::RouteBuilder::ControllerAction::VERSION = '0.14';
use Moose;
use namespace::autoclean;
# ABSTRACT: OX::RouteBuilder which routes to an action method in a controller class

use Try::Tiny;

with 'OX::RouteBuilder';


sub compile_routes {
    my $self = shift;
    my ($app) = @_;

    my $spec = $self->route_spec;
    my $params = $self->params;

    my ($defaults, $validations) = $self->extract_defaults_and_validations($params);
    $defaults = { %$spec, %$defaults };

    my $target = sub {
        my ($req) = @_;

        my $match = $req->mapping;
        my $c = $match->{controller};
        my $a = $match->{action};

        my $err;
        my $s = try { $app->fetch($c) } catch { ($err) = split "\n"; undef };
        return [
            500,
            [],
            ["Cannot resolve $c in " . blessed($app) . ": $err"]
        ] unless $s;

        my $component = $s->get;

        return $component->$a(@_)
            if $component;

        return [
            500,
            [],
            ["Component $component has no action $a"]
        ];
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
    return unless $action_spec =~ /^(\w+)\.(\w+)$/;

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

=encoding UTF-8

=head1 NAME

OX::RouteBuilder::ControllerAction - OX::RouteBuilder which routes to an action method in a controller class

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  package MyApp;
  use OX;

  has controller => (
      is  => 'ro',
      isa => 'MyApp::Controller',
  );

  router as {
      route '/' => 'controller.index';
  };

=head1 DESCRIPTION

This is an L<OX::RouteBuilder> which routes to action methods on a controller
class. The C<action_spec> should be a string in the form
C<"$controller.$action">, where C<$controller> is the name of a service which
provides a controller instance, and C<$action> is the name of a method on that
class.

C<controller> and C<action> will also be automatically added as defaults for
the route, as well as C<name> (which will be set to C<"$controller.$action">.

=for Pod::Coverage compile_routes
  parse_action_spec

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
