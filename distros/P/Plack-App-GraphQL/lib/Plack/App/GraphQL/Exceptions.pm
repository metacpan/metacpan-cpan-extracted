package Plack::App::GraphQL::Exceptions;

use Moo;

extends 'Plack::Component';

has 'psgi_app' => (is=>'ro', required=>1);

sub respond_415 {
  my ($self, $req) = @_;
  return [
    415,
    ['Content-Type' => 'text/plain', 'Content-Length' => 22], 
    ['Unsupported Media Type']
  ];
}

sub respond_404 {
  my ($self, $req) = @_;
  return [
    404,
    ['Content-Type' => 'text/plain', 'Content-Length' => 9], 
    ['Not Found']
  ];
}

sub respond_400 {
  my ($self, $req) = @_;
  return [
    400,
    ['Content-Type' => 'text/plain', 'Content-Length' => 11], 
    ['Bad Request']
  ];
}

1;

=head1 NAME
 
Plack::App::GraphQL::Exceptions - Return PSGI Exception Responses

=head1 SYNOPSIS

    TBD

=head1 DESCRIPTION

Module to encapsulate exception responses.  We isolate this in case you are fussy
and have special needs in how your exceptions are returned.
 
=head1 AUTHOR
 
John Napiorkowski

=head1 SEE ALSO
 
L<GraphQL>, L<Plack>, L<Plack::App::GraphQL>
 
=cut
