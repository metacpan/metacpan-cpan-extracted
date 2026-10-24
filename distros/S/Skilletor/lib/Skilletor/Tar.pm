package Skilletor::Tar;
# ABSTRACT: The reference's minimal tar reader: safe file and dir entries only

use strict;
use warnings;

use Exporter qw( import );
use Skilletor::Error;
use Skilletor::Error::Tar;
use Skilletor::FSUtil qw( decode_utf8_lossy is_executable );
use Skilletor::JSString qw( js_trim );

our $VERSION = '0.001';

our @EXPORT_OK = qw( parse_tar strip_top_level is_reserved VERSION_FILE );

# The version of a url cache's tree, at the root of the tree (reserved there).
use constant VERSION_FILE => '.skilletor-version';

sub _read_string {
  my ( $bytes, $offset, $length ) = @_;
  my $raw = substr $bytes, $offset, $length;
  my $end = index $raw, "\0";
  return decode_utf8_lossy( $end == -1 ? $raw : substr( $raw, 0, $end ) );
}

# parseInt(s, 8) of the trimmed field: NaN (undef) when no octal digit leads it.
sub _read_octal {
  my ( $bytes, $offset, $length ) = @_;
  my $s = js_trim( _read_string( $bytes, $offset, $length ) );
  return 0 if $s eq '';
  return undef unless $s =~ /\A([-+]?)([0-7]+)/;
  my $v = oct $2;
  return $1 eq '-' ? -$v : $v;
}

sub _pax_path {
  my ( $data ) = @_;
  for my $line ( split /\n/, decode_utf8_lossy($data), -1 ) {
    return $1 if $line =~ /\A[0-9]+ path=([^\n\r\x{2028}\x{2029}]*)\z/;
  }
  return undef;
}

sub _assert_safe {
  my ( $name ) = @_;
  if ( $name eq '' || $name =~ m{\A[/\\]} || $name =~ /\A[a-zA-Z]:/ ) {
    Skilletor::Error::Tar->throw( 'unsafe tar entry (absolute path): '.( length $name ? $name : '<empty>' ) );
  }
  if ( grep { $_ eq '..' } split m{/}, $name, -1 ) {
    Skilletor::Error::Tar->throw( 'unsafe tar entry (path traversal): '.$name );
  }
}

# A decompressed tar as safe entries: { name, type => 'file' | 'dir', data, executable }.
sub parse_tar {
  my ( $buf ) = @_;
  my @entries;
  my $len    = length $buf;
  my $offset = 0;
  my ( $long_name, $pax_path );
  my $ended = 0;
  while ( $offset + 512 <= $len ) {
    my $block = substr $buf, $offset, 512;
    if ( $block !~ /[^\0]/ ) {    # end of archive
      $ended = 1;
      last;
    }

    my $raw_name = _read_string( $block, 0, 100 );
    my $mode     = _read_octal( $block, 100, 8 );
    my $prefix   = _read_string( $block, 345, 155 );
    my $size     = _read_octal( $block, 124, 12 );
    my $typeflag = substr $block, 156, 1;
    # A size that parses negative would step back over this header for ever, a non-octal one
    # (NaN) would end the walk quietly: corrupt like a failed gunzip, not unsafe – a plain error, so
    # a url source falls back to its cache.
    Skilletor::Error->throw( 'corrupt tar entry (size): '.$raw_name ) unless defined $size && $size >= 0;
    $offset += 512;
    # k145: a stream cut short inside an entry's data (or its padding) is no smaller archive.
    Skilletor::Error->throw( 'corrupt tar (truncated): '.$raw_name ) if $offset + _ceil_blocks($size) > $len;
    my $data = $size > 0 ? substr( $buf, $offset, $size ) : '';
    $offset += _ceil_blocks($size);

    if ( $typeflag eq 'L' ) {
      ( $long_name = _read_string( $data, 0, length $data ) ) =~ s/\0+\z//;
      next;
    }
    if ( $typeflag eq 'x' || $typeflag eq 'g' ) {
      $pax_path = _pax_path($data) // $pax_path;
      next;
    }
    if ( $typeflag eq '2' || $typeflag eq '1' ) {
      Skilletor::Error::Tar->throw( 'unsafe tar entry (symlink/hardlink): '.$raw_name );
    }
    my $name = $pax_path // $long_name // ( length $prefix ? $prefix.'/'.$raw_name : $raw_name );
    undef $long_name;
    undef $pax_path;

    next if $typeflag ne '0' && $typeflag ne "\0" && $typeflag ne '5';    # devices etc.
    _assert_safe($name);
    if ( $typeflag eq '5' || $name =~ m{/\z} ) {
      ( my $dir = $name ) =~ s{/+\z}{};
      push @entries, { name => $dir, type => 'dir', data => '', executable => 0 };
    }
    else {
      push @entries, { name => $name, type => 'file', data => $data, executable => is_executable($mode) };
    }
  }
  # k145: every archive ends with a zero block; running out of bytes first is a truncated one.
  Skilletor::Error->throw('corrupt tar (truncated: no end-of-archive marker)') unless $ended;
  return \@entries;
}

