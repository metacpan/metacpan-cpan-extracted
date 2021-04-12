package OpenAPI::Generator;

use strict;
use warnings;

use Exporter qw(import);
use Carp;

our $VERSION = '0.05';
our @EXPORT = qw(openapi_from);

sub openapi_from {
  my($module, $conf) = @_;
  $module = 'OpenAPI::Generator::From::'.join('', map { ucfirst lc } split /_/, "$module");

  unless (eval "require $module") {
    croak "generator '$module' not found"
  }

  $module->new->generate($conf)
}

1

__END__

=head1 NAME

OpenAPI::Generator - generate openapi definition

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

Generate openapi definitions from various places.

  use OpenAPI::Generator;

  my $openapi_def = openapi_from(pod => {src => 'Controller.pm'});

Checkout modules OpenAPI::Generator::From::* to get more information about generations

=head1 EXPORTS

=over 4

=item openapi_from($module, $conf)

=back

=head1 SUBROUTINES

=over 4

=item openapi_from($module, $conf)

  # using OpenAPI::Generator::From::Pod
  openapi_from(pod => {src => './Controller.pm'})
  openapi_from(pod => {src => './Controllers/'})

=back

=head1 AUTHOR

Anton Fedotov, C<< <tosha.fedotov.2000 at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<https://github.com/doojonio/OpenAPI-Generator/issues>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc OpenAPI::Generator

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Anton Fedotov.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
