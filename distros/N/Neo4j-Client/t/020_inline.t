use Test2::V0;

BEGIN {
  skip_all 'Inline::C not installed or too old'
    unless eval { require Inline::C; Inline->VERSION('0.56') };

  require Path::Tiny;
  our $inline_dir = Path::Tiny->tempdir('neo4j-client-inline-XXXXXX');
  $ENV{PERL_INLINE_DIRECTORY} = $inline_dir->absolute->stringify;
}

use Inline with => 'Neo4j::Client';

use Inline C => Config => typemaps =>
  $::inline_dir->child('typemap')->spew_raw('uint_fast8_t T_UV')->stringify;

use Inline C => 'DATA', autowrap => 1;

is log_level_4_as_string(), 'TRACE', 'indirect call';
is neo4j_log_level_str(2), 'INFO', 'direct call';

done_testing;

__DATA__
__C__

const char *log_level_4_as_string() {
  return neo4j_log_level_str(4);
}

const char *neo4j_log_level_str(uint_fast8_t level);
