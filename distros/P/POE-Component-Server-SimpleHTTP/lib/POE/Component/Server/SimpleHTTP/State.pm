package POE::Component::Server::SimpleHTTP::State;
$POE::Component::Server::SimpleHTTP::State::VERSION = '2.28';
use strict;
use warnings;
use POE::Wheel::ReadWrite;

use Moose;

has 'wheel' => (
  is => 'ro',
  isa => 'POE::Wheel::ReadWrite',
  clearer => 'clear_wheel',
  predicate => 'has_wheel',
  required => 1,
);

has 'response' => (
  is => 'ro',
  isa => 'POE::Component::Server::SimpleHTTP::Response',
  writer => 'set_response',
  clearer => 'clear_response',
);

has 'request' => (
  is => 'ro',
  isa => 'HTTP::Request',
  writer => 'set_request',
  clearer => 'clear_request',
);

has 'connection' => (
  is => 'ro',
  isa => 'POE::Component::Server::SimpleHTTP::Connection',
  writer => 'set_connection',
  clearer => 'clear_connection',
  init_arg => undef,
);

has 'done' => (
  is => 'ro',
  isa => 'Bool',
  init_arg => undef,
  default => sub { 0 },
  writer => 'set_done',
);

has 'streaming' => (
  is => 'ro',
  isa => 'Bool',
  init_arg => undef,
  default => sub { 0 },
  writer => 'set_streaming',
);

sub reset {
  my $self = shift;
  $self->clear_response;
  $self->clear_request;
  $self->set_streaming(0);
  $self->set_done(0);
  $self->wheel->set_output_filter( $self->wheel->get_input_filter ) if $self->has_wheel;
  return 1;
}

sub close_wheel {
  my $self = shift;
  return unless $self->has_wheel;
  $self->wheel->shutdown_input;
  $self->wheel->shutdown_output;
  $self->clear_wheel;
  return 1;
}

sub wheel_alive {
  my $self = shift;
  return unless $self->has_wheel;
  return unless defined $self->wheel;
  return unless $self->wheel->get_input_handle();
  return 1;
}

no Moose;

__PACKAGE__->meta->make_immutable();

'This monkey has gone to heaven';

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::Server::SimpleHTTP::State

=head1 VERSION

version 2.28

=for Pod::Coverage        close_wheel
       reset
       wheel_alive

=head1 AUTHOR

Apocalypse <APOCAL@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Apocalypse, Chris Williams, Eriam Schaffter, Marlon Bailey and Philip Gwyn.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
