#!/usr/bin/env perl
# Unicode boundaries where the Perl port must retain JavaScript's character and UTF-16 behavior.
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use SkilletorTest qw( write_json );

use Path::Tiny qw( path tempdir );
use Skilletor;
use Skilletor::Convert qw( codex_agent_toml );
use Skilletor::FSUtil qw( encode_text );
use Skilletor::Frontmatter qw( parse_yaml_document );

sub write_files {
  my ( $root, %files ) = @_;
  for my $rel ( keys %files ) {
    my $file = path( $root, $rel );
    $file->parent->mkpath;
    $file->spew_raw( encode_text( $files{$rel} ) );
  }
  return "$root";
}

subtest 'k163: Ambiguous messages are characters and encode as UTF-8 through the public API' => sub {
  my $root = tempdir->realpath;
  my ( $home, $project ) = ( "$root/home", "$root/project" );
  my $user_source = write_files( "$root/user-source", 'rules/style.md' => "user rule\n" );
  my $project_source = write_files( "$root/project-source", 'rules/style.md' => "project rule\n" );
  write_json( "$home/.claude/skilletor.json", {
    sources => { user => { local => $user_source } }, install => { rules => ['style@user'] },
  } );
  write_json( "$project/.claude/skilletor.local.json", {
    sources => { project => { local => $project_source } }, install => { rules => ['style@project'] },
  } );

  my $sk = Skilletor->new( home => $home, project_dir => $project );
  my $error;
  eval { $sk->resolve_rule('style'); 1 } or $error = $@;
  isa_ok( $error, 'Skilletor::Error::Ambiguous', 'both scopes raise the public API error' );
  my $message = $error->message;
  my $before = 'rule style is declared in the user and the project scope; Claude Code loads both (neither overrides the other) ';
  my $after = ' ask resolve_rules, or pass a scope';
  is( $message, $before."\N{EN DASH}".$after, 'the error carries one en-dash character' );
  is( encode_text($message), $before."\xE2\x80\x93".$after, 'the error encodes the en dash as UTF-8' );
};

subtest 'k195: double-quoted UTF-16 escapes match JavaScript before text encoding' => sub {
  my $slash = chr 0x5C;
  my $lower_high = $slash.'uD83D';
  my $lower_low  = $slash.'uDE00';
  my $upper_high = $slash.'U0000D83D';
  my $upper_low  = $slash.'U0000DE00';
  my $yaml = join "\n",
    'pair: "'.$lower_high.$lower_low.'"',
    'high: "'.$lower_high.'"',
    'low: "'.$lower_low.'"',
    'reversed: "'.$lower_low.$lower_high.'"',
    'mixed: "'.$lower_high.$lower_high.$lower_low.'"',
    'separated: "'.$lower_high.' x '.$lower_low.'"',
    'upper: "'.$upper_high.$upper_low.'"',
    'lower_upper: "'.$lower_high.$upper_low.'"',
    'upper_lower: "'.$upper_high.$lower_low.'"';
  is( unpack( 'H*', substr( $yaml, 0, length 'pair: "'.$lower_high.$lower_low.'"' ) ),
    '706169723a20225c75443833445c754445303022', 'pair input contains two literal \\u escapes' );
  my $data = parse_yaml_document($yaml);

  is( $data->{pair}, "\N{GRINNING FACE}", 'a high and low \\u pair becomes one character' );
  is( encode_text( $data->{pair} ), "\xF0\x9F\x98\x80", 'the pair writes as the character UTF-8 bytes' );
  is( encode_text( $data->{high} ), "\xEF\xBF\xBD", 'a lone high half still writes as replacement' );
  is( encode_text( $data->{low} ), "\xEF\xBF\xBD", 'a lone low half still writes as replacement' );
  is( encode_text( $data->{reversed} ), "\xEF\xBF\xBD\xEF\xBF\xBD", 'reversed halves remain lone halves' );
  is( encode_text( $data->{mixed} ), "\xEF\xBF\xBD\xF0\x9F\x98\x80", 'only the adjacent high and low pair joins' );
  is( encode_text( $data->{separated} ), "\xEF\xBF\xBD x \xEF\xBF\xBD", 'text between halves prevents joining' );
  is( encode_text( $data->{upper} ), "\xF0\x9F\x98\x80", 'an adjacent \\U high and low pair also joins' );
  is( encode_text( $data->{lower_upper} ), "\xF0\x9F\x98\x80", 'an adjacent lower-high and upper-low pair joins' );
  is( encode_text( $data->{upper_lower} ), "\xF0\x9F\x98\x80", 'an adjacent upper-high and lower-low pair joins' );

  my $toml = codex_agent_toml( qq{---\ndescription: "\\uD83D\\uDE00"\n---\nB\n}, 'x' )->{toml};
  is( encode_text($toml), encode_text( qq{name = "x"\ndescription = "\N{GRINNING FACE}"\ndeveloper_instructions = '''\nB\n'''\n} ),
    'Codex conversion retains the joined character' );
};

done_testing;
