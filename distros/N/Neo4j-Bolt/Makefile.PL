use v5.12;
use warnings;

use Alien::Base::Wrapper qw( Neo4j::Client !export );
use Config;
use ExtUtils::MakeMaker;
use Data::Dumper;
use Text::ParseWords qw/shellwords/;
use Try::Tiny;
use File::Spec;
use Cwd qw/realpath/;

die "OS unsupported\n64 bit integers required\n" unless $Config{use64bitint};

my $META = {
  resources => {
    bugtracker => {
      web => 'https://github.com/majensen/perlbolt/issues',
    },
    repository => {
      type => 'git',
      url => 'https://github.com/majensen/perlbolt.git',
      web => 'https://github.com/majensen/perlbolt',
    },
  },
  x_contributors => [
    'Mark A. Jensen <majensen@cpan.org>',
    'Arne Johannessen <ajnn@cpan.org>',
  ],
  prereqs => {
    runtime => {
      recommends => {
        'Mozilla::CA' => 0,
      },
    },
    develop => {
      requires => {
        'Devel::PPPort' => '3.63',
        'Inline::C' => '0.56',  # in t/Boltfile.pm, used via xt/003_stream.t
	#'IPC::Run' => 0,  # in t/lib/NeoCon.pm, but not actually used anywhere
      },
      recommends => {
        'Path::Tiny' => '0.054',  # pod2md.PL
        'Pod::Markdown' => '3.100',  # pod2md.PL
      },
    },
  },
  'meta-spec' => { version => 2 },
};

my $neo_info = prompt_for_db();
if ($neo_info) {
  try {
    if (-d 't') {
      open my $fh, ">", File::Spec->catfile('t','neo_info') or die "Can't open neo_info for writing.";
      say $fh Dumper($neo_info);
      close $fh;
    }
  } catch {
    print STDERR "$_; skipping live db tests\n";
  };
}

my @define;

# NEO4J_BOLT_TYPES_FAST enables special case code in CTypeHandlers that will
#  read the hash ref entries of Neo4j::Bolt::DateTime & friends directly when
#  used as query parameters. Without it, they will be read using the generic
#  Neo4j::Types methods instead. This works just as well, but is slower.
push @define, '-DNEO4J_BOLT_TYPES_FAST' unless $ENV{NO_NEO4J_BOLT_TYPES_FAST};

# NEO4J_CORE_BOOLS sets the boolean values returned from Neo4j to be Perl core
#  "distinguished" booleans on Perl v5.36 and newer. Without it, blessed
#  JSON::PP::Boolean instances will always be used, even on Perl v5.36+.
push @define, '-DNEO4J_CORE_BOOLS' unless $ENV{NO_NEO4J_CORE_BOOLS};

