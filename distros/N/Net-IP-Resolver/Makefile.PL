use inc::Module::Install;

name           'Net-IP-Resolver';
all_from       'lib/Net/IP/Resolver.pm';
requires       'Net::IP::Match::XS' => '0.03';
build_requires 'Test::More'         => '0.47';
build_requires 'File::Spec'         => '0.80';

WriteAll;
