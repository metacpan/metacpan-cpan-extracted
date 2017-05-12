use inc::Module::Install;
use Module::Install::AuthorTests;

name 'String-TT';
all_from 'lib/String/TT.pm';

requires 'Template';
requires 'List::Util';
requires 'PadWalker';
requires 'Sub::Exporter';
requires 'Carp';
test_requires 'Test::Exception';
test_requires 'Test::More' => '0.88';
test_requires 'Test::TableDriven';
test_requires 'ok';

author_tests 't/author';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/String/TT.pm > README")
        and die;
}

resources repository => 'http://github.com/jrockway/string-tt.git';

WriteAll();

