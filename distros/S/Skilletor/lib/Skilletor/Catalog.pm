package Skilletor::Catalog;
# ABSTRACT: Scan a source tree into its installable items, bundles and source metadata

use strict;
use warnings;

use Errno ();
use Scalar::Util qw( blessed );
use Skilletor::Bundles qw( parse_bundle );
use Skilletor::Entry qw( name_key );
use Skilletor::Error::Catalog;
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text inner_segments node_fs_error path_join );
use Skilletor::JSON qw( js_parse js_sort_keys js_stringify js_type );
use Skilletor::JSString qw( js_trim js_ws_re );

our $VERSION = '0.001';

# The `.gitignore` skilletor writes into every skill it installs (spec §6.4): a skill directory
# holding exactly this is one of its installed copies.
use constant SKILL_GITIGNORE => "# installed by skilletor, not committed (\"gitignore\": false in skilletor.json to commit)\n*\n";

# The name prefix of installed agents and rules (spec §6.4).
use constant LOCAL_PREFIX => '.local.';

my @TYPE_DIRS = ( [ skills => 'skill' ], [ agents => 'agent' ], [ rules => 'rule' ] );

my $DOT = qr/[^\n\r\x{2028}\x{2029}]/;    # JavaScript's `.`
my $WS  = js_ws_re();

sub _fail { Skilletor::Error::Catalog->throw( $_[0] ) }

