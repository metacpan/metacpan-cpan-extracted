use v5.16;
use warnings;

package Net::Minecraft::Role::HTTP {

  # ABSTRACT: Base class for Minecraft C<HTTP> things.


  use Moo::Role;
  use HTTP::Tiny;
  use Scalar::Util qw( blessed );


  has user_agent => (
    is      => rwp =>,
    lazy    => 1,
    default => sub {
      my $class = $_[0];
      $class = blessed($class) if blessed($class);
      my $version = $class->VERSION;
      $version = 'DEVEL' if not defined $version;
      return sprintf q{%s/%s}, $class, $version;
    },
  );


  has http_headers => ( is => rwp =>, lazy => 1, default => sub { { 'Content-Type' => 'application/x-www-form-urlencoded' } }, );


  has http_engine => ( is => rwp =>, lazy => 1, default => sub { return HTTP::Tiny->new( agent => $_[0]->user_agent ) }, );

};
BEGIN {
  $Net::Minecraft::Role::HTTP::AUTHORITY = 'cpan:KENTNL';
}
{
  $Net::Minecraft::Role::HTTP::VERSION = '0.002000';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Minecraft::Role::HTTP - Base class for Minecraft C<HTTP> things.

=head1 VERSION

version 0.002000

=head1 CONSTRUCTOR ARGUMENTS

This section describes arguments that may be optionally passed to L<<< C<< ->new() >>|/new >>>, but as of the time of this writing, none are explicitly required,
and are offered only to give leverage to strange use cases ( and tests )

  my $instance = _SOME_CLASS_->new(
    user_agent   => ... ,
    http_headers => { ... },
    http_engine  => HTTP::Tiny->new(),
  );

=head2 C<user_agent>

The User Agent to self-describe over HTTP

  type    : String
  default : "Net::Minecraft::Login/" . VERSION

=head2 C<http_headers>

Standard Headers that will be injected in each request

  type    : Hash[ string => string ]
  default : { 'Content-Type' => 'application/x-www-form-urlencoded' }

=head2 C<http_engine>

Low-Level HTTP Transfer Agent.

  type    : Object[ =~ HTTP::Tiny ]
  default : An HTTP::Tiny instance.

=head1 ATTRIBUTES

=head2 C<user_agent>

=head2 C<http_headers>

=head2 C<http_engine>

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::Minecraft::Role::HTTP",
    "interface":"role"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
