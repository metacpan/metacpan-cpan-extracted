use strict;
use warnings;
use Test::More tests => 8;

use File::Temp ();
BEGIN { $ENV{PAR_TEMP} = File::Temp::tempdir( CLEANUP => 1 ); }

BEGIN { use_ok('PAR::Repository::Client') };

chdir('t') if -d 't';
push @INC, 'lib', File::Spec->catdir(qw(t lib));
require RepoMisc;

my $client = RepoMisc::client_ok( File::Spec->catdir('data', 'repo_with_simple_dependencies') );
$client->perl_version('5.10.0');
$client->architecture('x86_64-linux-gnu-thread-multi');

my $deps = $client->_resolve_static_dependencies("File-Stream-2.20-x86_64-linux-gnu-thread-multi-5.10.0.par");
ok(ref($deps) eq 'ARRAY');
is_deeply(
  [sort @$deps],
  [sort qw(
    YAPE-Regex-3.03-x86_64-linux-gnu-thread-multi-5.10.0.par
    PAR-0.984-x86_64-linux-gnu-thread-multi-5.10.0.par
  )],
);

$deps = $client->get_module_dependencies("File::Stream");
ok(ref($deps) eq 'ARRAY');
is_deeply(
  [shift @$deps, sort @$deps],
  ['File-Stream-2.20-x86_64-linux-gnu-thread-multi-5.10.0.par',
   sort qw(
    YAPE-Regex-3.03-x86_64-linux-gnu-thread-multi-5.10.0.par
    PAR-0.984-x86_64-linux-gnu-thread-multi-5.10.0.par
  )],
);

# FIXME/TODO test get_script_dependencies

