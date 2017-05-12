use Test::More;
use utf8;

#plan 'no_plan';
plan tests => 8;

use_ok ('Parse::CPAN::Whois');

#$XML::SAX::ParserPackage = "XML::SAX::Expat";
#$XML::SAX::ParserPackage = "XML::LibXML::SAX";
#$XML::SAX::ParserPackage = "XML::SAX::PurePerl";
my $file = 't/00whois.xml';
#open my $fh, "$file";
#{ local $/; $file = <$fh>; }
#close $fh;

my $handler = Parse::CPAN::Whois->new($file);
isa_ok($handler, 'Parse::CPAN::Whois');

my $author = $handler->author('ALEC');
isa_ok($author, 'Parse::CPAN::Whois::Author');
is ($author->name, '陳衍良', "it's chinese to me, but supposedly correct");
is ($author->asciiname, 'Alec Chen', 'has a ascii transliteration');
is ($author->homepage, 'http://alecchen.com/', 'has a homepage');
is ($author->email, 'alec@cpan.org', 'and an email address');

my $list = $handler->author('XMLML');
is ($list, undef, 'lists are not handled');
