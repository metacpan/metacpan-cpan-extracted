#!/usr/bin/env perl
# The reference's agentsmd.ts: the Codex rules file, the pointer block in a Codex AGENTS.md,
# inspecting that file before a sync writes it, and the read-only checks of Codex's config.toml.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use Path::Tiny qw( path tempdir );
use Scalar::Util qw( blessed );
use Skilletor::JSON qw( js_parse js_stringify );
use Skilletor::AgentsMD qw(
  BEGIN_MARKER END_MARKER MARKER_LINE NOTE RULES_FILE RULES_MARKER codex_hook_trusted inspect_agents_md normalize_section
  parse_block parse_rules_file pointer_lines project_doc_limit rules_file_text with_block
);

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw( output failure_output todo_output );

# t/data/agentsmd-oracle.json is the reference's answer (maint/oracle-agentsmd.mjs).
my $oracle = js_parse( path( $FindBin::Bin, 'data', 'agentsmd-oracle.json' )->slurp_utf8 );

my %CLASS = ( BlockError => 'Skilletor::Error::Block' );

# A sections hash as the oracle's Map entries ([ name, source, text ], ordered by name: a hash
# keeps no order, and only lookups use it).
sub entries {
  my ( $sections ) = @_;
  return [ map { [ $_, $sections->{$_}{source}, $sections->{$_}{text} ] } sort keys %$sections ];
}
sub sorted { [ sort { $a->[0] cmp $b->[0] } @{ $_[0] } ] }

sub parsed {
  my ( $p ) = @_;
  return $p && { begin => $p->{begin}, end => $p->{end}, sections => entries( $p->{sections} ) };
}
sub want_parsed {
  my ( $p ) = @_;
  return $p && { begin => $p->{begin}, end => $p->{end}, sections => sorted( $p->{sections} ) };
}

# The result of $code, or the error the oracle expects instead.
sub check {
  my ( $name, $case, $code, $compare ) = @_;
  my $got;
  my $ok  = eval { $got = $code->(); 1 };
  my $err = $@;
  if ( my $want = $case->{error} ) {
    my $class = $CLASS{ $want->{name} } // 'an unexpected '.$want->{name};
    ok( !$ok && blessed $err && $err->isa($class), "$name: a $class" );
    is( $ok ? undef : blessed $err ? $err->message : "$err", $want->{message}, "$name: message" );
    return;
  }
  return fail("$name: died: $err") unless $ok;
  $compare->($got);
}

# A fresh directory holding the oracle's file (or kind of entry) under $name.
my $tmp = tempdir;
my $n   = 0;
sub place {
  my ( $f, $name ) = @_;
  my $dir = path( $tmp, $n++ );
  $dir->mkpath;
  my $p = $dir->child($name);
  if    ( defined $f->{hex} )        { $p->spew_raw( pack 'H*', $f->{hex} ) }
  elsif ( $f->{kind} eq 'dir' )      { $p->mkpath }
  elsif ( $f->{kind} eq 'symlink' )  { $dir->child('target.md')->spew_raw("x\n"); symlink 'target.md', "$p" or die $! }
  elsif ( $f->{kind} eq 'dangling' ) { symlink 'nowhere.md', "$p" or die $! }
  return ( "$dir", "$p" );
}

subtest 'normalizeSection' => sub {
  is( normalize_section( $_->{text} ), $_->{out}, js_stringify( $_->{text} ) ) for @{ $oracle->{normalize} };
};

subtest 'MARKER_LINE' => sub {
  is( ( $_->{line} =~ MARKER_LINE ) ? 1 : 0, $_->{out} ? 1 : 0, js_stringify( $_->{line} ) ) for @{ $oracle->{markers} };
};

subtest 'rulesFileText' => sub {
  for my $case ( @{ $oracle->{rulesFile} } ) {
    is( rules_file_text( $case->{scope}, $case->{sections} ), $case->{out}, $case->{scope}.' '.js_stringify( $case->{sections} ) );
  }
};

subtest 'parseRulesFile' => sub {
  is_deeply( entries( parse_rules_file( $_->{text} ) ), sorted( $_->{out} ), js_stringify( $_->{text} ) ) for @{ $oracle->{parseRules} };
};

subtest 'pointerLines' => sub {
  is_deeply( [ pointer_lines( $_->{scope}, $_->{file} ) ], $_->{out}, $_->{scope} ) for @{ $oracle->{pointer} };
};

subtest 'parseBlock' => sub {
  for my $case ( @{ $oracle->{parseBlock} } ) {
    my $name = js_stringify( $case->{text} );
    check( $name, $case, sub { parsed( parse_block( $case->{text} ) ) }, sub { is_deeply( $_[0], want_parsed( $case->{out} ), $name ) } );
  }
};

subtest 'withBlock' => sub {
  for my $case ( @{ $oracle->{withBlock} } ) {
    my $name = js_stringify( $case->{text} ).' with '.js_stringify( $case->{body} );
    check( $name, $case, sub { with_block( $case->{text}, $case->{body} ) }, sub { is( $_[0], $case->{out}, $name ) } );
  }
};

subtest 'inspectAgentsMd' => sub {
  for my $case ( @{ $oracle->{inspect} } ) {
    my $name = js_stringify( $case->{file} );
    my ( undef, $p ) = place( $case->{file}, 'AGENTS.md' );
    my $r    = inspect_agents_md($p);
    my $want = $case->{out};
    if ( $want->{ok} ) {
      is_deeply( { ok => $r->{ok} ? 1 : 0, text => $r->{text}, parsed => parsed( $r->{parsed} ) },
        { ok => 1, text => $want->{text}, parsed => want_parsed( $want->{parsed} ) }, $name );
    }
    else {
      is_deeply( $r, { ok => 0, reason => $want->{reason} }, $name );
    }
  }
  SKIP: {
    skip 'root reads any file', 1 if $> == 0;
    my ( undef, $p ) = place( { hex => '780a' }, 'AGENTS.md' );
    chmod 0, $p;
    is_deeply( inspect_agents_md($p), { ok => 0, reason => "unreadable (EACCES: permission denied, open '$p')" }, 'unreadable: Node\'s message' );
    chmod 0644, $p;
  }
};

subtest 'projectDocLimit and codexHookTrusted' => sub {
  for my $case ( @{ $oracle->{config} } ) {
    my $name = js_stringify( $case->{file} );
    my ($dir) = place( $case->{file}, 'config.toml' );
    is( project_doc_limit($dir), $case->{limit}, "$name: the limit" );
    is( codex_hook_trusted($dir) ? 1 : 0, $case->{trusted} ? 1 : 0, "$name: trusted" );
  }
  ok( !codex_hook_trusted("$tmp/none"), 'no Codex home: not trusted' );
  is( project_doc_limit("$tmp/none"), 32768, 'and the default limit' );
};

subtest 'the constants' => sub {
  is( BEGIN_MARKER, '<!-- skilletor:begin -->', 'BEGIN' );
  is( END_MARKER,   '<!-- skilletor:end -->',   'END' );
  is( NOTE,         '<!-- managed by skilletor — edits inside are overwritten -->', 'NOTE' );
  is( RULES_FILE,   'skilletor-rules.md',  'RULES_FILE' );
  is( RULES_MARKER, '<!-- skilletor:rules', 'RULES_MARKER' );
};

done_testing;
