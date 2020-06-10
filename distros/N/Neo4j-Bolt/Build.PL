use lib '.';
use File::Spec;
use Builder;
use ExtUtils::CChecker;
use Neo4j::Client;
use Try::Tiny;

my $DEFAULT_URL = "bolt://localhost:7687";

my $build = Builder->new(
  dist_name => "Neo4j-Bolt",
  dist_version_from => "lib/Neo4j/Bolt.pm",
  dist_abstract => "Neo4j server agent using Bolt protocol",
  dist_author => 'Mark A. Jensen',
  configure_requires => {
    'Module::Build' => '0.36_14',
    'Neo4j::Client' => '>=0.17',
    'ExtUtils::CChecker' => 0,
    'Try::Tiny' => 0,
  },
  requires => {
    'Inline::C' => 0,
    'JSON::PP' => 0,
    'URI' => 0,
    'Neo4j::Client' => '0.17',
  },
  build_requires => {
    'Inline' => 0,
    'Try::Tiny' => 0,
    'Test::More' => 0,
    'Test::Exception' => 0
  },
  recommends => {
    'Mozilla::CA' => 0,
    'Pod::Markdown' => 0,
  },
  license => 'Apache_2_0',
  no_index => {
    package => [
      'Builder',
      't::BoltFile',
    ],
  },
  meta_merge => {
    resources => {
      bugtracker => 'https://github.com/majensen/perlbolt/issues',
      repository => 'https://github.com/majensen/perlbolt.git',
    },
    x_contributors => [
      'Mark A. Jensen <majensen@cpan.org>',
      'Arne Johannessen <ajnn@cpan.org>'
      ],
  },
  # inline_modules is a property added in the subclass 'Builder.pm'
  inline_modules => [
#    'Neo4j::Bolt::TypeHandlersC',
    'Neo4j::Bolt::NeoValue',
#    'Neo4j::Bolt::Cxn',
#    'Neo4j::Bolt::ResultStream',
    'Neo4j::Bolt',
  ],
 );
$build->add_build_element("h");
$build->add_to_cleanup("_Inline");
$build->add_to_cleanup("lib/Neo4j/Bolt/Config.pm");

# look for libneo4j-client
my $cc = ExtUtils::CChecker->new( quiet => 1);
$cc->push_extra_linker_flags( Neo4j::Client::LIBS_ARY() );
$cc->push_extra_compiler_flags( Neo4j::Client::CCFLAGS_ARY() );

my $code_cc = <<'CC';
#include <stdio.h>
#include <string.h>
#include <neo4j-client.h>
int main(int argc, char *argv[]) {
  const char *version = libneo4j_client_version();
  printf("libneo4j-client version %s is installed.\n", version);
  if (strcmp(version, "2.") < 0) {
    printf("ERROR: libneo4j-client version 1.x is not supported by Neo4j::Bolt.\n");
    return 1;
  }
  return neo4j_type(neo4j_null);
}
CC

unless (
  $cc->try_compile_run(source => $code_cc,
		      )
 ) {
  print "libneo4j-client cannot be found.\n";
  print "Install the module Neo4j::Client.\n";
  exit(0);
}

$build->notes(lf => $cc->extra_linker_flags);
$build->notes(cf => $cc->extra_compiler_flags);

$build->extra_linker_flags(@{$cc->extra_linker_flags});
$build->extra_compiler_flags(@{$cc->extra_compiler_flags});

if ($build->y_n("Would you like to perform read-only tests on a local database?","n")) {
  $build->notes( 'db_url' =>
		   $build->prompt("Enter local Neo4j address and bolt port: ",
				  $DEFAULT_URL));
  $build->notes( 'db_user' =>
		   $build->prompt("Enter Neo4j username for ".$build->notes('db_url')." (RET if none): ",undef) );
  if (length $build->notes('db_user')) {
    $build->notes( 'db_pass' =>
		     $build->prompt("Enter Neo4j password: ","") );
  }
  else {
    $build->notes('db_pass' => undef);
  }
  if ($build->notes('db_url')) {
    $build->notes('ok_add_delete', $build->y_n("Will you allow add/delete tests on your database (cruft added will be removed)?","y"));
  }
}


$build->create_build_script;
