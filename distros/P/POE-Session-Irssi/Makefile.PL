use inc::Module::Install;

name		'POE-Session-Irssi';
perl_version	'5.006';
all_from	'lib/POE/Session/Irssi.pm';

requires 'Carp'                 => '1.08';
requires 'POE'                  => '1.003';
requires 'POE::Loop::Glib'      => '0.0036';

# evil or what :) at least we can depend on Irssi this way.
# maybe that'll stop the false negative test reports because
# irssi isn't installed.
sub Irssi::version { return 0.9 };
requires 'Irssi'                => '0'; # specifying a version doesn't work

test_requires 'Test::More' => '0';

author_tests('t/author');

auto_provides;

WriteAll;
