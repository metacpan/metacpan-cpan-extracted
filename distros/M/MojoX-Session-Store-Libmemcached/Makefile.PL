use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'MojoX::Session::Store::Libmemcached',
    AUTHOR        => 'Daniel Mascarenhas <daniel.mts@gmail.com>',
    VERSION_FROM  => 'lib/MojoX/Session/Store/Libmemcached.pm',
    #ABSTRACT_FROM => 'lib/MojoX/Session/Store/Libmemcached.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE' => 'perl')
        : ()),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More'              => 0,
        'Mojolicious'             => '0.999931',
        'MojoX::Session'          => '0.21',
        'Memcached::libmemcached' => '0.4402',
        'Storable'                => 0,
        'MIME::Base64'            => 0,
        'Digest::SHA1'            => 0
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES    => 'MojoX-Session-Store-*'},
    test  => {TESTS    => 't/*.t t/*/*.t'}
);
