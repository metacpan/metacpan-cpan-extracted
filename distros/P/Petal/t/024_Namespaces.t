#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

my $template_file = 'namespaces.xml';
$Petal::DISK_CACHE = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT = 1;
$Petal::BASE_DIR = 't/data';
my $template = new Petal ($template_file);
my $string;


$string = $template->process (
	replace   => 'REPLACE',
	content   => 'CONTENT',
	attribute => 'ATTRIBUTE',
        elements  => [ 'ELEMENT1', 'ELEMENT2', 'ELEMENT3' ],
);

like ($string => qr/REPLACE/);
like ($string => qr/\Q<p>CONTENT<\/p>\E/);
like ($string => qr/\Q<p attribute="ATTRIBUTE">yo<\/p>\E/);
like ($string => qr/\Q<li>ELEMENT1<\/li>\E/);
like ($string => qr/\Q<li>ELEMENT2<\/li>\E/);
like ($string => qr/\Q<li>ELEMENT3<\/li>\E/);
unlike ($string => qr/\Qtal:\E/);
unlike ($string => qr/\Qxmlns:\E/);


$Petal::OUTPUT = "XHTML";
$string = $template->process (
	replace   => 'REPLACE',
	content   => 'CONTENT',
	attribute => 'ATTRIBUTE',
        elements  => [ 'ELEMENT1', 'ELEMENT2', 'ELEMENT3' ],
);

like ($string => qr/REPLACE/);
like ($string => qr/\Q<p>CONTENT<\/p>\E/);
like ($string => qr/\Q<p attribute="ATTRIBUTE">yo<\/p>\E/);
like ($string => qr/\Q<li>ELEMENT1<\/li>\E/);
like ($string => qr/\Q<li>ELEMENT2<\/li>\E/);
like ($string => qr/\Q<li>ELEMENT3<\/li>\E/);
unlike ($string => qr/\Qtal:\E/);
unlike ($string => qr/\Qxmlns:\E/);
