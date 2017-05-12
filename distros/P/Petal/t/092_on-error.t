#!/usr/bin/perl
use warnings;
use strict;
use lib ('lib');
use Test::More 'no_plan';
use Petal;

$|=1;

$Petal::BASE_DIR     = './t/data/';
$Petal::DISK_CACHE   = 0;
$Petal::MEMORY_CACHE = 0;
$Petal::TAINT        = 1;

my $template_file = 'eval2.xml';
my $template      = new Petal ($template_file);
my $string        = $template->process;

TODO: {
    local $TODO = 'http://www.zope.org/Wikis/DevSite/Projects/ZPT/TAL%20Specification%201.4/#on-error';
    like ($string, qr/<span>booo<\/span>/, 'booo (XML out)');
};

unlike ($string, qr/<</,       'invalid XML');
like ($string, qr/&lt;&lt;/,   'valid XML');

__END__
