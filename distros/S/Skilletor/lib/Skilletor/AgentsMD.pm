package Skilletor::AgentsMD;
# ABSTRACT: The Codex rules file, the pointer block in a Codex AGENTS.md, and the checks of Codex's config.toml

use strict;
use warnings;
use utf8;

use Exporter qw( import );
use Skilletor::Error::Block;
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text node_fs_error );
use Skilletor::JSString qw( js_trim js_ws_re );

our $VERSION = '0.008000';

our @EXPORT_OK = qw(
  BEGIN_MARKER END_MARKER NOTE RULES_FILE RULES_MARKER MARKER_LINE normalize_section
  rules_file_text parse_rules_file pointer_lines parse_block with_block inspect_agents_md
  project_doc_limit codex_hook_trusted
);

use constant BEGIN_MARKER => '<!-- skilletor:begin -->';
use constant END_MARKER   => '<!-- skilletor:end -->';
use constant NOTE         => '<!-- managed by skilletor — edits inside are overwritten -->';
use constant RULES_FILE   => 'skilletor-rules.md';
use constant RULES_MARKER => '<!-- skilletor:rules';

use constant RULES_NOTE => '<!-- managed by skilletor — edits are overwritten; change the rule in its source -->';

# Any skilletor marker line; a rule body must not contain one. `\b` with JavaScript's ASCII
# word characters, so `<!-- skilletor:ruleé` is one too.
use constant MARKER_LINE => qr/\A<!-- skilletor:(?:begin|end|rules?)\b/a;

my $WS = js_ws_re();

# JavaScript's `\S` and `.` (no line terminator), for the reference's patterns.
my $NOT_WS = qr/[^\t\n\x{0B}\f\r \x{A0}\x{1680}\x{2000}-\x{200A}\x{2028}\x{2029}\x{202F}\x{205F}\x{3000}\x{FEFF}]/;
my $DOT    = qr/[^\n\r\x{2028}\x{2029}]/;

my $RULE_RE = qr/\A<!-- skilletor:rule ($NOT_WS+) source=($DOT*) -->\z/;

sub normalize_section {
  my ( $text ) = @_;
  $text =~ s/\A(?:[ \t]*\r?\n)+//;
  $text =~ s/$WS+\z//;
  return $text."\n";
}

# text.split("\n"): an empty text is one empty line.
sub _lines {
  my ( $text ) = @_;
  return length $text ? split( /\n/, $text, -1 ) : ('');
}

# The rule sections among the lines, each running to the next rule marker: { name => { source,
# text } }, a later section of one name replacing the earlier one.
sub _parse_sections {
  my ( @lines ) = @_;
  my ( %sections, $current );
  my $flush = sub {
    $sections{ $current->{name} } = { source => $current->{source}, text => normalize_section( join "\n", @{ $current->{lines} } ) }
      if $current;
  };
  for my $line (@lines) {
    if ( js_trim($line) =~ $RULE_RE ) {
      $flush->();
      $current = { name => $1, source => $2, lines => [] };
    }
    elsif ($current) {
      push @{ $current->{lines} }, $line;
    }
  }
  $flush->();
  return \%sections;
}

#### the rules file ##########################################################

sub rules_file_text {
  my ( $scope, $sections ) = @_;
  return undef unless @$sections;
  my @out = ( RULES_MARKER.' scope='.$scope.' -->', RULES_NOTE, '' );
  for my $s (@$sections) {
    ( my $text = $s->{text} ) =~ s/\n\z//;
    push @out, '<!-- skilletor:rule '.$s->{name}.' source='.$s->{source}.' -->', _lines($text), '';
  }
  ( my $joined = join "\n", @out ) =~ s/\n+\z//;
  return $joined."\n";
}

sub parse_rules_file {
  my ( $text ) = @_;
  return _parse_sections( _lines($text) );
}

#### the pointer block in AGENTS.md ##########################################

sub pointer_lines {
  my ( $scope, $file ) = @_;
  return (
    NOTE,
    'Additional rules for '.( $scope eq 'user' ? 'all projects' : 'this project' ).' are managed by skilletor. They are normally provided at',
    'session start as a developer message beginning with `'.RULES_MARKER.'`. If that message',
    'is not in your context (for example after context compaction), read',
    '`'.$file.'` before you start a task, and follow it.',
  );
}

