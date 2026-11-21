package Skilletor::Convert;
# ABSTRACT: A Claude agent as a Codex agent role, a rule as its section of the Codex rules file

use strict;
use warnings;

use Exporter qw( import );
use Scalar::Util qw( blessed reftype );
use Skilletor::AgentsMD qw( RULES_FILE MARKER_LINE normalize_section );
use Skilletor::Error::Convert;
use Skilletor::FSUtil qw( decode_utf8_lossy encode_text );
use Skilletor::Frontmatter qw( split_frontmatter is_yaml_float );
use Skilletor::JSON qw( js_number js_ordered js_stringify js_type );
use Skilletor::JSString qw( js_trim );
use Skilletor::TOML qw( stringify_toml toml_float );

our $VERSION = '0.008000';

our @EXPORT_OK = qw( codex_agent_toml codex_rule_section convert_for_target );

sub _fail { Skilletor::Error::Convert->throw( $_[0] ) }

# split_frontmatter; unreadable frontmatter is a conversion error with the reader's message.
sub _split {
  my ( $markdown ) = @_;
  my $fm;
  return $fm if eval { $fm = split_frontmatter($markdown); 1 };
  my $err = $@;
  _fail( $err->message ) if blessed $err && $err->isa('Skilletor::Error::Frontmatter');
  die $err;
}

