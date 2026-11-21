#!/usr/bin/env perl
# Environment path defaults are UTF-8 bytes at the process boundary (k198). Builders decode
# those defaults once; unset/empty semantics and values supplied by callers stay unchanged.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use SkilletorTest::Conformance qw( with_case_env );
use Skilletor::Engine;
use Skilletor::FSUtil qw( encode_text );
use Skilletor::Process qw( run_command );

my @paths = (
  [ CLAUDE_CONFIG_DIR => 'claude_config_dir', '/tmp/conf-ü' ],
  [ CODEX_HOME        => 'codex_home',        '/tmp/codex-ü' ],
  [ CLAUDE_PLUGIN_ROOT => 'plugin_root',      '/tmp/plugin-ü' ],
);

sub engine { Skilletor::Engine->new( home => '/tmp/home', @_ ) }

subtest 'environment defaults decode UTF-8 bytes' => sub {
  local $ENV{LC_ALL} = 'C';
  for my $case (@paths) {
    my ( $env, $attr, $text ) = @$case;
    local $ENV{$env} = encode_text($text);
    is( engine()->$attr, $text, "$env is decoded at the builder boundary" );
  }
};

subtest 'unset and empty environment values keep their meanings' => sub {
  for my $case (@paths) {
    my ( $env, $attr ) = @$case;
    {
      local $ENV{$env};
      delete $ENV{$env};
      is( engine()->$attr, undef, "$env unset stays undef" );
    }
    {
      local $ENV{$env} = '';
      is( engine()->$attr, '', "$env empty stays empty" );
    }
  }
};

subtest 'the shared case helper crosses the environment byte boundary once' => sub {
  my $value = '/tmp/helper-ü';
  my $want_hex = unpack 'H*', encode_text($value);
  my $r = {
    env => {
      LC_ALL              => 'C',
      CLAUDE_CONFIG_DIR    => $value,
      CODEX_HOME           => '',
      CLAUDE_PLUGIN_ROOT   => undef,
    },
  };

  with_case_env(
    $r,
    sub {
      is( unpack( 'H*', $ENV{CLAUDE_CONFIG_DIR} ), $want_hex, 'helper puts UTF-8 bytes in %ENV' );
      is( engine()->claude_config_dir, $value, 'the builder decodes the helper environment' );
      is( $ENV{CODEX_HOME}, '', 'the helper preserves an empty value' );
      is( $ENV{CLAUDE_PLUGIN_ROOT}, undef, 'the helper preserves an undefined value' );

      my $child = run_command(
        cmd => [ $^X, '-e', 'binmode STDOUT; print unpack "H*", $ENV{CLAUDE_CONFIG_DIR} // ""' ],
      );
      is( $child->{code}, 0, 'the child exits cleanly' );
      is( $child->{stdout}, $want_hex, 'the child receives the same UTF-8 environment bytes' );
    }
  );

  is( $r->{env}{CLAUDE_CONFIG_DIR}, $value, 'the helper keeps its input as characters' );
  ok( utf8::is_utf8( $r->{env}{CLAUDE_CONFIG_DIR} ), 'the helper input remains a character string' );
};

subtest 'explicit constructor values are not decoded again' => sub {
  my $value = '/tmp/explicit-ü';
  my $engine = engine(
    claude_config_dir => $value,
    codex_home        => $value,
    plugin_root       => $value,
  );
  for my $attr (qw( claude_config_dir codex_home plugin_root )) {
    is( $engine->$attr, $value, "$attr keeps its explicit value" );
    ok( utf8::is_utf8( $engine->$attr ), "$attr remains a character string" );
  }
};

done_testing;