sub _message { my ( $err ) = @_; return blessed $err && $err->can('message') ? $err->message : "$err" =~ s/ at \S+ line \d+\.?\n?\z//r }

#### File system, as node:fs sees it ###################################

# existsSync: follows symlinks, false on any error.
sub _exists { -e encode_text( $_[0] ) ? 1 : 0 }

# lstatSync: { dir, file, link }; throws Node's message.
sub _lstat {
  my ( $path ) = @_;
  lstat( encode_text($path) ) or _fail( node_fs_error( 0 + $!, 'lstat', $path ) );
  return { dir => ( -d _ ? 1 : 0 ), file => ( -f _ ? 1 : 0 ), link => ( -l _ ? 1 : 0 ) };
}

# readdirSync: the names, in libuv's order (bytes, strcmp); throws Node's message.
sub _readdir {
  my ( $path ) = @_;
  opendir( my $dh, encode_text($path) ) or _fail( node_fs_error( 0 + $!, 'scandir', $path ) );
  my @names = sort grep { $_ ne '.' && $_ ne '..' } readdir $dh;
  closedir $dh;
  return map { decode_utf8_lossy($_) } @names;
}

# readFileSync(path, "utf8").
sub _read_text {
  my ( $path ) = @_;
  my $bytes = encode_text($path);
  _fail( node_fs_error( Errno::EISDIR(), 'read' ) ) if -d $bytes;
  open( my $fh, '<:raw', $bytes ) or _fail( node_fs_error( 0 + $!, 'open', $path ) );
  local $/;
  my $data = <$fh>;
  close $fh;
  return decode_utf8_lossy( $data // '' );
}

# Is `path` a directory, not a symlink? False when it cannot be read.
sub _is_plain_dir {
  my ( $path ) = @_;
  return ( lstat( encode_text($path) ) && -d _ ) ? 1 : 0;
}

sub _is_dangling_link {
  my ( $path ) = @_;
  return ( lstat( encode_text($path) ) && -l _ ) ? 1 : 0;
}

# Throw if `path` is a symlink; its lstat otherwise.
sub _no_symlink {
  my ( $path ) = @_;
  my $st = _lstat($path);
  _fail( 'symlink not allowed in source: '.$path ) if $st->{link};
  return $st;
}

sub _basename { my ( $rel ) = @_; return ( split m{/}, $rel )[-1] }

# String comparison as JavaScript's `<` sees it (UTF-16 code units).
sub _js_sorted { js_sort_keys(@_) }

sub _js_cmp {
  my ( $a, $b ) = @_;
  return 0 if $a eq $b;
  my ($first) = js_sort_keys( $a, $b );
  return $first eq $a ? -1 : 1;
}

#### The scan ##########################################################

sub scan {
  my ( $class, $dir, $paths ) = @_;
  if ( defined $paths ) {
    my $items = _path_skills( $dir, ref $paths ? $paths : [$paths] );
    return { items => $items, bundles => [], meta => _read_source_meta($dir) };
  }
  my @items;
  for my $td (@TYPE_DIRS) {
    my ( $sub, $type ) = @$td;
    my $type_dir = path_join( $dir, $sub );
    next unless _exists($type_dir);
    _no_symlink($type_dir);
    my @found;    # a skill per directory, an agent or rule per file
    for my $entry ( _readdir($type_dir) ) {
      my $p  = path_join( $type_dir, $entry );
      my $st = _no_symlink($p);
      if ( $type eq 'skill' ) {
        next unless $st->{dir};
        my $file = _skill_file($p) // next;
        push @found, _skill_item( $dir, $p, $sub.'/'.$entry, $file );
      }
      else {
        next unless $st->{file};
        my $name = _item_name($entry) // next;
        push @found, { type => $type, name => $name, files => [ $sub.'/'.$entry ] };
      }
    }
    # Both `<name>.md` and `<name>.md.njk` is an error of that item, like a bundle's `.yaml`
    # beside its `.yml` (spec §4.1, §15.4); so are two spellings of one name (k135).
    for my $i ( _one_name( \@found, $type eq 'skill' ? \&_in_dirs : \&_both_exist ) ) {
      if ( !defined $i->{error} && $type ne 'skill' ) {
        my $d = _description_of( path_join( $dir, $i->{files}[0] ) );
        $i = { %$i, ( defined $d ? ( description => $d ) : () ) };
      }
      push @items, $i;
    }
  }
  push @items, _plugin_skills( $dir, [@items] );
  push @items, _claude_items( $dir, [@items] );
  my $bundles = _scan_bundles($dir);
  return { items => \@items, bundles => $bundles, meta => _read_source_meta($dir) };
}

# A top-level frontmatter scalar per key (name, description): the catalog's own reader, read raw.
sub _frontmatter {
  my ( $text ) = @_;
  # A BOM and CRLF line ends are no part of a value.
  $text =~ s/\A\x{FEFF}//;
  $text =~ s/\r\n/\n/g;
  return {} unless substr( $text, 0, 3 ) eq '---';
  my $first_nl = index $text, "\n";
  return {} if $first_nl == -1;
  my $close = index $text, "\n---", $first_nl;
  return {} if $close == -1;
  my $block = substr $text, $first_nl + 1, $close - $first_nl - 1;
  my %out;
  for my $line ( split /\n/, $block, -1 ) {
    $out{$1} = _unquote( js_trim($2) ) if $line =~ /\A([A-Za-z0-9_-]+):$WS*($DOT*)\z/;
  }
  return \%out;
}

sub _unquote {
  my ( $v ) = @_;
  if ( length($v) >= 2 ) {
    my ( $f, $l ) = ( substr( $v, 0, 1 ), substr( $v, -1 ) );
    return substr( $v, 1, -1 ) if ( $f eq '"' && $l eq '"' ) || ( $f eq "'" && $l eq "'" );
  }
  return $v;
}

sub _description_of { _frontmatter( _read_text( $_[0] ) )->{description} }

# SKILL.md or SKILL.md.njk in a skill directory.
sub _skill_file {
  my ( $dir ) = @_;
  for my $candidate ( 'SKILL.md', 'SKILL.md.njk' ) {
    my $p = path_join( $dir, $candidate );
    next unless _exists($p);
    _no_symlink($p);
    return $p;
  }
  return undef;
}

# All files under $abs (whose path relative to the source is $rel), relative, sorted; no symlinks.
sub _walk_files {
  my ( $abs, $rel ) = @_;
  my @out;
  for my $entry ( _readdir($abs) ) {
    my $p  = path_join( $abs, $entry );
    my $st = _no_symlink($p);
    if    ( $st->{dir} )  { push @out, _walk_files( $p, $rel.'/'.$entry ) }
    elsif ( $st->{file} ) { push @out, $rel.'/'.$entry }
  }
  return _js_sorted(@out);
}

# The skill in $skill_dir (relative: $rel), whose main file is $file. `f` beside `f.njk`, which
# both install as `f`, is an error of the skill naming every such pair (k113).
sub _skill_item {
  my ( $dir, $skill_dir, $rel, $file ) = @_;
  my @files = _walk_files( $skill_dir, $rel );
  my %have  = map { $_ => 1 } @files;
  my @twice = grep { !/\.njk\z/ && $have{ $_.'.njk' } } @files;
  my $item  = { type => 'skill', name => _basename($rel), files => \@files, dir => $rel };
  my $main  = $rel.'/'._basename($file);
  unless ( grep { $_ eq $main } @twice ) {
    my $d = _description_of($file);
    $item->{description} = $d if defined $d;
  }
  $item->{error} = join '; ', map { 'both '.$_.' and '.$_.'.njk exist' } @twice if @twice;
  return $item;
}

# `<name>.md` or `<name>.md.njk`: the name.
sub _item_name {
  my ( $file_name ) = @_;
  return $file_name =~ /\A($DOT+?)\.md(?:\.njk)?\z/ ? $1 : undef;
}

# `a`, `a and b`, `a, b and c`.
sub _listed {
  my ( @xs ) = @_;
  return join '', @xs if @xs < 2;
  return join( ', ', @xs[ 0 .. $#xs - 1 ] ).' and '.$xs[-1];
}

sub _in_dirs {
  my ( $where, $why ) = @_;
  return 'found in '.scalar(@$where).' directories'.$why.': '._listed(@$where);
}

sub _both_exist {
  my ( $where, $why ) = @_;
  return ( @$where == 2 ? 'both ' : '' )._listed(@$where).' exist'.$why;
}

# One item per name ignoring case (k127, k135), in first-seen order; a name found more than once
# is an error of each of its spellings.
sub _one_name {
  my ( $items, $error ) = @_;
  my ( %groups, @order );
  for my $item (@$items) {
    my $key = name_key( $item->{name} );
    push @order, $key unless $groups{$key};
    push @{ $groups{$key} }, $item;
  }
  my @out;
  for my $key (@order) {
    my $group = $groups{$key};
    if ( @$group == 1 ) {
      push @out, $group->[0];
      next;
    }
    my ( %seen, @names );
    for my $i (@$group) { push @names, $i->{name} unless $seen{ $i->{name} }++ }
    my @where = _js_sorted( map { $_->{type} eq 'skill' ? $_->{dir} : $_->{files}[0] } @$group );
    my $why   = @names > 1 ? ', names equal ignoring case' : '';
    my @files = _js_sorted( map { @{ $_->{files} } } @$group );
    push @out, map { +{ type => $group->[0]{type}, name => $_, files => [@files], error => $error->( \@where, $why ) } } @names;
  }
  return @out;
}

# Items of the Claude project layout, `.claude/{skills,agents,rules}` (k96), best effort.
sub _claude_items {
  my ( $dir, $found ) = @_;
  my @out;
  my $base = path_join( $dir, '.claude' );
  return () unless _is_plain_dir($base);
  my %known = map { ( $_->{type}.':'.name_key( $_->{name} ) => 1 ) } @$found;
  for my $td (@TYPE_DIRS) {
    my ( $sub, $type ) = @$td;
    my $type_dir = path_join( $base, $sub );
    next unless _is_plain_dir($type_dir);
    my @entries = eval { _js_sorted( _readdir($type_dir) ) } or next;
    my @here;
    for my $entry (@entries) {
      my $item = eval { _claude_item( $dir, $type_dir, '.claude/'.$sub, $entry, $type ) };
      next if $@;    # a symlink or an unreadable file: this item only
      next if !$item || $known{ $type.':'.name_key( $item->{name} ) } || grep { $_->{name} eq $item->{name} } @here;
      push @here, $item;
    }
    push @out, _one_name( \@here, $type eq 'skill' ? \&_in_dirs : \&_both_exist );
  }
  return @out;
}

sub _claude_item {
  my ( $dir, $type_dir, $rel_dir, $entry, $type ) = @_;
  my $p  = path_join( $type_dir, $entry );
  my $st = _no_symlink($p);
  if ( $type eq 'skill' ) {
    return undef unless $st->{dir};
    my $file = _skill_file($p) // return undef;
    return undef if _is_installed_copy($p);
    return _skill_item( $dir, $p, $rel_dir.'/'.$entry, $file );
  }
  return undef unless $st->{file};
  my $name = _item_name($entry);
  return undef if !defined $name || index( $name, LOCAL_PREFIX ) == 0;
  my $d = _description_of($p);
  return { type => $type, name => $name, ( defined $d ? ( description => $d ) : () ), files => [ $rel_dir.'/'.$entry ], dir => $rel_dir };
}

# Is the skill directory one of skilletor's own installed copies (spec §6.4)?
sub _is_installed_copy {
  my ( $skill_dir ) = @_;
  my $gitignore = path_join( $skill_dir, '.gitignore' );
  return 0 unless lstat( encode_text($gitignore) ) && -f _;
  my $text = eval { _read_text($gitignore) };
  return ( defined $text && $text eq SKILL_GITIGNORE ) ? 1 : 0;
}

# Skills `.claude-plugin/plugin.json` lists that $found does not hold (by directory).
sub _plugin_skills {
  my ( $dir, $found ) = @_;
  my $pdir = path_join( $dir, '.claude-plugin' );
  my $p    = path_join( $pdir, 'plugin.json' );
  return () unless _exists($p);
  _no_symlink($pdir);
  _no_symlink($p);
  my $parsed;
  unless ( eval { $parsed = js_parse( _read_text($p) ); 1 } ) {
    _fail( $p.': invalid JSON ('._message($@).')' );
  }
  return () unless js_type($parsed) eq 'object';
  return () unless exists $parsed->{skills};
  my $raw   = $parsed->{skills};
  my $paths = js_type($raw) eq 'string' ? [$raw] : $raw;
  unless ( js_type($paths) eq 'array' && !grep { js_type($_) ne 'string' } @$paths ) {
    _fail( $p.': "skills" must be a string or an array of strings' );
  }

  my ( %dirs_of, @out );
  my $known = sub { my ( $name, $rel ) = @_; push @{ $dirs_of{ name_key($name) } }, $rel };
  for my $it (@$found) {
    $known->( $it->{name}, $it->{dir} // 'skills/'.$it->{name} ) if $it->{type} eq 'skill';
  }
  my $add = sub {
    my ( $skill_dir, $rel, $file ) = @_;
    my $name = _basename($rel);
    my @dirs = @{ $dirs_of{ name_key($name) } // [] };
    return if grep { $_ eq $rel } @dirs;
    if (@dirs) {
      my $why = ( grep { _basename($_) ne $name } @dirs ) ? ', names equal ignoring case' : '';
      _fail( $p.': skill "'.$name.'" found twice'.$why.': '.$dirs[0].' and '.$rel );
    }
    $known->( $name, $rel );
    push @out, _skill_item( $dir, $skill_dir, $rel, $file );
  };
  for my $entry (@$paths) {
    my ( $target, $rel ) = _inner_dir( $dir, $p.': skills path', $entry );
    if ( my $file = _skill_file($target) ) {
      $add->( $target, $rel, $file );
      next;
    }
    for my $child ( _js_sorted( _readdir($target) ) ) {
      my $c = path_join( $target, $child );
      next unless _no_symlink($c)->{dir};
      my $f = _skill_file($c) // next;
      $add->( $c, $rel.'/'.$child, $f );
    }
  }
  return @out;
}

# The skills beneath a source entry's `path` values (spec §4.1, k126), sorted by name.
sub _path_skills {
  my ( $dir, $paths ) = @_;
  my ( %found, @order );    # a skill per directory, relative to the source
  my $visit;
  $visit = sub {
    my ( $cur, $rel, $named ) = @_;
    if ( my $file = _skill_file($cur) ) {
      return if _is_installed_copy($cur);
      my $item = _skill_item( $dir, $cur, $rel, $file );
      unless ( $found{ $item->{dir} } ) {
        $found{ $item->{dir} } = $item;
        push @order, $item->{dir};
      }
      return;
    }
    return if !$named && substr( _basename($rel), 0, 1 ) eq '.';
    for my $entry ( _js_sorted( _readdir($cur) ) ) {
      my $p = path_join( $cur, $entry );
      $visit->( $p, $rel.'/'.$entry, 0 ) if _is_plain_dir($p);
    }
  };
  my $ok = eval {
    for my $entry (@$paths) {
      my ( $abs, $rel ) = _inner_dir( $dir, '"path"', $entry );
      $visit->( $abs, $rel, 1 );
    }
    1;
  };
  my $err = $@;
  undef $visit;
  die $err unless $ok;
  return [ sort { _js_cmp( $a->{name}, $b->{name} ) } _one_name( [ map { $found{$_} } @order ], \&_in_dirs ) ];
}

# One path of a source – a plugin.json `skills` path, a source entry's `path` – as a directory
# inside the source: (absolute, relative). Every segment is checked; neither `..` nor a symlink
# can leave the source root.
sub _inner_dir {
  my ( $dir, $what, $entry ) = @_;
  my $segments = inner_segments($entry);
  _fail( $what.' must not be absolute: '.$entry ) if !ref $segments && $segments eq 'absolute';
  _fail( $what.' must not contain "..": '.$entry ) if !ref $segments && $segments eq 'dotdot';
  # Its name would be the source root's basename, i.e. the cache directory's.
  _fail( $what.' must not be the source root: '.js_stringify($entry) ) unless ref $segments;
  my $cur = $dir;
  for my $seg (@$segments) {
    $cur = path_join( $cur, $seg );
    _fail( $what.' does not exist: '.$entry ) if !_exists($cur) && !_is_dangling_link($cur);
    _no_symlink($cur);
  }
  _fail( $what.' is not a directory: '.$entry ) unless _lstat($cur)->{dir};
  return ( $cur, join '/', @$segments );
}

# `bundles/<name>.yaml|.yml`; both for one name is an error of that bundle.
sub _scan_bundles {
  my ( $dir ) = @_;
  my $bdir = path_join( $dir, 'bundles' );
  return [] unless _exists($bdir);
  _no_symlink($bdir);
  my ( %by_name, @order );
  for my $entry ( _js_sorted( _readdir($bdir) ) ) {
    my ($name) = $entry =~ /\A($DOT+)\.ya?ml\z/ or next;
    my $p = path_join( $bdir, $entry );
    next unless _no_symlink($p)->{file};
    push @order, $name unless $by_name{$name};
    push @{ $by_name{$name} }, 'bundles/'.$entry;
  }
  my @out;
  for my $name (@order) {
    my $files = $by_name{$name};
    if ( @$files > 1 ) {
      push @out, { name => $name, files => $files, error => 'both '.join( ' and ', @$files ).' exist' };
      next;
    }
    my $def;
    if ( eval { $def = parse_bundle( _read_text( path_join( $dir, $files->[0] ) ) ); 1 } ) {
      push @out, { name => $name, files => $files, def => $def };
      next;
    }
    my $err = $@;
    die $err unless blessed $err && $err->isa('Skilletor::Error::Bundle');
    push @out, { name => $name, files => $files, error => $files->[0].': '.$err->message };
  }
  return \@out;
}

sub _read_source_meta {
  my ( $dir ) = @_;
  my $p = path_join( $dir, 'skilletor.json' );
  return {} unless _exists($p);
  _no_symlink($p);
  my $parsed;
  unless ( eval { $parsed = js_parse( _read_text($p) ); 1 } ) {
    _fail( $p.': invalid JSON ('._message($@).')' );
  }
  my $type = js_type($parsed);
  return {} unless $type eq 'object' || $type eq 'array';
  return {} if $type eq 'array';    # no own `description` or `vars`
  my %meta;
  $meta{description} = $parsed->{description} if js_type( $parsed->{description} ) eq 'string';
  # k145: defaults are keyed by name; an array (or anything else) would spread by index.
  if ( exists $parsed->{vars} ) {
    _fail( $p.': "vars" must be an object' ) unless js_type( $parsed->{vars} ) eq 'object';
    $meta{vars} = $parsed->{vars};
  }
  return \%meta;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Catalog - Scan a source tree into its installable items, bundles and source metadata

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Skilletor::Catalog;

  my $cat = Skilletor::Catalog->scan($source_dir);            # the source layout
  my $sub = Skilletor::Catalog->scan( $source_dir, ['tools'] );   # a source's `path`

  for my $item ( @{ $cat->{items} } ) {
    # { type => 'skill', name => 'perl-moo', dir => 'skills/perl-moo',
    #   files => [ 'skills/perl-moo/SKILL.md', ... ], description => '...', error? }
  }

=head1 DESCRIPTION

The reference's C<catalog.ts> (spec §4.1): what a source tree offers.

  skills/<name>/SKILL.md[.njk] + companion files
  agents/<name>.md[.njk]
  rules/<name>.md[.njk]
  bundles/<name>.yaml|.yml            named item sets (spec §15)
  skilletor.json                      { description, vars }
  .claude-plugin/plugin.json          a Claude plugin's `skills` paths
  .claude/skills|agents|rules/        the Claude project layout, best effort

With a source's C<path> the items are the skills beneath those paths and
nothing else (no bundles, no other layout). Names come from the paths;
descriptions from the main file's frontmatter, read raw – a C<.njk> file is
never rendered for it. A symlink in the tree fails the scan (in C<.claude/> it
is skipped); an agent with both C<.md> and C<.md.njk>, a skill holding C<f>
beside C<f.njk>, or one name (ignoring case) in several places is an item
carrying an C<error>, never a failed scan. Every message is the reference's;
a failing file system call reads as Node's.

=head2 scan

  Skilletor::Catalog->scan( $dir, $paths );

C<< { items => [...], bundles => [ { name, files, def | error } ], meta => { description?, vars? } } >>.
Item files are relative to C<$dir>, C</>-separated, sorted. Throws
L<Skilletor::Error::Catalog>.

=head2 SKILL_GITIGNORE

The C<.gitignore> skilletor puts into an installed skill.

=head2 LOCAL_PREFIX

C<.local.>, the name prefix of installed agents and rules.

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
