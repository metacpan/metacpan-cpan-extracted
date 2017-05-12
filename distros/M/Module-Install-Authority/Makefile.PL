use strict;
use warnings;
no warnings 'redefine';
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;
use Module::Install::ReadmeFromPod;

all_from 'lib/Module/Install/Authority.pm';
readme_from 'lib/Module/Install/Authority.pm';

author_requires 'Test::NoTabs';
author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';

test_requires 'Test::More' => '0.88';
author_tests 't/author';

resources repository => 'git://github.com/bobtfish/Module-Install-Authority.git';

# Load ourself in author mode so that the dist META.yml always
# gets generated with the latest version of the code.
if ($Module::Install::AUTHOR) {
    require 'lib/Module/Install/Authority.pm';
}

authority 'cpan:BOBTFISH';

license 'perl';

WriteAll;

