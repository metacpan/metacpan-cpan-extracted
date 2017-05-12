use inc::Module::Install;
use Module::Install::Repository;
use Module::Install::ReadmePodFromPod;
name 'MooX-Types-MooseLike-Email';
all_from 'lib/MooX/Types/MooseLike/Email.pm';
readme_pod_from 'lib/MooX/Types/MooseLike/Email.pm';

requires 'MooX::Types::MooseLike' => '0.16';
requires 'Email::Valid';
requires 'Email::Valid::Loose';
requires 'Email::Abstract';

test_requires 'Test::More';
test_requires 'Test::Exception';
test_requires 'Scalar::Util';

tests 't/*.t';
author_tests 'xt';

auto_set_repository;
auto_include;
WriteAll;
