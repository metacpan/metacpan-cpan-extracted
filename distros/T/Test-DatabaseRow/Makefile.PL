use inc::Module::Install;

name           'Test-DatabaseRow';
all_from       'lib/Test/DatabaseRow.pm';

# any version of DBI will do, I guess...?
requires       'DBI'                   => 0;

# I don;t know what version of Scalar::Util first
# shipped with a working "blessed" function
# but at the time of writing this was the
# earliest version still on the CPAN and it did
# support blessed.
requires       'Scalar::Util'          => 1.21;

# T::B::T before 0.09 breaks with modern perls
build_requires 'Test::Builder::Tester' => 0.09;

license 'perl';
githubmeta;
author_tests('xt');

WriteAll;