sub _is_mapping {
  my ( $v ) = @_;
  return ref $v && ( reftype $v // '' ) eq 'HASH' && !is_yaml_float($v) ? 1 : 0;
}

# A YAML value as a TOML scalar or string array: ( $value ), or ( undef, $reason ) when it
# cannot be one.
sub _toml_leaf {
  my ( $v ) = @_;
  return ( toml_float( $v->value ) ) if is_yaml_float($v);
  my $type = js_type($v);
  return ($v) if $type eq 'string' || $type eq 'boolean' || $type eq 'number';
  return ( undef, 'null has no TOML form' ) if $type eq 'null';
  if ( $type eq 'array' ) {
    return ( undef, 'only arrays of strings are supported' ) if grep { js_type($_) ne 'string' } @$v;
    return ($v);
  }
  return ( undef, 'nested tables are not supported' );
}

# String(v) of a scalar, undef for null, a list, a mapping or a float (all objects there).
sub _as_text {
  my ( $v ) = @_;
  my $type = js_type($v);
  return $v ? 'true' : 'false' if $type eq 'boolean';
  return js_number($v) if $type eq 'number';
  return $type eq 'string' ? $v : undef;
}

# String(v) of a YAML value that is no list.
sub _js_string {
  my ( $v ) = @_;
  return '[object Object]' if is_yaml_float($v) || _is_mapping($v);
  return defined $v ? _as_text($v) : 'null';
}

# JSON.stringify(v) of a YAML scalar; a float is the object it is in the reference.
sub _json {
  my ( $v ) = @_;
  return js_stringify( is_yaml_float($v) ? js_ordered( value => $v->value ) : $v );
}

# A briefing skill name the comment line cannot carry: `"`, `\`, `]`, or any control character
# (line breaks included; TOML allows none but tab in a comment).
my $BAD_SKILL_CHAR = qr/["\\\]\x00-\x1F\x7F]/;

# briefing.skills as the comment line the briefing plugin reads for Codex (spec §14.7): Codex
# drops a role with any unknown key, so a [briefing] table is not an option. Undef when there
# is nothing to declare.
sub _briefing_comment {
  my ( $briefing ) = @_;
  return undef unless _is_mapping($briefing) && exists $briefing->{skills};
  my $skills = $briefing->{skills};
  _fail('briefing.skills must be a list of skill names') unless js_type($skills) eq 'array';
  return undef unless @$skills;
  my $i = 0;
  for my $s (@$skills) {
    $i++;
    next if js_type($s) eq 'string' && $s ne '' && $s !~ $BAD_SKILL_CHAR;
    _fail( 'briefing.skills item '.$i.' ('._json($s).') must be a non-empty string '
        .'without a double quote, backslash, ] or line break' );
  }
  return '# briefing: skills = ['.join( ', ', map { '"'.$_.'"' } @$skills )."]\n";
}

sub codex_agent_toml {
  my ( $markdown, $item_name ) = @_;
  my $fm = _split($markdown);
  my ( $data, $body ) = @{$fm}{qw( data body )};
  my @warnings;

  my $name = _as_text( $data->{name} );
  my $top  = js_ordered(
    name        => defined $name && $name ne '' ? $name : $item_name,
    description => _as_text( $data->{description} ) // '',
  );
  my $tables = js_ordered();

  my $briefing = _briefing_comment( $data->{briefing} );

  my $instructions = $body;
  my $codex        = $data->{codex};
  if ( exists $data->{codex} && !_is_mapping($codex) ) {
    push @warnings, 'codex: must be a mapping; ignored';
  }
  elsif ( _is_mapping($codex) ) {
    for my $key ( keys %$codex ) {
      my $v = $codex->{$key};
      if ( $key eq 'briefing' ) {
        _fail( 'codex.briefing: would become a [briefing] table, and Codex ignores a role with one; '
            .'declare skills in the top-level briefing.skills' );
      }
      if ( _is_mapping($v) && ( exists $top->{$key} || $key eq 'developer_instructions' || exists $tables->{$key} ) ) {
        push @warnings, "codex.$key: a table cannot replace the $key key; dropped";
        next;
      }
      if ( _is_mapping($v) ) {
        my $t = js_ordered();
        for my $sk ( keys %$v ) {
          my ( $leaf, $reason ) = _toml_leaf( $v->{$sk} );
          if   ( defined $reason ) { push @warnings, "codex.$key.$sk: $reason; dropped" }
          else                     { $t->{$sk} = $leaf }
        }
        $tables->{$key} = $t;
        next;
      }
      my ( $leaf, $reason ) = _toml_leaf($v);
      if    ( defined $reason )                { push @warnings, "codex.$key: $reason; dropped" }
      elsif ( $key eq 'developer_instructions' ) { $instructions = $leaf }
      else                                     { $top->{$key} = $leaf }
    }
  }

  _fail('name must be a non-empty string') unless js_type( $top->{name} ) eq 'string' && js_trim( $top->{name} ) ne '';
  unless ( js_type( $top->{description} ) eq 'string' && js_trim( $top->{description} ) ne '' ) {
    _fail('has no description (Codex rejects an agent role without one)');
  }
  _fail('developer_instructions must be a string') unless js_type($instructions) eq 'string';
  return { warnings => \@warnings } if js_trim($instructions) eq '';

  # $top holds no tables, so its keys come out first; the briefing line sits between them and
  # developer_instructions, never inside the multi-line string.
  my $rest = js_ordered( developer_instructions => $instructions );
  $rest->{$_} = $tables->{$_} for keys %$tables;
  my $text = stringify_toml($top).( $briefing // '' ).stringify_toml( $rest, { multiline => ['developer_instructions'] } );
  return { toml => $text, warnings => \@warnings };
}

sub codex_rule_section {
  my ( $markdown, $item_name ) = @_;
  my $fm = _split($markdown);
  return undef if js_trim( $fm->{body} ) eq '';
  if ( grep { js_trim($_) =~ MARKER_LINE } split /\n/, $fm->{body}, -1 ) {
    _fail( 'rule '.$item_name.' contains a skilletor marker line; it would break the rules file' );
  }
  my $raw   = $fm->{data}{paths};
  my @paths = map { _js_string($_) } js_type($raw) eq 'array' ? @$raw : defined $raw ? ($raw) : ();
  my $lead  = @paths ? 'Applies when working with files matching: '.join( ', ', map { "`$_`" } @paths ).".\n\n" : '';
  return normalize_section( $lead.$fm->{body} );
}

sub _file {
  my ( $output, $path ) = @_;
  for my $f (@$output) {
    return $f->[1] if $f->[0] eq $path;
  }
  return undef;
}

sub convert_for_target {
  my ( $harness, $type, $name, $output ) = @_;
  if ( $harness eq 'codex' && $type eq 'rule' ) {
    my $md = _file( $output, "rules/$name.md" );
    _fail("rules/$name.md missing from the build") unless defined $md;
    my $section = codex_rule_section( decode_utf8_lossy($md), $name );
    return {
      output   => [ defined $section ? [ RULES_FILE, encode_text($section) ] : () ],
      skipped  => defined $section ? 0 : 1,
      warnings => [],
    };
  }
  return { output => $output, skipped => 0, warnings => [] } unless $harness eq 'codex' && $type eq 'agent';
  my $md = _file( $output, "agents/$name.md" );
  _fail("agents/$name.md missing from the build") unless defined $md;
  my $conv = codex_agent_toml( decode_utf8_lossy($md), $name );
  my $toml = $conv->{toml};
  return {
    output   => [ defined $toml ? [ "agents/$name.toml", encode_text($toml) ] : () ],
    skipped  => defined $toml ? 0 : 1,
    warnings => $conv->{warnings},
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Skilletor::Convert - A Claude agent as a Codex agent role, a rule as its section of the Codex rules file

=head1 VERSION

version 0.008000

=head1 SYNOPSIS

  use Skilletor::Convert qw( codex_agent_toml codex_rule_section convert_for_target );

  my $conv = codex_agent_toml( $agent_markdown, 'reviewer' );
  # { toml => "name = \"reviewer\"\n...", warnings => [ 'codex.x: null has no TOML form; dropped' ] }

  my $section = codex_rule_section( $rule_markdown, 'style' );   # undef for a blank body

  my $r = convert_for_target( 'codex', 'agent', 'reviewer', $output );
  # { output => [ [ 'agents/reviewer.toml', $bytes ] ], skipped => 0, warnings => [...] }

=head1 DESCRIPTION

The reference's C<convert.ts> (spec §14.7, §14.8): the per-target output
conversion between render and apply. It knows neither sources nor the target
filesystem; its texts are the reference's, byte for byte.

A Claude agent becomes a Codex agent role: C<name> (else the item's name),
C<description> and the body as C<developer_instructions>, a multi-line string.
A C<codex:> mapping in the frontmatter passes its scalars, string lists and one
level of tables through and overrides the derived keys; a value outside those
shapes is dropped with one warning. C<briefing.skills> becomes the comment line
C<# briefing: skills = [...]> the briefing plugin reads, right before
C<developer_instructions>. Claude-only keys (C<tools>, C<model>, …) are not
carried.

A rule becomes its section of the Codex rules file: the body without
frontmatter, led by an "Applies when working with files matching: …" line for
a C<paths:> frontmatter, since Codex cannot load a rule conditionally.

Errors are L<Skilletor::Error::Convert> with the reference's message;
unreadable frontmatter is one too, with the reader's message. A float TOML
cannot write (C<1e999>) is a L<Skilletor::Error::TOML>, as in the reference.

=head2 codex_agent_toml

  my $conv = codex_agent_toml( $markdown, $item_name );

C<< { toml => $text, warnings => [ ... ] } >>; no C<toml> key when the body is
blank (the agent does not apply to Codex). Text in, text out.

=head2 codex_rule_section

  my $text = codex_rule_section( $markdown, $item_name );

The section text, normalized (see L<Skilletor::AgentsMD/normalize_section>);
undef when the body is blank. A body with a skilletor marker line is an error.

=head2 convert_for_target

  my $r = convert_for_target( $harness, $type, $name, $output );

Maps an item's built output (L<Skilletor::Render/build>: C<[ [ path, bytes ],
... ]>) to what a harness installs: C<< { output, skipped, warnings } >>.
Claude, Hermes and Codex skills take it as it is (the same array). A Codex
agent becomes C<< agents/<name>.toml >>; a Codex rule becomes its section under
the key C<skilletor-rules.md>, which the engine assembles into the rules file.
C<skipped> is true where the item does not apply to the target, as for an
empty render. Files are read and written as UTF-8, an ill-formed byte read as
U+FFFD as Node reads it.

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
