package Skilletor::Backend;
# ABSTRACT: Choose a source's backend (author mode) and build it – one value for trust and fetch

use strict;
use warnings;

use Cwd ();
use Skilletor::Error;
use Skilletor::FSUtil qw( decode_utf8_lossy path_resolve );
use Skilletor::JSON ();
use Skilletor::Source::Git;
use Skilletor::Source::Local;
use Skilletor::Source::Url;

our $VERSION = '0.001';

sub local_class { 'Skilletor::Source::Local' }
sub git_class   { 'Skilletor::Source::Git' }
sub url_class   { 'Skilletor::Source::Url' }

# A `local` field as an absolute path: the real path when it is an existing directory.
sub local_dir {
  my ( $self, $path, $home ) = @_;
  my $abs = path_resolve( $self->local_class->expand_home( $path, $home ) );
  if ( -d $abs ) {
    my $real = eval { Cwd::abs_path($abs) };
    # abs_path answers in bytes; an address is a character string, as the reference's is.
    return { path => decode_utf8_lossy($real), exists => 1 } if defined $real;
  }
  return { path => $abs, exists => 0 };
}

# Author mode: `local` if that directory exists, else `git`, else `url`; a `local` alone whose
# directory is missing stays `local`. The origin is the chosen field's (`project` without
# one); the source's `path` goes with whichever is chosen.
sub resolve {
  my ( $self, $src, $home ) = @_;
  my $b = $self->_chosen( $src, $home );
  if ( exists $src->{path} ) {
    $b->{path} = ref $src->{path} ? [ @{ $src->{path} } ] : [ $src->{path} ];
  }
  return $b;
}

sub _chosen {
  my ( $self, $src, $home ) = @_;
  my $origin = sub { $src->{origins}{ $_[0] } // 'project' };
  my $local = exists $src->{local} ? $self->local_dir( $src->{local}, $home ) : undef;
  return { kind => 'local', address => $local->{path}, origin => $origin->('local') } if $local && $local->{exists};
  if ( exists $src->{git} ) {
    my %b = ( kind => 'git', address => $src->{git}, origin => $origin->('git') );
    $b{ref} = $src->{ref} if exists $src->{ref};
    return \%b;
  }
  return { kind => 'url', address => $src->{url}, origin => $origin->('url') } if exists $src->{url};
  return { kind => 'local', address => $local->{path}, origin => $origin->('local') } if $local;
  Skilletor::Error->throw( 'source '.$src->{name}.' has no backend' );
}

# The backend object for a resolved backend – nothing else is consulted.
sub make {
  my ( $self, $backend, $cache_root, $timeout_ms ) = @_;
  my %timeout = defined $timeout_ms ? ( timeout_ms => $timeout_ms ) : ();
  return $self->local_class->new( local_path => $backend->{address} ) if $backend->{kind} eq 'local';
  if ( $backend->{kind} eq 'git' ) {
    return $self->git_class->new(
      url        => $backend->{address},
      ( exists $backend->{ref} ? ( ref => $backend->{ref} ) : () ),
      cache_root => $cache_root,
      %timeout,
    );
  }
  return $self->url_class->new( url => $backend->{address}, cache_root => $cache_root, %timeout ) if $backend->{kind} eq 'url';
  Skilletor::Error->throw( 'unknown backend kind '.$backend->{kind} );
}

# The key under which a run resolves a backend once for every source name that uses it.
sub identity {
  my ( $self, $backend ) = @_;
  return Skilletor::JSON::js_stringify( [ $backend->{kind}, $backend->{address}, $backend->{ref} ] );
}

# A trust request for a source, naming the backend that would be used.
sub trust_request {
  my ( $self, $name, $backend ) = @_;
  return { name => $name, kind => $backend->{kind}, url => $backend->{address} };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Backend - Choose a source's backend (author mode) and build it – one value for trust and fetch

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Backend;
  use Skilletor::Cache qw( cache_root );

  my $src     = $config->source('shared');
  my $backend = Skilletor::Backend->resolve( $src, $home );
  # { kind => 'local', address => '/home/me/dev/skills', origin => 'user' }

  unless ( $state->is_trusted( shared => $backend ) ) { ... }   # project origin: ask first

  my $loc = Skilletor::Backend->make( $backend, cache_root($home) )->resolve;

=head1 DESCRIPTION

The reference's C<resolveBackend> and C<makeBackend> (engine.ts; spec §3,
§4.3): choosing the backend and checking trust work on one value, so they
cannot disagree. A source with a C<local> whose directory exists is read from
there (author mode); else its C<git>, else its C<url>. The backend carries the
origin of the field it came from – what trust is checked against – and the
source's C<path> as a list.

Class methods throughout; override L</local_class>, L</git_class> or
L</url_class> in a subclass to swap a backend.

=head2 resolve

  Skilletor::Backend->resolve( $source, $home );

C<< { kind, address, origin, ref?, path? } >>. A C<local> address is absolute
and, when the directory exists, its real path.

=head2 make

  Skilletor::Backend->make( $backend, $cache_root, $timeout_ms );

The L<Skilletor::Role::Source> object for it.

=head2 identity

The backend identity a run resolves once (C<JSON.stringify([kind, address, ref ?? null])>).

=head2 trust_request

  Skilletor::Backend->trust_request( $name, $backend );   # { name, kind, url }

=head2 local_dir

  Skilletor::Backend->local_dir( $path, $home );   # { path, exists }

A C<local> field as an absolute path; the real path when it is an existing directory.

=head2 local_class

The class built for a C<local> backend (L<Skilletor::Source::Local>).

=head2 git_class

The class built for a C<git> backend (L<Skilletor::Source::Git>).

=head2 url_class

The class built for a C<url> backend (L<Skilletor::Source::Url>).

=head1 SUPPORT

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <getty@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
