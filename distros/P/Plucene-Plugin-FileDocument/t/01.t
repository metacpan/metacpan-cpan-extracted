use strict;

use Test::More tests => 17;
use Plucene::Plugin::FileDocument;

{
	my $doc = Plucene::Plugin::FileDocument->new($0);
	isa_ok $doc => "Plucene::Document";

	my $path = $doc->get('path');
	isa_ok $path => "Plucene::Document::Field";
	is $path->name, "path", "Got the path";
	is $path->string, $0, " - this file";
	ok $path->is_indexed, "And it's indexed";

	my $text = $doc->get('text');
	isa_ok $text => "Plucene::Document::Field";
	is $text->name, "text", "Got the text";
	like $text->string, qr/use Test::More/, " - it's a test";
	ok $text->is_indexed, "And it's indexed";

	my $atime = $doc->get('atime');
	is $atime, undef, "No atime field";
}

{
	my $doc = Plucene::Plugin::FileDocument->new($0 =>     
		atime => sub { (stat(+shift->{path}))[8] },
	);

	isa_ok $doc => "Plucene::Document";

	is $doc->get('path')->string, $0, "Still got path";
	like $doc->get('text')->string, qr/Test::More/, "Still got text";

	my $atime = $doc->get('atime');
	isa_ok $atime => "Plucene::Document::Field";
	is $atime->name, "atime", "Got atime";
	ok time - $atime->string < 60, "Last accessed in last minute";
	ok $atime->is_indexed, "And it's indexed";
}


