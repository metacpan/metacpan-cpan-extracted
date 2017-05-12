
BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for testing by the author');
  }
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::EOL 0.18

use Test::More 0.88;
use Test::EOL;

my @files = (
    'bin/repositorio',
    'lib/Rex/Repositorio.pm',
    'lib/Rex/Repositorio/Repository/Apt.pm',
    'lib/Rex/Repositorio/Repository/Base.pm',
    'lib/Rex/Repositorio/Repository/Docker.pm',
    'lib/Rex/Repositorio/Repository/OpenSuSE.pm',
    'lib/Rex/Repositorio/Repository/Plain.pm',
    'lib/Rex/Repositorio/Repository/Yum.pm',
    'lib/Rex/Repositorio/Repository_Factory.pm',
    'lib/Rex/Repositorio/Server/Docker.pm',
    'lib/Rex/Repositorio/Server/Docker/Auth.pm',
    'lib/Rex/Repositorio/Server/Docker/Helper/Auth.pm',
    'lib/Rex/Repositorio/Server/Docker/Helper/Auth/Plain.pm',
    'lib/Rex/Repositorio/Server/Docker/Image.pm',
    'lib/Rex/Repositorio/Server/Docker/Index.pm',
    'lib/Rex/Repositorio/Server/Docker/Mojolicious/Plugin/DockerSession.pm',
    'lib/Rex/Repositorio/Server/Docker/Repository.pm',
    'lib/Rex/Repositorio/Server/Docker/Search.pm',
    'lib/Rex/Repositorio/Server/Helper/Common.pm',
    'lib/Rex/Repositorio/Server/Helper/Proxy.pm',
    'lib/Rex/Repositorio/Server/Helper/RenderFile.pm',
    'lib/Rex/Repositorio/Server/Yum.pm',
    'lib/Rex/Repositorio/Server/Yum/Errata.pm',
    'lib/Rex/Repositorio/Server/Yum/File.pm',
    't/author-critic.t',
    't/author-eol.t',
    't/author-pod-syntax.t',
    't/base.t',
    't/release-kwalitee.t'
);

eol_unix_ok($_, { trailing_whitespace => 1 }) foreach @files;
done_testing;
