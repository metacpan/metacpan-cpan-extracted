package Skilletor::Apply;
# ABSTRACT: Apply a build plan to disk – diff, atomic writes, conflicts, removal (spec §6.1–6.3)

use strict;
use warnings;

use Errno ();
use Exporter qw( import );
use JSON::MaybeXS ();
use Path::Tiny qw( path );
use Skilletor::Entry qw( name_key );
use Skilletor::Error::Apply;
use Skilletor::FSUtil qw( atomic_write encode_text hash_bytes is_executable path_join path_resolve same_file );
use Skilletor::JSON qw( js_ordered );
use Skilletor::Lock qw( read_lock serialize_lock write_lock );

our $VERSION = '0.001';

our @EXPORT_OK = qw( apply is_valid_item_name );

my $NAME_RE = qr/\A[A-Za-z0-9._\-]+\z/;

sub is_valid_item_name { ( defined $_[0] && $_[0] =~ $NAME_RE ) ? 1 : 0 }

sub _uniq {
  my %seen;
  return grep { !$seen{$_}++ } @_;
}

sub _dirname { my ( $p ) = @_; ( my $d = $p ) =~ s{/[^/]*\z}{}; return length $d ? $d : '/' }

sub apply {
  my ( $plan, %opts ) = @_;
  my $lock_path = path_join( path_resolve( $opts{target_dir} ), 'skilletor.lock.json' );
  my $old_lock  = read_lock($lock_path);
  my $landed    = { order => [], by => {} };
  my $res;
  my $ok = eval { $res = _apply_plan( $plan, \%opts, $lock_path, $old_lock, $landed ); 1 };
  unless ($ok) {
    my $err = $@;
    _write_salvage_lock( $lock_path, $old_lock, $landed ) if @{ $landed->{order} };
    die $err;
  }
  return $res;
}

sub _entry {
  my ( $it, %fields ) = @_;
  my $e = js_ordered( source => $it->{source}, version => $it->{version}, files => $fields{files} );
  $e->{skipped} = $fields{skipped} if $fields{skipped};
  $e->{block}   = JSON::MaybeXS::true() if $fields{block};
  $e->{via}     = [ @{ $it->{via} } ] if $it->{via} && @{ $it->{via} };
  $e->{partial} = JSON::MaybeXS::true() if $fields{partial};
  return $e;
}

sub _files_of { my ( $e ) = @_; return ( $e && ref $e->{files} eq 'HASH' ) ? $e->{files} : {} }

