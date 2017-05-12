use strict;
use warnings;
use Test::More tests => 2;
use Test::Exception;

use XML::LibXML;
use Template::Refine::Fragment;

my $p = XML::LibXML::Element->new('p');
$p->addChild(XML::LibXML::Text->new('foo'));

my $frag;
lives_ok {
    $frag = Template::Refine::Fragment->new(
        fragment => $p,
    );
} 'creating fragment from element is ok';

is $frag->render, $p->toString, 'this worked';
