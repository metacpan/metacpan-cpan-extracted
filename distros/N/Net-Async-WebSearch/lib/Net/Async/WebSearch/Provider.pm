package Net::Async::WebSearch::Provider;
our $VERSION = '0.002';
# ABSTRACT: Base class for Net::Async::WebSearch providers
use strict;
use warnings;
use Carp qw( croak );

sub new {
  my ( $class, %args ) = @_;
  my $self = bless { %args }, $class;
  $self->{enabled} = 1 unless defined $self->{enabled};
  $self->{tags}  ||= [];
  $self->_init;
  return $self;
}

sub _init {}

sub default_name {
  my ( $self ) = @_;
  my $pkg = ref $self;
  $pkg =~ s/.*:://;
  return lc $pkg;
}

sub name {
  my ( $self ) = @_;
  @_ > 1 ? ($self->{name} = $_[1]) : ($self->{name} // $self->default_name);
}

sub enabled { @_ > 1 ? ($_[0]->{enabled} = $_[1]) : $_[0]->{enabled} }

sub tags {
  my ( $self ) = @_;
  return @{ $self->{tags} || [] };
}

sub has_tag {
  my ( $self, $tag ) = @_;
  return scalar grep { $_ eq $tag } @{ $self->{tags} || [] };
}

sub matches {
  my ( $self, $sel ) = @_;
  return 1 if $sel eq $self->name;
  return 1 if $sel eq $self->default_name;
  return 1 if $self->has_tag($sel);
  return 0;
}

sub user_agent_string {
  'Net-Async-WebSearch/' . ($Net::Async::WebSearch::VERSION // 'dev');
}

# Subclasses MUST implement.
# Signature: $self->search($http, $query, \%opts)
# Returns: Future of arrayref of Net::Async::WebSearch::Result
sub search {
  my ( $self ) = @_;
  croak ref($self).": must implement search()";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::WebSearch::Provider - Base class for Net::Async::WebSearch providers

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  package Net::Async::WebSearch::Provider::Foo;
  use parent 'Net::Async::WebSearch::Provider';
  use Future;
  use Net::Async::WebSearch::Result;

  sub search {
    my ( $self, $http, $query, $opts ) = @_;
    # ... build HTTP::Request, dispatch via $http->do_request(...)
    # return Future->done([ Net::Async::WebSearch::Result->new(...), ... ]);
  }

=head1 DESCRIPTION

Base class for search providers. Subclasses override C<search> and return a
L<Future> that resolves to an arrayref of L<Net::Async::WebSearch::Result>
objects in provider-native rank order.

The same L<Net::Async::HTTP> client is shared by every provider attached to a
L<Net::Async::WebSearch>, so providers should I<not> build their own HTTP
pipelines.

=head2 name

Provider short name (used in allow/deny lists). Defaults to the lowercased
leaf package name. Read/write — L<Net::Async::WebSearch/add_provider>
auto-renames a provider (C<name#2>, C<name#3>...) when a stacked instance
would otherwise collide with an existing registered name.

=head2 enabled

Boolean. Disabled providers are skipped by L<Net::Async::WebSearch> regardless
of per-query C<only>/C<exclude>.

=head2 tags

Arrayref of tag strings. Tags are matched by C<only>/C<exclude> and
C<provider_opts> keys alongside the provider's C<name> — so you can group
multiple stacked instances (e.g. tag every paid API as C<paid>, tag a set of
private SearxNGs as C<private>) and select/deselect them together.

=head2 default_name

Lowercased leaf package name. Used by C<name> when no explicit name was
passed to C<new>.

=head2 has_tag($tag)

True if this provider carries C<$tag>.

=head2 matches($selector)

True if C<$selector> equals this provider's C<name>, its class leaf
(lowercased), or one of its C<tags>. Used internally by L<Net::Async::WebSearch>
for C<only>/C<exclude>/C<provider_opts> resolution.

=head2 search($http, $query, \%opts)

Abstract. C<$http> is a L<Net::Async::HTTP>. C<$query> is the search string.
C<%opts> carries C<limit>, C<language>, C<region>, C<safesearch>, and any
provider-specific overrides from the caller. Return a Future of arrayref of
L<Net::Async::WebSearch::Result>.

=head2 user_agent_string

Default User-Agent used if the provider needs to build its own request.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-websearch/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
