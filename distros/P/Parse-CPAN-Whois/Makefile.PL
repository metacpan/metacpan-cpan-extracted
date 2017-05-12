use inc::Module::Install;

# we have an author sub with docs, so have to declare this.
author		'Martijn van Beers <martijn@cpan.org>';

perl_version	'5.006';
all_from	'lib/Parse/CPAN/Whois.pm';


requires	'XML::SAX::ParserFactory'	=> '0';
requires	'XML::SAX::Base'		=> '1.04';

test_requires	'Test::More'	=> '0';


author_tests('t/author');

auto_provides;

bugtracker 'http://rt.cpan.org/Dist/Display.html?Status=Active&Queue=Parse-CPAN::Whois';

WriteAll;