my %alien_flags = Alien::Base::Wrapper->mm_args;
$alien_flags{DEFINE} = join ' ', shellwords($alien_flags{DEFINE} // ''), @define;
$alien_flags{INC} = join ' ', shellwords($alien_flags{INC} // ''), '-iquote'.realpath('include');

WriteMakefile(
  NAME => 'Neo4j::Bolt',
  VERSION_FROM => 'lib/Neo4j/Bolt.pm',
  MIN_PERL_VERSION => '5.012',
  CONFIGURE_REQUIRES => {
    'Alien::Base::Wrapper' => '0.04',
    'ExtUtils::MakeMaker' => '7.12',
    'Neo4j::Client' => '0.56',
    'Try::Tiny' => 0,
  },
  BUILD_REQUIRES => {
    'ExtUtils::Typemaps' => '3.24',  # embedded typemap
  },
  PREREQ_PM => {
    'Neo4j::Client' => '0.56',
    'Neo4j::Types' => '2.00',
    'JSON::PP' => 0,
    'URI' => 0,
    'XSLoader' => '0.14',  # XSLoader::load()
  },
  TEST_REQUIRES => {
    'Test::Exception' => 0,
    'Test::Neo4j::Types' => '0.06',
    'Try::Tiny' => 0,
  },
  ABSTRACT => "Neo4j server agent using Bolt protocol",
  AUTHOR => ['Mark A. Jensen (majensen -at- cpan -dot- org)'],
  LICENSE => 'apache_2_0',
  %alien_flags,
  test => {TESTS => 't/*.t'},
  clean => {FILES => "include/ppport.h t/neo_info"},
  PL_FILES => { "pod2md.PL" => [qw(
				    lib/Neo4j/Bolt.pm
				    lib/Neo4j/Bolt/Bytes.pm
				    lib/Neo4j/Bolt/CResultStream.pm
				    lib/Neo4j/Bolt/Cxn.pm
				    lib/Neo4j/Bolt/DateTime.pm
				    lib/Neo4j/Bolt/Duration.pm
				    lib/Neo4j/Bolt/NeoValue.pm
				    lib/Neo4j/Bolt/Node.pm
				    lib/Neo4j/Bolt/Path.pm
				    lib/Neo4j/Bolt/Point.pm
				    lib/Neo4j/Bolt/Relationship.pm
				    lib/Neo4j/Bolt/ResultStream.pm
				    lib/Neo4j/Bolt/Txn.pm
				 )]},
  XSMULTI => 1,
  XSBUILD => {
    xs => {
      'lib/Neo4j/Bolt/Cxn' => {
	LDFROM => "lib/Neo4j/Bolt/Cxn\$(OBJ_EXT) lib/Neo4j/Bolt/CResultStream\$(OBJ_EXT) lib/Neo4j/Bolt/CTypeHandlers\$(OBJ_EXT)",
      },
      'lib/Neo4j/Bolt/Txn' => {
	LDFROM => "lib/Neo4j/Bolt/Txn\$(OBJ_EXT) lib/Neo4j/Bolt/CResultStream\$(OBJ_EXT) lib/Neo4j/Bolt/CTypeHandlers\$(OBJ_EXT)",
      },
      'lib/Neo4j/Bolt/ResultStream' => {
	LDFROM => "lib/Neo4j/Bolt/ResultStream\$(OBJ_EXT) lib/Neo4j/Bolt/CResultStream\$(OBJ_EXT) lib/Neo4j/Bolt/CTypeHandlers\$(OBJ_EXT)",
      },
      'lib/Neo4j/Bolt/NeoValue' => {
	LDFROM => "lib/Neo4j/Bolt/NeoValue\$(OBJ_EXT) lib/Neo4j/Bolt/CTypeHandlers\$(OBJ_EXT)",
      },
    },
  },
  META_MERGE => $META,
  dist => {
    TAR => 'ptar',  # avoid extended headers in tarball
  },
);

sub MY::postamble {
  # Generate ppport.h automatically (keep it out of the repository)
  return <<"END";
config ::
\t\$(NOECHO) \$(PERLRUN) "-MDevel::PPPort" -E "-f 'include/ppport.h' or do { say 'Writing ppport.h'; Devel::PPPort::WriteFile('include/ppport.h')}"

END
  # To have ppport.h run a code analysis:
  #   perl include/ppport.h --compat-version 5.012 --cplusplus lib/*/*.xs lib/*/*/*.xs
}

sub prompt_for_db {
  my %neo_info;
  my $ans = '';
  while ($ans !~ /^[yn]/i) {
    $ans = prompt("Perform read-only tests on a local database?: ", "n");
  }
  return if (lc $ans eq 'n');

  $neo_info{host} = prompt("Host:port: ", "localhost:7687");
  $neo_info{user} = prompt("User: ","");
  $neo_info{pass} = prompt("Pass: ","");
  $ans = '';
  while ($ans !~ /^[yn]/i) {
    $ans = prompt("Will you allow add/delete tests on your database (cruft will be removed)?: ", "n");
  }
  $neo_info{tests} = (lc $ans eq 'y' ? 1 : 0);
  return \%neo_info;
}
