use Module::Build;
$build = Module::Build->new(
  dist_author => 'Mark A. Jensen',
  dist_name => 'Neo4j-Cypher-Abstract',
  dist_version_from => 'lib/Neo4j/Cypher/Abstract.pm',
  dist_abstract => 'Generate Cypher queries in Perl',
  requires => {
    'Scalar::Util' => 0,
    'List::Util' => '1.33'
   },
  configure_requires => {
    'Module::Build' => 0
   },
  build_requires => {
    'Tie::IxHash' => 0,
    'Try::Tiny' => 0,
   },
  meta_merge => {
    resources => {
      bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Neo4j-Cypher-Abstract',
      repository  => 'http://github.com/majensen/cypher-abstract.git',
    }
   },
  perl => 5.010,
  license => 'perl'
);
$build->create_build_script;
