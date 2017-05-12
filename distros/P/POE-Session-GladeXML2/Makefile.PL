use inc::Module::Install;

name		'POE-Session-GladeXML2';
perl_version	'5.006';
all_from	'lib/POE/Session/GladeXML2.pm';

requires	'Carp'			=> '1.08';
requires	'POE'			=> '1.0002';
requires	'Gtk2::GladeXML'	=> '1.006';
requires	'POE::Loop::Glib'	=> '0.0034';

test_requires	'Test::More'	=> '0';

author_tests('t/author');

auto_provides;

WriteAll;
