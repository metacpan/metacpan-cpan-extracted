use 5.010;    # mro
use strict;
use warnings;

package Net::Travis::API::UA;

our $VERSION = '0.002001';

# ABSTRACT: Travis Specific User Agent that handles authorization

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













use Moo qw( extends has );
use mro;
extends 'HTTP::Tiny';


































use Carp qw(croak);

sub _package_version {
  my $vfield = join q[::], __PACKAGE__, q[VERSION];
  ## no critic (BuiltinFunctions::ProhibitStringyEval,Lax::ProhibitStringyEval::ExceptForRequire)
  if ( eval "defined \$$vfield" ) {
    ## no critic(ErrorHandling::RequireCheckingReturnValueOfEval)
    return eval "\$$vfield";
  }
  return;
}

sub _ua_version {
  my ( $self, ) = @_;
  return 0 if not defined $self->_package_version;
  return $self->_package_version;
}
sub _ua_name { return __PACKAGE__ }

sub _ua_flags {
  my ( $self, ) = @_;
  my $flags = ['cpan'];
  push @{$flags}, 'dev' if not defined $self->_package_version;
  return $flags;
}

sub _agent {
  my ($self) = @_;
  my $own_ua = sprintf '%s/%s (%s)', $self->_ua_name, $self->_ua_version, ( join q{; }, @{ $self->_ua_flags } );
  my @agent_strings = ($own_ua);
  for my $class ( @{ mro::get_linear_isa(__PACKAGE__) } ) {
    next unless $class->can('_agent');
    next if $class eq __PACKAGE__;
    push @agent_strings, $class->_agent();
  }
  return join q[ ], @agent_strings;
}











has 'http_prefix' => (
  is      => ro  =>,
  lazy    => 1,
  builder => sub { return 'https://api.travis-ci.org' },
);












has 'http_default_accept_headers' => (
  is      => ro  =>,
  lazy    => 1,
  builder => sub { return 'application/vnd.travis-ci.2+json' },
);















has 'authtokens' => (
  is        => rw =>,
  predicate => 'has_authtokens',
);









has 'json' => (
  is      => ro =>,
  lazy    => 1,
  builder => sub {
    require JSON::MaybeXS;
    return JSON::MaybeXS->new();
  },
);

sub _add_auth_tokens {
  my ( $self, $options ) = @_;
  $options = {} if not defined $options;
  if ( exists $options->{travis_no_auth} ) {
    delete $options->{travis_no_auth};
    return $options;
  }
  return $options unless $self->has_authtokens;
  return $options if exists $options->{headers} and exists $options->{headers}->{Authorization};
  $options->{headers}->{Authorization} = [ map { 'token ' . $_ } @{ $self->authtokens } ];
  return $options;
}

sub _expand_uri {
  my ( $self, $uri ) = @_;
  require URI;
  return URI->new_abs( $uri, $self->http_prefix );
}

sub FOREIGNBUILDARGS {
  my ( undef, @elems ) = @_;
  my $hash;
  if ( 1 == @elems and ref $elems[0] ) {
    $hash = $elems[0];
  }
  elsif ( @elems % 2 == 0 ) {
    $hash = {@elems};
  }
  else {
    croak q[Uneven number of parameters or non-ref passed];
  }
  my %not = map { $_ => 1 } qw( http_prefix http_default_accept_headers authtokens );
  my %out;
  for my $key ( keys %{$hash} ) {
    next if $not{$key};
    $out{$key} = $hash->{$key};
  }
  return %out;
}

sub BUILD {
  my ($self) = @_;
  if( not exists $self->{default_headers}{Accept} ) {
    $self->{default_headers}{Accept} = $self->http_default_accept_headers;
  }
  return;
}










sub request {
  my ( $self, $method, $uri, $opts ) = @_;
  my $result = $self->SUPER::request( $method, $self->_expand_uri($uri), $self->_add_auth_tokens($opts) );
  require Net::Travis::API::UA::Response;
  return Net::Travis::API::UA::Response->new(
    json => $self->json,
    %{$result},
  );
}





no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Travis::API::UA - Travis Specific User Agent that handles authorization

=head1 VERSION

version 0.002001

=head1 SYNOPSIS

    use Net::Travis::API::UA;
    use Data::Dump qw( pp );

    my $ua = Net::Travis::API::UA->new(
        http_prefix => 'https://api.travis-ci.org', # default
        authtokens => [ 'sometoken' ]               # multiple supported, but it may not mean anything for travis
    );

    my $result = $ua->get('/users');
    if ( $result->content_type eq 'application/json' ) {
        print pp( $result->content_json );
    } else {
        print pp( $result );
    }

This module does a few things:

=over 4

=item 1. Wrap HTTP::Tiny

=item 2. Assume you want to use relative URI's to the travis service

=item 3. Inject Authorization tokens where possible.

=back

All requests return L<< C<::Response>|Net::Travis::API::UA::Response >> objects.

=head1 METHODS

=head2 C<has_authtokens>

A predicate that returns whether L<< C<authtokens>|/authtokens >> is set or not

=head2 C<request>

This method overrides C<HTTP::Tiny>'s L<< C<request>|HTTP::Tiny/request >> method so
as to augment all other methods inherited.

This simply wraps all responses in a L<< C<Net::Travis::API::UA::Response>|Net::Travis::API::UA::Response >>

=head1 ATTRIBUTES

=head2 C<http_prefix>

I<Optional.>

Determines the base URI to use for relative URIs.

Defaults as L<< C<https://api.travis-ci.org>|https://api.travis-ci.org >> but should be changed if you're using their paid-for service.

=head2 C<http_default_accept_headers>

I<Optional.>

Sets the default C< Accept > headers to send to the Travis-CI service.

Defaults to C<application/vnd.travis-ci.2+json> as per the API documentation.
Without this, the deprecated version 1 API will be used instead.

=head2 C<authtokens>

I<Optional.>

If specified, determines a list of authentication tokens to pass with all requests.

=head2 C<json>

I<Optional.>

Defines a JSON decoder object.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::Travis::API::UA",
    "interface":"class",
    "inherits":"HTTP::Tiny"
}


=end MetaPOD::JSON

=for Pod::Coverage FOREIGNBUILDARGS BUILD

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
