#!/usr/bin/env perl
# The reference's convert.ts: a Claude agent as a Codex agent-role TOML file, a rule as its
# section of the Codex rules file, and the per-target mapping of an item's output.
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( error_of );

use Path::Tiny qw( path );
use Scalar::Util qw( blessed refaddr );
use Skilletor::JSON qw( js_parse js_stringify );
use Skilletor::Convert qw( codex_agent_toml codex_rule_section convert_for_target );

# t/data/convert-oracle.json is the reference's answer (maint/oracle-convert.mjs).
my $oracle = js_parse( path( $FindBin::Bin, 'data', 'convert-oracle.json' )->slurp_utf8 );

my %CLASS = ( ConvertError => 'Skilletor::Error::Convert', TomlWriteError => 'Skilletor::Error::TOML' );

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

subtest 'codexAgentToml' => sub {
  for my $case ( @{ $oracle->{agents} } ) {
    my $name = js_stringify( $case->{md} ).' as '.js_stringify( $case->{name} );
    check( $name, $case, sub { codex_agent_toml( $case->{md}, $case->{name} ) }, sub {
      my ( $r ) = @_;
      is( $r->{toml}, $case->{out}{toml}, "$name: toml" );
      is( exists $r->{toml} ? 1 : 0, exists $case->{out}{toml} ? 1 : 0, "$name: a toml key only with a text" );
      is_deeply( $r->{warnings}, $case->{out}{warnings}, "$name: warnings" );
    } );
  }
};

subtest 'codexRuleSection' => sub {
  for my $case ( @{ $oracle->{rules} } ) {
    my $name = js_stringify( $case->{md} );
    check( $name, $case, sub { codex_rule_section( $case->{md}, $case->{name} ) }, sub {
      is( $_[0], $case->{out}, $name );
    } );
  }
};

subtest 'convertForTarget' => sub {
  for my $case ( @{ $oracle->{targets} } ) {
    my $name = join ' ', $case->{harness}, $case->{type}, $case->{name}, js_stringify( $case->{files} );
    my $input = [ map { [ $_->[0], pack 'H*', $_->[1] ] } @{ $case->{files} } ];
    check( $name, $case, sub { convert_for_target( $case->{harness}, $case->{type}, $case->{name}, $input ) }, sub {
      my ( $r ) = @_;
      is_deeply( [ map { [ $_->[0], unpack 'H*', $_->[1] ] } @{ $r->{output} } ], $case->{out}{files}, "$name: files" );
      is( $r->{skipped} ? 1 : 0, $case->{out}{skipped} ? 1 : 0, "$name: the skipped flag" );
      is_deeply( $r->{warnings}, $case->{out}{warnings}, "$name: warnings" );
      is( refaddr( $r->{output} ) == refaddr($input) ? 1 : 0, $case->{out}{same} ? 1 : 0, "$name: the same output" );
    } );
  }
};

subtest 'bytes out, characters in' => sub {
  my $r = convert_for_target( 'codex', 'agent', 'x', [ [ 'agents/x.md', "---\ndescription: \xC3\xA9\n---\nB\n" ] ] );
  is( $r->{output}[0][1], qq(name = "x"\ndescription = "\xC3\xA9"\ndeveloper_instructions = '''\nB\n'''\n), 'UTF-8 bytes' );
  like( codex_agent_toml( "---\ndescription: \x{e9}\n---\nB\n", 'x' )->{toml}, qr/"\x{e9}"/, 'a text in, a text out' );
  like( error_of( sub { codex_agent_toml( "---\ndescription: d\n---\nB\n", undef ) } ), qr/\Aname must be a non-empty string\z/,
    'no item name and no name: the reference error' );
};

done_testing;
