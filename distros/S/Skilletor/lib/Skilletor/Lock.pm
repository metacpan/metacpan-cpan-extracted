package Skilletor::Lock;
# ABSTRACT: A scope's lock file (skilletor.lock.json) – reading, writing, its keys

use strict;
use warnings;

use Errno ();
use Exporter qw( import );
use Scalar::Util qw( blessed );
use Skilletor::Error::Lock;
use JSON::MaybeXS ();
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text node_fs_error write_text );
use Skilletor::JSON qw( js_parse js_ordered js_sort_keys js_stringify js_type );

our $VERSION = '0.001';

our @EXPORT_OK = qw( read_lock serialize_lock write_lock parse_lock_key key_to_type_name );

# The lock key prefix of each harness; Claude's keys carry none.
my %HARNESS_OF_PREFIX = ( 'codex:' => 'codex', 'hermes:' => 'hermes' );
my %TYPE_OF_DIR = ( skills => 'skill', agents => 'agent', rules => 'rule' );

# The lock at $path as an ordered hash of entries; a missing file is an empty lock.
sub read_lock {
  my ( $path ) = @_;
  my $bytes = encode_text($path);
  my $text;
  if ( -d $bytes ) {
    Skilletor::Error::Lock->throw( $path.': cannot read lock (EISDIR: illegal operation on a directory, read)' );
  }
  if ( open my $fh, '<:raw', $bytes ) {
    local $/;
    $text = decode_utf8_lossy( <$fh> // '' );
    close $fh;
  }
  else {
    return js_ordered() if $!{ENOENT};
    Skilletor::Error::Lock->throw( $path.': cannot read lock ('.node_fs_error( 0 + $!, 'open', $path ).')' );
  }
  my $value;
  my $ok = eval {
    $value = js_parse($text);
    die { message => 'expected an object' } unless js_type($value) eq 'object';
    # k145: `via` is matched against bundle labels exactly; anything but an array of strings is refused.
    for my $key ( keys %$value ) {
      my $entry = $value->{$key};
      next unless js_type($entry) eq 'object' && exists $entry->{via};
      my $via = $entry->{via};
      die { message => $key.': "via" must be an array of strings' }
        unless js_type($via) eq 'array' && !grep { js_type($_) ne 'string' } @$via;
    }
    1;
  };
  unless ($ok) {
    my $err = $@;
    my $msg = ref $err eq 'HASH' ? $err->{message} : blessed $err && $err->can('message') ? $err->message : "$err";
    Skilletor::Error::Lock->throw( $path.': invalid lock JSON ('.$msg.')' );
  }
  return $value;
}

# The lock's bytes: entries and files sorted, each entry's fields in the reference's order.
sub serialize_lock {
  my ( $lock ) = @_;
  my $out = js_ordered();
  for my $key ( js_sort_keys( keys %$lock ) ) {
    my $e     = $lock->{$key};
    my $files = $e->{files} // {};
    my $entry = js_ordered(
      source  => $e->{source},
      version => $e->{version},
      files   => js_ordered( map { ( $_ => $files->{$_} ) } js_sort_keys( keys %$files ) ),
    );
    $entry->{skipped} = $e->{skipped} if $e->{skipped};
    $entry->{block}   = JSON::MaybeXS::true() if $e->{block};
    my $via = $e->{via};
    if ( ref $via eq 'ARRAY' ? @$via : ( defined $via && !ref $via && length $via ) ) {
      $entry->{via} = ref $via eq 'ARRAY' ? [@$via] : [ split //, $via ];    # [...entry.via]
    }
    $entry->{partial} = JSON::MaybeXS::true() if $e->{partial};
    $out->{$key} = $entry;
  }
  return js_stringify( $out, 2 )."\n";
}

# Write the lock; one without entries deletes the file instead, never `{}`.
sub write_lock {
  my ( $path, $lock ) = @_;
  unless (%$lock) {
    my $bytes = encode_text($path);
    unlink $bytes or $!{ENOENT} or die 'unlink '.$path.': '.$!."\n";
    return;
  }
  write_text( $path, serialize_lock($lock) );
}

# A lock key – `skills/foo`, `codex:agents/x` – as { harness, target, type, name }. A prefix no
# harness has leaves the harness undefined; a directory no type has reads as a rule.
sub parse_lock_key {
  my ( $key ) = @_;
  my $colon   = index $key, ':';
  my $slash   = index $key, '/';
  my $harness = 'claude';
  my $target  = $key;
  if ( $colon != -1 && ( $slash == -1 || $colon < $slash ) ) {
    $harness = $HARNESS_OF_PREFIX{ substr $key, 0, $colon + 1 };
    $target  = substr $key, $colon + 1;
  }
  my ( $dir, @rest ) = split m{/}, $target, -1;
  $dir //= '';
  return { harness => $harness, target => $target, type => $TYPE_OF_DIR{$dir} // 'rule', name => join( '/', @rest ) };
}

sub key_to_type_name {
  my ( $key ) = @_;
  my $k = parse_lock_key($key);
  return { type => $k->{type}, name => $k->{name} };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Lock - A scope's lock file (skilletor.lock.json) – reading, writing, its keys

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Lock qw( read_lock key_to_type_name );

  my $lock = read_lock("$project/.claude/skilletor.lock.json");
  for my $key ( keys %$lock ) {
    my $it = key_to_type_name($key);    # { type => 'skill', name => 'perl-moo' }
    print "$it->{type} $it->{name} from $lock->{$key}{source}\n";
  }

=head1 DESCRIPTION

The reference's C<lock.ts> (spec §6.2): one lock per
scope, C<< <scope>/.claude/skilletor.lock.json >>, the ownership boundary of
what skilletor installed. A resolve reads it to keep offering what an
unreachable source or an unexpandable bundle installed before (spec §3,
§15.4); a sync writes it (L<Skilletor::Apply>), byte for byte as the reference:
keys and files sorted, two-space indent, a final newline – a lock without
entries is no file at all.

=head2 read_lock

  read_lock($path);

The entries, in file order; C<{}> when there is no file. Throws
L<Skilletor::Error::Lock> on a file it cannot read or that holds no JSON
object, worded as the reference.

=head2 serialize_lock

  my $text = serialize_lock($lock);

The lock file's text: entries and their files sorted (UTF-16 order), each entry
C<source>, C<version>, C<files> and, when set, C<skipped>, C<block> (C<true>),
C<via>, C<partial> (C<true>).

=head2 write_lock

  write_lock( $path, $lock );

Writes L</serialize_lock> atomically; an empty lock deletes the file.

=head2 parse_lock_key

  parse_lock_key('codex:skills/foo');   # { harness => 'codex', target => 'skills/foo', type => 'skill', name => 'foo' }

=head2 key_to_type_name

  key_to_type_name('agents/reviewer');   # { type => 'agent', name => 'reviewer' }

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