sub _ceil_blocks {
  my ( $size ) = @_;
  my $blocks = int( $size / 512 );
  $blocks++ if $size > 0 && $size % 512;
  return $blocks * 512;
}

# Strip a single GitHub-style top-level directory, if there is one.
sub strip_top_level {
  my ( $entries ) = @_;
  my %tops;
  for my $e (@$entries) {
    my ($top) = split m{/}, $e->{name}, 2;
    $tops{$top} = 1 if defined $top && length $top;
  }
  my $nested = grep { index( $_->{name}, '/' ) >= 0 } @$entries;
  return $entries if keys(%tops) != 1 || !$nested;
  my ($top) = keys %tops;
  my $prefix = $top.'/';
  return [
    grep { length $_->{name} }
    map {
      my $n = $_->{name};
      +{ %$_, name => $n eq $top ? '' : index( $n, $prefix ) == 0 ? substr( $n, length $prefix ) : $n };
    } @$entries
  ];
}

# An archive entry at the version file's path, or under it: never extracted.
sub is_reserved {
  my ( $name ) = @_;
  my ($first) = grep { $_ ne '' && $_ ne '.' } split m{/}, $name, -1;
  return ( defined $first && $first eq VERSION_FILE ) ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Tar - The reference's minimal tar reader: safe file and dir entries only

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Tar qw( parse_tar strip_top_level is_reserved );

  my $entries = strip_top_level( parse_tar($tar_bytes) );
  my @kept = grep { !is_reserved( $_->{name} ) } @$entries;

=head1 DESCRIPTION

The reference unpacks a url source with its own dependency-free tar reader,
not with C<tar>; reading archives the same way is what makes both
implementations' cache trees the same. Plain files and directories are kept;
GNU long names and pax C<path> records are honoured; devices and other types
are skipped; symlinks, hardlinks, absolute paths and C<..> are refused with a
L<Skilletor::Error::Tar>. A header whose size field is no non-negative octal
number is a corrupt archive – a plain L<Skilletor::Error>
C<corrupt tar entry (size): E<lt>nameE<gt>>, so a url source falls back to its
cache as for a failed download; so is an archive cut short (C<corrupt tar (truncated): ...>,
or no end-of-archive block). Of an entry's mode only the owner's executable bit is
kept. Names are decoded as UTF-8 the way Node decodes them.

=head2 parse_tar

  my $entries = parse_tar($bytes);

C<< [ { name, type => 'file' | 'dir', data, executable } ] >>.

=head2 strip_top_level

A single top-level directory (as GitHub's archives have) is stripped.

=head2 is_reserved

True for the version file's name at the tree root.

=head2 VERSION_FILE

C<.skilletor-version>.

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
