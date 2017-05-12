package OX::RouteBuilder::Code;
BEGIN {
  $OX::RouteBuilder::Code::AUTHORITY = 'cpan:STEVAN';
}
$OX::RouteBuilder::Code::VERSION = '0.14';
use Moose;
use namespace::autoclean;
# ABSTRACT: OX::RouteBuilder which routes to a coderef

with 'OX::RouteBuilder';


sub compile_routes {
    my $self = shift;

    my ($defaults, $validations) = $self->extract_defaults_and_validations($self->params);

    return {
        path        => $self->path,
        defaults    => $defaults,
        target      => $self->route_spec,
        validations => $validations,
    };
}

sub parse_action_spec {
    my $class = shift;
    my ($action_spec) = @_;

    return unless ref($action_spec) eq 'CODE';
    return $action_spec;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OX::RouteBuilder::Code - OX::RouteBuilder which routes to a coderef

=head1 VERSION

version 0.14

=head1 SYNOPSIS

  package MyApp;
  use OX;

  router as {
      route '/' => sub { "Hello world" };
  };

=head1 DESCRIPTION

This is an L<OX::RouteBuilder> which allows routing directly to a coderef.

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
