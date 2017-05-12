use strict;
use warnings;
use Test::More tests => 8;
use File::Temp ();
BEGIN { $ENV{PAR_TEMP} = File::Temp::tempdir( CLEANUP => 1 ); }
use File::Spec;

BEGIN { use_ok('PAR::Repository::Client') };

chdir('t') if -d 't';
push @INC, 'lib', File::Spec->catdir(qw(t lib));
require RepoMisc;

# Test whether a repository prior to P::R 0.18 expectedly
# fails if static_dependencies are enabled.


my $client;
eval {
  $client = PAR::Repository::Client->new(
    uri => File::Spec->catdir(qw(data repo_no_static_deps)),
    static_dependencies => 1,
    cache_dir => $ENV{PAR_TEMP}, # be a good /tmp citizen
  );
};
ok( $@ );
ok( $@ =~ /static/);
ok( not defined $client );

eval {
  $client = PAR::Repository::Client->new(
    uri => File::Spec->catdir(qw(data repo_no_static_deps)),
    static_dependencies => 0,
    cache_dir => $ENV{PAR_TEMP}, # be a good /tmp citizen
  );
};
ok( !$@ );
ok( defined $client );
isa_ok( $client, 'PAR::Repository::Client' );

