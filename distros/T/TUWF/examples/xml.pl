#!/usr/bin/perl

# This is an example on how to use TUWF::XML outside of the TUWF framework.

use strict;
use warnings;


# See examples/singlefile.pl for an explanation on what this does
use Cwd 'abs_path';
our $ROOT;
BEGIN { ($ROOT = abs_path $0) =~ s{/examples/xml.pl$}{}; }
use lib $ROOT.'/lib';


# load TUWF::XML
use TUWF::XML 'xml_escape', ':xml';


# xml_escape() can be used as a separate utility function
printf "xml_escape: %s\n\n", xml_escape '<br />';


# generate a simple html page using the OO interface
print "HTML page:\n";
my $h = TUWF::XML->new();
$h->html();
 $h->head();
  $h->title('Page Title');
 $h->end();
 $h->body();
  $h->h1('Page Title');
  $h->p('Paragraph');
 $h->end();
$h->end('html');


# generate an pretty-printed XML document using the functional interface
print "\n\nXML document:\n";
TUWF::XML->new(pretty => 2, default => 1);
xml();
tag('root', attribute => 'value');
 tag('tag', 'Contents');
 tag('tag', attribute => 'value', 'Contents');
end('root');
print "\n";

