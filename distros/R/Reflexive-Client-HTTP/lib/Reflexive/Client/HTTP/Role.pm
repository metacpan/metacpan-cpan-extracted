package Reflexive::Client::HTTP::Role;
BEGIN {
  $Reflexive::Client::HTTP::Role::AUTHORITY = 'cpan:GETTY';
}
{
  $Reflexive::Client::HTTP::Role::VERSION = '0.007';
}
# ABSTRACT: A role for automatically getting a watched Reflexive::Client::HTTP

use Moose::Role;

with 'Reflex::Role::Reactive';

use Reflex::Trait::Watched qw(watches);
use Reflexive::Client::HTTP;


watches http => (
	is => 'ro',
	isa => 'Reflexive::Client::HTTP',
	lazy_build => 1,
	handles => {
		http_request => 'request',
	},
);

sub _build_http { Reflexive::Client::HTTP->new(shift->http_options) }


has http_options => (
	is => 'ro',
	isa => 'HashRef',
	default => sub {{}},
);


1;
__END__
=pod

=head1 NAME

Reflexive::Client::HTTP::Role - A role for automatically getting a watched Reflexive::Client::HTTP

=head1 VERSION

version 0.007

=head1 SYNOPSIS

  {
    package MySampleClient;

    use Moose;
    with 'Reflexive::Client::HTTP::Role';

    sub on_http_response {
      my ( $self, $response_event ) = @_;
      my $http_response = $response_event->response;
      my ( $who ) = @{$response_event->args};
      print $who." got status ".$http_response->code."\n";
    }

    sub request {
      my ( $self, $who ) = @_;
      $self->http_request( HTTP::Request->new( GET => 'http://www.duckduckgo.com/' ), $who );
    }
  }

  my $msc = MySampleClient->new;
  $msc->request('peter');
  $msc->request('paul');
  $msc->request('marry');

  Reflex->run_all();

=head1 DESCRIPTION

If you attach this role, your L<Moose> class gets an additional attribute
C<http> which contains a L<Reflexive::Client::HTTP>. This allows you to add a
simple C<on_http_response> method, which gets the
L<Reflexive::Client::HTTP::ResponseEvent> on the success of a previous
executed call to L</http_request>.

=head1 ATTRIBUTES

=head2 http

This watched attribute containts the L<Reflexive::Client::HTTP>. It handles
L</http_request> which triggers L<Reflexive::Client::HTTP/request>.

=head2 http_options

This HashRef is used for constructing the L<Reflexive::Client::HTTP> in
L</http>.

=head1 METHODS

=head2 http_request

See L<Reflexive::Client::HTTP/request>.

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

