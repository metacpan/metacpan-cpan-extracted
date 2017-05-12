use v5.16;
use warnings;

package Net::Minecraft::Login {

  # ABSTRACT: Basic implementation of the Minecraft Login Protocol.


  use Moo;
  with 'Net::Minecraft::Role::HTTP';
  use Carp qw( confess );
  use Scalar::Util qw( blessed );
  use Params::Validate qw( validate SCALAR );
  use Net::Minecraft::LoginResult;
  use Net::Minecraft::LoginFailure;


  has login_server => ( is => rwp =>, lazy => 1, default => sub { return 'https://login.minecraft.net/' }, );


  ## no critic ( ProhibitMagicNumbers )
  has version => ( is => rwp =>, lazy => 1, default => sub { 13 }, );


  sub _do_request {
    my ( $self, $base_uri, $parameters, $config ) = @_;
    my $uri = sprintf q{%s?%s}, $base_uri, $self->http_engine->www_form_urlencode($parameters);
    return $self->http_engine->request( GET => $uri, $config );

  }


  sub login {
    my ( $self, @args ) = @_;
    my %params = validate(
      @args => {
        user     => { type => SCALAR },
        password => { type => SCALAR },
        version  => { type => SCALAR, default => $self->version },
      }
    );
    my $result = $self->_do_request( $self->login_server, \%params, { headers => $self->http_headers }, );
    if ( not $result->{success} ) {
      my $failure = Net::Minecraft::LoginFailure->new(
        code   => $result->{status},
        reason => $result->{reason},
      );
      return $failure;
    }
    return Net::Minecraft::LoginResult->parse( $result->{content} );
  }
};
BEGIN {
  $Net::Minecraft::Login::AUTHORITY = 'cpan:KENTNL';
}
{
  $Net::Minecraft::Login::VERSION = '0.002000';
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Minecraft::Login - Basic implementation of the Minecraft Login Protocol.

=head1 VERSION

version 0.002000

=head1 DESCRIPTION

This is a basic implementation of the Minecraft Login protocol as described at L<http://wiki.vg/Session#Login>

  use Net::Minecraft::Login;

  my $ua = Net::Minecraft::Login->new();

  my $result = $ua->login(
    user => 'Bob',
    password => 'secret',
  );
  if( not $result->is_success ){
    die $result;
  }
  say "Login for user " . $result->user . " succeeded";

Note, it presently does no explicit session stuff, only performs the basic HTTP Request and returns the response as an object.

=head1 CONSTRUCTOR ARGUMENTS

This section describes arguments that may be optionally passed to L<<< C<< ->new() >>|/new >>>, but as of the time of this writing, none are explicitly required,
and are offered only to give leverage to strange use cases ( and tests )

  my $instance = Net::Minecraft::Login->new(
    user_agent   => ... ,
    http_headers => { ... },
    http_engine  => HTTP::Tiny->new(),
    login_server => 'https://somewhere.else.org/'
    version      => 14, # IN THE FUTURE!
  );

Additional Constructor arguments can also be found in L<< C<Net::Minecraft::Role::HTTP>|Net::Minecraft::Role::HTTP >>

=head2 C<login_server>

HTTP Address to authenticate with.

  type  : String
  default : https://login.minecraft.net/

=head2 C<version>

"Client" version.

  type  : String
  default : 13

This field indicates the version of the "Launcher". Minecraft may at some future time produce an updated launcher, and indicate that this specified version is out of date.

Mojang Minecraft Launchers will be required to download a newer version, and users of C<Net::Minecraft::Login> will either

=over 4

=item a) Be required to update to a newer C<Net::Minecraft::Login> that supports the newer version and changes that implies

=item b) Assuming no C<Login Protocol> Changes, only have to specify C<< version => >> either to the constructor, or as an argument to L</login>

=back

=head1 METHODS

=head2 C<login>

  signature: { user => String , password => String, version? => String }
  return   : Any( Net::Minecraft::LoginResult , Net::Minecraft::LoginFailure )

  my $result = $nmcl->login(
    user   => 'notch',
    password => 'jellybean',
  );

  if( not $result->is_success ){
    say "$result";
  } else {
    say "Logged in!";
  }

See L<< C<::LoginFailure>|Net::Minecraft::LoginFailure >> and L<< C<::LoginResult>|Net::Minecraft::LoginResult >>

=head1 ATTRIBUTES

=head2 C<login_server>

=head2 C<version>

=head1 PRIVATE METHODS

=head2 C<_do_request>

  signature : ( String $base_uri, Hash[ String => String ] $parameters , Hash[ String => Any ] $config )
  return    : Hash[ String => String ]

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::Minecraft::Login",
    "inherits":"Moo::Object",
    "does":"Net::Minecraft::Role::HTTP",
    "interface":"class"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentnl@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