sub _apply_plan {
  my ( $plan, $opts, $lock_path, $old_lock, $landed ) = @_;
  my $target_dir = path_resolve( $opts->{target_dir} );
  my $new_lock = js_ordered();
  my $res = {
    added => [], updated => [], removed => [], unchanged => [], skipped => [], conflicts => [], overwritten => [], written => [],
    leftInPlace => [],
  };
  my ( %dirs_touched, @touched_roots );
  my $root_for = sub { path_resolve( $opts->{root_of} ? $opts->{root_of}->( $_[0] ) : $target_dir ) };
  my $touched = sub {
    my ( $root ) = @_;
    unless ( $dirs_touched{$root} ) { $dirs_touched{$root} = { order => [], set => {} }; push @touched_roots, $root }
    return $dirs_touched{$root};
  };

  my %planned = map { ( $_->{key} => 1 ) } @$plan;
  my %keep    = map { ( $_ => 1 ) } @{ $opts->{keep} // [] };
  # Entries leaving the lock that hold files: a planned item may find one of their files at its
  # own path under a spelling equal ignoring case (k136).
  my @leaving = grep {
    my $e = $old_lock->{$_};
    !$planned{$_} && !$keep{$_} && !$e->{block} && !$e->{skipped} && %{ _files_of($e) };
  } keys %$old_lock;

  for my $it (@$plan) {
    Skilletor::Error::Apply->throw( 'invalid item name: '.$it->{name} ) unless $it->{name} =~ $NAME_RE;
    if ( $it->{inBlock} ) {
      _record_block_item( $it, $old_lock->{ $it->{key} }, $new_lock, $res );
      next;
    }
    my $root = $root_for->( $it->{key} );
    if ( $it->{skipped} ) {
      # Owns no paths: delete only what the lock says was installed.
      my @files = keys %{ _files_of( $old_lock->{ $it->{key} } ) };
      _remove_item_files( $it->{key}, $root, \@files, $touched->($root), $res );
      push @{ $res->{removed} }, $it->{key} if @files;
      push @{ $res->{skipped} }, $it->{key};
      $new_lock->{ $it->{key} } = _entry( $it, files => js_ordered(), skipped => $it->{skipped} );
      next;
    }
    # A previous skip entry owns nothing: the item counts as not yet installed.
    my $existing = ( $old_lock->{ $it->{key} } && !$old_lock->{ $it->{key} }{skipped} ) ? $old_lock->{ $it->{key} } : undef;
    my $ex_files = _files_of($existing);
    my @holders = ( $ex_files, map { _files_of( $old_lock->{$_} ) } grep { $root_for->($_) eq $root } @leaving );
    my $locked_hash = sub {
      my ( $rel ) = @_;
      return $ex_files->{$rel} // _held( $root, $rel, \@holders );
    };
    my $owned = sub { defined $locked_hash->( $_[0] ) };
    my $own = _own_path( $it->{key} );
    my %out = map { ( $_->[0] => $_->[1] ) } @{ $it->{output} };
    my @removals = grep { !exists $out{$_} } keys %$ex_files;

    # Every path of the item is checked before its first write (spec §6.3).
    my ( @found, @delete_first );
    my $conflict = sub {
      my ( $p, $not_file, $replace ) = @_;
      return if grep { $_->{path} eq $p } @found;
      my $c = { key => $it->{key}, path => $p };
      $c->{replace} = JSON::MaybeXS::true() if $replace;
      $c->{notFile} = JSON::MaybeXS::true() if $not_file;
      push @found, $c;
      push @delete_first, $p if $replace && !$not_file;
    };
    my %claims = map { ( $_ => 1 ) } @{ $it->{claims} // [] };
    for my $rel ( _uniq( @{ $it->{claims} // [] }, ( map { $_->[0] } @{ $it->{output} } ), @removals ) ) {
      my $at = _inspect( $root, $rel, $own );
      my $is_output = exists $out{$rel};
      if ( $at->{kind} eq 'blocked' ) {
        # A link, or a file, where the item needs a directory: a conflict – unless it is one of
        # the item's own files (the source turned it into a directory).
        if ( $at->{link} || !$owned->( $at->{path} ) ) { $conflict->( $at->{path}, 0, 1 ) }
        elsif ( !grep { $_ eq $at->{path} } @delete_first ) { push @delete_first, $at->{path} }
      }
      elsif ( !$is_output && !$claims{$rel} ) {
        next;    # only a removal: done after the writes
      }
      elsif ( $at->{kind} eq 'other' && ( $is_output || !$owned->($rel) ) ) {
        $conflict->( $rel, 1, 0 );
      }
      elsif ( ( $at->{kind} eq 'file' || $at->{kind} eq 'link' ) && !$owned->($rel) ) {
        $conflict->( $rel, 0, !$is_output );
      }
    }
    my @blocking = grep { $_->{notFile} || !$opts->{force} } @found;
    if (@blocking) {
      push @{ $res->{conflicts} }, @blocking;
      $new_lock->{ $it->{key} } = $old_lock->{ $it->{key} } if $old_lock->{ $it->{key} };    # left as it was
      push @{ $res->{unchanged} }, $it->{key};
      next;
    }
    _remove_file( _safe_join( $root, $_ ), $touched->($root) ) for @delete_first;

    my $entry_files = js_ordered();
    my ( $wrote, $removed_file, $took_over ) = ( 0, 0, 0 );
    my $land = sub {
      my ( $rel, $hash ) = @_;
      push @{ $res->{written} }, { key => $it->{key}, path => $rel };
      unless ( $landed->{by}{ $it->{key} } ) {
        $landed->{by}{ $it->{key} } = { item => $it, files => js_ordered() };
        push @{ $landed->{order} }, $it->{key};
      }
      $landed->{by}{ $it->{key} }{files}{$rel} = $hash;
    };

    for my $pair ( @{ $it->{output} } ) {
      my ( $rel, $bytes ) = @$pair;
      my $abs        = _safe_join( $root, $rel );
      my $desired    = hash_bytes($bytes);
      my $executable = ( $it->{executable} // {} )->{$rel} ? 1 : 0;
      my $st         = _lstat($abs);
      my $locked     = $st ? $locked_hash->($rel) : $ex_files->{$rel};
      $took_over = 1 if defined $locked && !defined $ex_files->{$rel};

      if ( $st && $st->{file} ) {
        my $disk = hash_bytes( path( encode_text($abs) )->slurp_raw );
        if ( $disk eq $desired && is_executable( $st->{mode} ) == $executable ) {
          # Already correct; adopted into the lock (a stale hash updates silently).
          $entry_files->{$rel} = $desired;
          $land->( $rel, $desired ) unless defined $locked;    # adopted (force)
          next;
        }
        atomic_write( encode_text($abs), $bytes, $executable );
        if ( defined $locked && $disk ne $desired && $disk ne $locked ) {
          push @{ $res->{overwritten} }, { key => $it->{key}, path => $rel };    # local drift; the bit alone is none
        }
      }
      else {
        # Missing, or a link the lock owns (or force adopts): the rename replaces the link itself.
        atomic_write( encode_text($abs), $bytes, $executable );
        push @{ $res->{overwritten} }, { key => $it->{key}, path => $rel } if $st && defined $locked;
      }
      $wrote = 1;
      $entry_files->{$rel} = $desired;
      $land->( $rel, $desired );
    }

    # Files the item no longer contains but the lock still tracks – save one that is a file of
    # its output under another spelling (k136).
    my $outputs = [ { map { ( $_->[0] => '' ) } @{ $it->{output} } } ];
    my @gone = grep { !defined _held( $root, $_, $outputs ) } @removals;
    $removed_file = 1 if _remove_item_files( $it->{key}, $root, \@gone, $touched->($root), $res );
    $took_over = 1 if @gone < @removals;

    $new_lock->{ $it->{key} } = _entry( $it, files => $entry_files ) if %$entry_files;

    if ( !$existing ) {
      if   ( $wrote || $took_over ) { push @{ $res->{added} },     $it->{key} }
      else                          { push @{ $res->{unchanged} }, $it->{key} }    # fully conflicted
    }
    elsif ( $wrote || $removed_file || $took_over || $existing->{partial} ) {
      push @{ $res->{updated} }, $it->{key};    # a partial entry: the run that left it never reported it
    }
    else {
      push @{ $res->{unchanged} }, $it->{key};
    }
  }

  # Items no longer declared: their locked files go (unless kept) – but none the new lock holds
  # under another spelling (k136).
  my $kept = sub {
    my ( $root ) = @_;
    return [ map { _files_of( $new_lock->{$_} ) } grep { !$new_lock->{$_}{block} && $root_for->($_) eq $root } keys %$new_lock ];
  };
  for my $key ( keys %$old_lock ) {
    next if $planned{$key};
    if ( $keep{$key} ) {
      $new_lock->{$key} = $old_lock->{$key};    # preserved untouched
      next;
    }
    unless ( $old_lock->{$key}{block} ) {
      my $root    = $root_for->($key);
      my $holders = $kept->($root);
      my @files   = grep { !defined _held( $root, $_, $holders ) } keys %{ _files_of( $old_lock->{$key} ) };
      _remove_item_files( $key, $root, \@files, $touched->($root), $res );
    }
    push @{ $res->{removed} }, $key unless $old_lock->{$key}{skipped};    # a skip entry had nothing installed
  }

  _prune_empty_dirs( $dirs_touched{$_}{order}, $_ ) for @touched_roots;

  # The lock is rewritten only when it changed (no-op runs stay write-free); without entries it
  # goes, a `{}` an earlier version left included.
  my $empty_left = !%$new_lock && -e encode_text($lock_path);
  write_lock( $lock_path, $new_lock ) if $empty_left || serialize_lock($new_lock) ne serialize_lock($old_lock);
  return $res;
}

# The lock after a run that threw (spec §6.2, k71): the old lock plus every file the run wrote
# or adopted, under its item marked partial. Best effort.
sub _write_salvage_lock {
  my ( $lock_path, $old_lock, $landed ) = @_;
  my $lock = js_ordered( map { ( $_ => $old_lock->{$_} ) } keys %$old_lock );
  for my $key ( @{ $landed->{order} } ) {
    my ( $item, $files ) = @{ $landed->{by}{$key} }{qw( item files )};
    my $prev = ( $old_lock->{$key} && !$old_lock->{$key}{skipped} ) ? $old_lock->{$key} : undef;
    my $merged = js_ordered( %{ _files_of($prev) } );
    $merged->{$_} = $files->{$_} for keys %$files;
    $lock->{$key} = _entry( $item, files => $merged, partial => 1 );
  }
  eval { write_lock( $lock_path, $lock ); 1 };
}

# Lock and report a block section by its hash; no disk access.
sub _record_block_item {
  my ( $it, $prev, $new_lock, $res ) = @_;
  my $had = ( $prev && !$prev->{skipped} ) ? 1 : 0;
  if ( $it->{skipped} ) {
    push @{ $res->{removed} }, $it->{key} if $had;
    push @{ $res->{skipped} }, $it->{key};
    $new_lock->{ $it->{key} } = _entry( $it, files => js_ordered(), skipped => $it->{skipped}, block => 1 );
    return;
  }
  my $files = js_ordered( map { ( $_->[0] => hash_bytes( $_->[1] ) ) } @{ $it->{output} } );
  $new_lock->{ $it->{key} } = _entry( $it, files => $files, block => 1 );
  if    ( !$had ) { push @{ $res->{added} }, $it->{key} }
  elsif ( Skilletor::JSON::js_stringify( $prev->{files} ) ne Skilletor::JSON::js_stringify($files) ) { push @{ $res->{updated} }, $it->{key} }
  else  { push @{ $res->{unchanged} }, $it->{key} }
}

# The hash `holders` give the file at $rel under another spelling of it (k136): a path equal
# ignoring case that is the same file on disk.
sub _held {
  my ( $root, $rel, $holders ) = @_;
  my $k = name_key($rel);
  for my $files (@$holders) {
    for my $other ( keys %$files ) {
      next if $other eq $rel || name_key($other) ne $k;
      return $files->{$other} if same_file( _safe_join( $root, $other ), _safe_join( $root, $rel ) );
    }
  }
  return undef;
}

sub _safe_join {
  my ( $root, $rel ) = @_;
  my $abs = path_resolve( path_join( $root, $rel ) );
  Skilletor::Error::Apply->throw( 'path escapes target: '.$rel ) if $abs ne $root && index( $abs, $root.'/' ) != 0;
  return $abs;
}

# The item's own path under its root: the lock key without a `<prefix>:`.
sub _own_path {
  my ( $key ) = @_;
  my ( $colon, $slash ) = ( index( $key, ':' ), index( $key, '/' ) );
  return ( $colon != -1 && ( $slash == -1 || $colon < $slash ) ) ? substr( $key, $colon + 1 ) : $key;
}

# lstat answering undef for a missing path (also below a non-directory).
sub _lstat {
  my ( $abs ) = @_;
  my @st = lstat encode_text($abs);
  unless (@st) {
    return undef if $!{ENOENT} || $!{ENOTDIR};
    die 'lstat '.$abs.': '.$!."\n";
  }
  return { link => ( -l _ ? 1 : 0 ), dir => ( -d _ ? 1 : 0 ), file => ( -f _ ? 1 : 0 ), mode => $st[2] };
}

# What is at $rel (spec §6.3), looking at every component from the item's own path down
# without following links.
sub _inspect {
  my ( $root, $rel, $own ) = @_;
  my $abs   = _safe_join( $root, $rel );
  my @parts = split m{/}, ( $abs eq $root ? '' : substr( $abs, length($root) + 1 ) ), -1;
  @parts = ('') unless @parts;
  my @own_parts = split m{/}, $own, -1;
  my $under = @parts > @own_parts && !grep { $own_parts[$_] ne $parts[$_] } 0 .. $#own_parts;
  my $first = $under ? $#own_parts : $#parts;
  for my $i ( $first .. $#parts ) {
    my $st = _lstat( path_join( $root, @parts[ 0 .. $i ] ) ) or return { kind => 'absent' };
    if ( $i < $#parts ) {
      return { kind => 'blocked', path => join( '/', @parts[ 0 .. $i ] ), link => $st->{link} } unless $st->{dir} && !$st->{link};
    }
    elsif ( $st->{link} ) {
      return { kind => 'link' };
    }
    else {
      return { kind => $st->{file} ? 'file' : 'other' };
    }
  }
  return { kind => 'absent' };
}

# Delete an item's lock-owned files – a link there itself, never through a link at or below the
# item's path (reported in leftInPlace). True when anything was deleted.
sub _remove_item_files {
  my ( $key, $root, $files, $dirs, $res ) = @_;
  my $own = _own_path($key);
  my $removed = 0;
  for my $rel (@$files) {
    my $at = _inspect( $root, $rel, $own );
    if ( $at->{kind} eq 'blocked' ) {
      if ( $at->{link} && !grep { $_->{key} eq $key && $_->{path} eq $at->{path} } @{ $res->{leftInPlace} } ) {
        push @{ $res->{leftInPlace} }, { key => $key, path => $at->{path} };
      }
    }
    elsif ( $at->{kind} eq 'file' || $at->{kind} eq 'link' ) {
      _remove_file( _safe_join( $root, $rel ), $dirs );
      $removed = 1;
    }
  }
  return $removed;
}

# Delete a file or link (never a directory, never through the final link).
sub _remove_file {
  my ( $abs, $dirs ) = @_;
  my $st = _lstat($abs);
  return unless $st && ( $st->{link} || !$st->{dir} );
  unlink encode_text($abs) or $!{ENOENT} or die 'unlink '.$abs.': '.$!."\n";
  my $d = _dirname($abs);
  push @{ $dirs->{order} }, $d unless $dirs->{set}{$d}++;
}

# Remove now-empty directories deleted from, walking up to (not including) the root; a link on
# the way ends the walk.
sub _prune_empty_dirs {
  my ( $dirs, $root ) = @_;
  for my $start ( sort { length($b) <=> length($a) } @$dirs ) {
    my $dir = $start;
    while ( $dir ne $root && index( $dir, $root.'/' ) == 0 ) {
      my $st = _lstat($dir);
      last unless $st && $st->{dir} && !$st->{link};
      opendir( my $dh, encode_text($dir) ) or last;
      my $empty = !grep { $_ ne '.' && $_ ne '..' } readdir $dh;
      closedir $dh;
      last unless $empty;
      rmdir encode_text($dir) or die 'rmdir '.$dir.': '.$!."\n";
      $dir = _dirname($dir);
    }
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Apply - Apply a build plan to disk – diff, atomic writes, conflicts, removal (spec §6.1–6.3)

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Apply qw( apply );

  my $res = apply(
    [ { key => 'skills/foo', type => 'skill', name => 'foo', source => 'shared', version => 'git:ab12cd3',
        output => [ [ 'skills/foo/SKILL.md', $bytes ] ], executable => { 'skills/foo/run.sh' => 1 } } ],
    target_dir => "$home/.claude",
    force      => 0,
    keep       => [ 'skills/offline-item' ],
  );
  # { added, updated, removed, unchanged, skipped, conflicts, overwritten, written, leftInPlace }

=head1 DESCRIPTION

The port of the reference's C<apply.ts> (spec §6.1–6.3). It compares each
item's built output – bytes and the owner's executable bit – with the disk and
the lock, writes only the differences (atomically: a temp file beside the
target, then a rename), removes the files an item no longer contains and
deletes the items no longer declared. The lock is the ownership boundary: only
paths it holds are ever overwritten or deleted.

=over 4

=item * Every path of an item is checked before its first write. A path on disk
that the lock does not hold, or a symbolic link at or below the item's own
path, is a conflict and blocks the whole item – nothing of it is written or
removed – unless C<force> adopts the file, replaces the link or deletes the
file at a claimed path (an agent's plain name beside its C<.local.> file). A
directory where a file goes blocks it even with C<force>.

=item * A managed file that diverged from its lock hash is overwritten and
named in C<overwritten>; a file whose bit alone is wrong is rewritten silently.

=item * Nothing is written or deleted through a link at or below an item's
path; a removal stopped by one is named in C<leftInPlace>.

=item * An error after the first write leaves a lock that owns what landed,
those entries marked C<partial> (k71), so a retry resumes.

=item * Paths equal ignoring case that are one file on disk (a case-insensitive
file system, k136) are one path.

=back

The lock is rewritten only when its bytes change, and deleted when it is left
without entries.

=head2 apply

  apply( \@plan, target_dir => $dir, root_of => sub { $root_for_key }, force => 0, keep => \@keys );

A plan item: C<< { key, type, name, source, version, output => [ [ rel, bytes ] ],
executable => { rel => 1 }?, skipped?, inBlock?, via => [...]?, claims => [...]? } >>.
C<root_of> answers the root a lock key's files live under (default
C<target_dir>, which also holds the lock). C<keep> names lock keys preserved
untouched although not in the plan.

The result holds lock keys in C<added>, C<updated>, C<removed>, C<unchanged>,
C<skipped>; C<< { key, path, replace?, notFile? } >> in C<conflicts>;
C<< { key, path } >> in C<overwritten>, C<written> (written or adopted this run)
and C<leftInPlace>. Throws L<Skilletor::Error::Apply> for an invalid item name.

=head2 is_valid_item_name

True for a name the apply accepts: ASCII letters, digits, C<.>, C<_>, C<->.

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
