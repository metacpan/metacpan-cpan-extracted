use inc::Module::Install 0.91;
use Module::Install::ReadmeFromPod;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;
use Module::Install::AssertOS;

assertos qw/ Unix /;

all_from    'lib/Mock/Apache.pm';
readme_from 'lib/Mock/Apache.pm';

requires 'Apache::FakeTable';
requires 'Apache::ConfigParser';
requires 'Capture::Tiny';
requires 'Carp';
requires 'Class::Accessor';
requires 'Cwd';
requires 'HTTP::Headers';
requires 'HTTP::Response';
requires 'IO::Scalar';
requires 'Log::Log4perl';
requires 'Module::Loaded';
requires 'parent';
requires 'Readonly';
requires 'Scalar::Util';
requires 'URI';
requires 'URI::QueryParam';


test_requires 'Test::More' => '0.88';

author_requires 'Test::NoTabs';
author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Spelling' => '0.11'
    if $] >= 5.010000;  # prerequisites require 5.10

author_tests 't/author';

resources repository => 'https://github.com/fordmason/Mock-Apache.git';

WriteAll;
