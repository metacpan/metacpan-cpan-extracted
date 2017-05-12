use inc::Module::Install;

name     'Test-Apache-RewriteRules';
all_from 'lib/Test/Apache/RewriteRules.pm';
author   'Wakaba (id:wakabatan) <wakabatan@hatena.ne.jp>';
license  'Perl';

requires $_ for qw(
    JSON::XS
    Path::Class
    File::Temp
    LWP::UserAgent
    HTTP::Request
    Exporter::Lite

    Test::TCP
    Test::Differences
    Test::Httpd::Apache2
);

test_requires 'Test::More' => 0.96; # for subtest()
test_requires 'Test::Fatal';

tests 't/*.t';
author_tests 'xt';

readme_markdown_from_pod;
auto_set_repository;
auto_include_deps;

WriteAll;