sub parse_block {
  my ( $text ) = @_;
  my @lines = _lines($text);
  my ( @begins, @ends );
  for my $i ( 0 .. $#lines ) {
    my $t = js_trim( $lines[$i] );
    if    ( $t eq BEGIN_MARKER ) { push @begins, $i }
    elsif ( $t eq END_MARKER )   { push @ends,   $i }
  }
  return undef unless @begins || @ends;
  my ( $b, $e ) = ( '"'.BEGIN_MARKER.'"', '"'.END_MARKER.'"' );
  Skilletor::Error::Block->throw( $b.' appears '.@begins.' times' ) if @begins > 1;
  Skilletor::Error::Block->throw( $e.' appears '.@ends.' times' )   if @ends > 1;
  Skilletor::Error::Block->throw( $e.' without '.$b ) unless @begins;
  Skilletor::Error::Block->throw( $b.' without '.$e ) unless @ends;
  my ( $begin, $end ) = ( $begins[0], $ends[0] );
  Skilletor::Error::Block->throw( $e.' before '.$b ) if $end < $begin;
  return { begin => $begin, end => $end, sections => _parse_sections( @lines[ $begin + 1 .. $end - 1 ] ) };
}

sub with_block {
  my ( $text, $body ) = @_;
  my @block = $body ? ( BEGIN_MARKER, @$body, END_MARKER ) : ();
  return $body ? join( "\n", @block )."\n" : undef unless defined $text;
  my $parsed = parse_block($text);
  my @lines  = _lines($text);
  my $out;
  if ($parsed) {
    my @before = @lines[ 0 .. $parsed->{begin} - 1 ];
    my @after  = @lines[ $parsed->{end} + 1 .. $#lines ];
    $out = join "\n", @before, @block, @after;
    # A block that was the last content leaves no blank lines of ours behind.
    $out =~ s/$WS*\z/\n/ if !$body && !grep { js_trim($_) ne '' } @after;
  }
  else {
    return $text unless $body;
    ( my $base = $text ) =~ s/$WS*\z//;
    $out = ( length $base ? $base."\n\n" : '' ).join( "\n", @block )."\n";
  }
  return js_trim($out) eq '' ? undef : $out;
}

sub inspect_agents_md {
  my ( $path ) = @_;
  my $bytes = encode_text($path);
  unless ( lstat $bytes ) {
    return { ok => 1, text => undef, parsed => undef } if $!{ENOENT};
    return { ok => 0, reason => 'unreadable ('.node_fs_error( 0 + $!, 'lstat', $path ).')' };
  }
  return { ok => 0, reason => 'is a symlink (skilletor does not write through it)' } if -l _;
  return { ok => 0, reason => 'is a directory' } if -d _;
  return { ok => 0, reason => 'is not a regular file' } unless -f _;
  my $raw;
  my $fh;
  unless ( open( $fh, '<:raw', $bytes ) && defined( $raw = do { local $/; <$fh> } ) ) {
    return { ok => 0, reason => 'unreadable ('.node_fs_error( 0 + $!, 'open', $path ).')' };
  }
  close $fh;
  my $text = decode_utf8_lossy($raw);
  my $parsed;
  return { ok => 1, text => $text, parsed => $parsed } if eval { $parsed = parse_block($text); 1 };
  my $err = $@;
  die $err unless ref $err && $err->isa('Skilletor::Error::Block');
  return { ok => 0, reason => 'malformed skilletor markers: '.$err->message };
}

#### Codex config.toml (read-only, line based) ###############################

sub _read_config_toml {
  my ( $codex_home ) = @_;
  open( my $fh, '<:raw', encode_text("$codex_home/config.toml") ) or return undef;
  my $raw = do { local $/; <$fh> };
  close $fh;
  return defined $raw ? decode_utf8_lossy($raw) : undef;
}

sub project_doc_limit {
  my ( $codex_home ) = @_;
  my $text = _read_config_toml($codex_home) // return 32768;
  for my $line ( _lines($text) ) {
    last if $line =~ /\A$WS*\[/;    # a table header: no longer top level
    return 0 + $1 if $line =~ /\A$WS*project_doc_max_bytes$WS*=$WS*([0-9]+)$WS*(?:#$DOT*)?\z/;
  }
  return 32768;
}

# A hooks.state key of skilletor's SessionStart handler, in any marketplace.
sub _is_session_start_key {
  my ( $key ) = @_;
  return index( $key, 'skilletor@' ) == 0 && index( $key, ':session_start:' ) >= 0;
}

my $QUOTED       = qr/"((?:[^"\\]|\\$DOT)*)"|'([^']*)'/;
my $TRUSTED_HASH = qr/\A$WS*trusted_hash$WS*=$WS*["']/;

sub codex_hook_trusted {
  my ( $codex_home ) = @_;
  my $text = _read_config_toml($codex_home) // return 0;
  my $table = 'other';
  for my $line ( _lines($text) ) {
    if ( $line =~ /\A$WS*\[$WS*([^\[\]]*?)$WS*\]$WS*(?:#$DOT*)?\z/ ) {
      my $name = $1;
      if    ( $name =~ /\Ahooks$WS*\.$WS*state$WS*\.$WS*(?:$QUOTED)\z/ ) { $table = _is_session_start_key( $1 // $2 ) ? 'hook' : 'other' }
      elsif ( $name =~ /\Ahooks$WS*\.$WS*state\z/ )                       { $table = 'state' }
      else                                                                 { $table = 'other' }
      next;
    }
    return 1 if $table eq 'hook' && $line =~ $TRUSTED_HASH;
    if ( $table eq 'state' && $line =~ /\A$WS*(?:$QUOTED)/ ) {
      my ( $key, $rest ) = ( $1 // $2, substr( $line, $+[0] ) );
      return 1 if _is_session_start_key($key) && $rest =~ /\btrusted_hash$WS*=$WS*["']/a;
    }
  }
  return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::AgentsMD - The Codex rules file, the pointer block in a Codex AGENTS.md, and the checks of Codex's config.toml

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::AgentsMD qw( rules_file_text parse_rules_file pointer_lines with_block inspect_agents_md );

  my $text = rules_file_text( project => [ { name => 'k8s', source => 'shared', text => "Use helm.\n" } ] );
  my $sections = parse_rules_file($text);    # { k8s => { source => 'shared', text => "Use helm.\n" } }

  my $agents = inspect_agents_md("$repo/AGENTS.md");
  if ( $agents->{ok} ) {
    my $next = with_block( $agents->{text}, [ pointer_lines( project => '.codex/skilletor-rules.md' ) ] );
  }

=head1 DESCRIPTION

The reference's C<agentsmd.ts> (spec §14.8): Codex rules on disk.

The rules file (C<skilletor-rules.md>, in C<$CODEX_HOME> for the user scope and
C<< <repo>/.codex >> for a project) is wholly skilletor's: a header line, the
managed note, then one section per rule under its marker comment. The
SessionStart hook under Codex injects it. C<AGENTS.md> carries only a pointer
to it, one managed block between C<< <!-- skilletor:begin --> >> and
C<< <!-- skilletor:end --> >>; text outside the markers is never modified.
Malformed markers, and files skilletor must not write through (a symlink, a
directory, an unreadable file), are refused, never repaired.

Codex's C<config.toml> is read line by line, never parsed as TOML, as the
reference reads it.

Texts are characters; files are read as UTF-8, an ill-formed byte as U+FFFD,
as Node reads them.

=head2 normalize_section

Leading blank lines and trailing whitespace (JavaScript's C<\s>) dropped, one
final newline added.

=head2 rules_file_text

  my $text = rules_file_text( $scope, [ { name, source, text }, ... ] );

The rules file of a scope, the sections in the order given; undef without one.

=head2 parse_rules_file

  my $sections = parse_rules_file($text);   # { name => { source, text } }

The sections of a rules file, whatever its header says.

=head2 pointer_lines

  my @lines = pointer_lines( $scope, $file );

The lines inside the pointer block; C<$file> is shown as given.

=head2 parse_block

  my $block = parse_block($text);   # { begin, end, sections } or undef

The managed block of an C<AGENTS.md>: the line numbers of its markers and the
rule sections inside it (only the first design wrote any; they are read for
the migration). Undef without one; L<Skilletor::Error::Block> when the markers
are malformed.

=head2 with_block

  my $next = with_block( $text, \@body );   # the block holding @body
  my $next = with_block( $text, undef );    # the block removed

The file's content with the block, or without one; undef when the file should
not exist (no block and nothing but whitespace). C<$text> undef: no file.

=head2 inspect_agents_md

  my $i = inspect_agents_md($path);
  # { ok => 1, text => $text_or_undef, parsed => $block_or_undef } or { ok => 0, reason => $why }

May skilletor keep a block in this file? Never dies.

=head2 project_doc_limit

  my $bytes = project_doc_limit($codex_home);   # 32768 unless config.toml says otherwise

Codex's C<project_doc_max_bytes>, a top-level key of
C<< $codex_home/config.toml >>.

=head2 codex_hook_trusted

  codex_hook_trusted($codex_home);   # 1 or 0

Has the user trusted skilletor's Codex SessionStart hook? True when
C<< $codex_home/config.toml >> has a C<trusted_hash> for a C<hooks.state> key
starting with C<skilletor@> and containing C<:session_start:> – as a
C<[hooks.state."E<lt>keyE<gt>"]> table, or as a key under C<[hooks.state]>.
Whether the hash is current is not checked. Never dies.

=head2 BEGIN_MARKER

=head2 END_MARKER

=head2 NOTE

=head2 RULES_FILE

C<skilletor-rules.md>, the rules file's name, and the lock key of every rule
section.

=head2 RULES_MARKER

How the rules file, and so the hook's message, begins.

=head2 MARKER_LINE

A pattern for a skilletor marker line (C<< <!-- skilletor:begin >>, C<end>,
C<rule>, C<rules>), matched against a trimmed line.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests at
L<https://github.com/Getty/skilletor/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
