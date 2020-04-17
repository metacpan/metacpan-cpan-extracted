package Mojo::UserAgent::Role::Signature;
use Mojo::Base -role;

use Mojo::Loader qw(load_class);
use Mojo::Util qw(camelize);
use Mojo::UserAgent::Signature::Base;

our $VERSION = '0.01';

has signature_namespaces => sub { ['Mojo::UserAgent::Signature'] };
has 'signature';

around build_tx => sub {
  my ($orig, $self) = (shift, shift);
  return $orig->($self, @_) unless $self->signature;
  $self->signature->apply_signature($orig->($self, @_));
};

sub initialize_signature {
  my $self = shift;
  $self->load_signature(shift)->init($self, ref $_[0] ? $_[0] : {@_});
}

sub load_signature {
  my ($self, $name) = @_;

  # Try all namespaces and full module name
  my $suffix  = $name =~ /^[a-z]/ ? camelize $name : $name;
  my @classes = map {"${_}::$suffix"} @{$self->signature_namespaces};
  for my $class (@classes, $name) { return $class->new if _load($class) }
  return Mojo::UserAgent::Signature::None->new;
}

sub _load {
  my $module = shift;
  return $module->isa('Mojo::UserAgent::Signature::Base')
    unless my $e = load_class $module;
  ref $e ? die $e : return undef;
}

1;

=encoding utf8

=head1 NAME

Mojo::UserAgent::Role::Signature - Role for Mojo::UserAgent that automatically
signs request transactions

=head1 SYNOPSIS

  use Mojo::UserAgent;

  my $ua = Mojo::UserAgent->with_roles('+Signature')->new;
  $ua->initialize_signature(SomeService => {%args});
  my $tx = $ua->get('/api/for/some/service');
  say $tx->req->headers->authorization;

=head1 DESCRIPTION

L<Mojo::UserAgent::Role::Signature> is a role for the full featured non-blocking
I/O HTTP and WebSocket user agent L<Mojo::UserAgent>, that automatically signs
request transactions.

This module modifies the L<Mojo::UserAgent> by wrapping L<Role::Tiny/"around">
the L<Mojo::UserAgent/"build_tx"> method with L</"apply_signature"> signing the
final built transaction using the object instance set in the L</"signature">
attribute that is this module adds to the L<Mojo::UserAgent> class.

=head1 ATTRIBUTES

=head2 signature

  $signature = $ua->signature;
  $ua        = $ua->signature(SomeService->new);

If this attribute is not defined, the method modifier provided by this
L<role|Role::Tiny> will have no effect on the transaction being built
by L<Mojo::UserAgent>.

=head2 signature_namespaces

  $namespaces = $ua->signature_namespaces;
  $ua         = $ua->signature_namespaces(['Mojo::UserAgent::Signature']);

Namespaces to load signature from, defaults to C<Mojo::UserAgent::Signature>.

  # Add another namespace to load signature from
  push @{$ua->namespaces}, 'MyApp::Signature';

=head1 METHODS

L<Mojo::UserAgent::Role::Signature> inherits all methods from L<Mojo::Base> and
implements the following new ones.

=head2 initialize_signature

  $ua->initialize_signature('some_service');
  $ua->initialize_signature('some_service', foo => 23);
  $ua->initialize_signature('some_service', {foo => 23});
  $ua->initialize_signature('SomeService');
  $ua->initialize_signature('SomeService', foo => 23);
  $ua->initialize_signature('SomeService', {foo => 23});
  $ua->initialize_signature('MyApp::Signature::SomeService');
  $ua->initialize_signature('MyApp::Signature::SomeService', foo => 23);
  $ua->initialize_signature('MyApp::Signature::SomeService', {foo => 23});

Load a signature from the configured namespaces or by full module name and run
init, optional arguments are passed through.

=head2 load_signature

  my $signature = $ua->load_signature('some_service');
  my $signature = $ua->load_signature('SomeService');
  my $signature = $ua->load_signature('MyApp::Signature::SomeService');

Load a signature from the configured namespaces or by full module name. Will
fallback to L<Mojo::UserAgent::Signature::None> if the specified signature
cannot be loaded.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2020, Stefan Adams.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 SEE ALSO

L<https://github.com/stefanadams/mojo-useragent-role-signature>, L<Mojo::UserAgent>.

=cut
