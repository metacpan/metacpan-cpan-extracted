#perl -w
use strict;
use Sphinx::XML::Pipe2;
use Test::More tests => 1;

my $p = Sphinx::XML::Pipe2->new;

$p->attr('type', 'int');
$p->attr('type', 'str2ordianal');
map $p->field($_), qw(name content);
$p->add(1, 1, 'test', 'hi', 'there');

ok($p->xml eq join('', <main::DATA>) , 'simple');

__DATA__
<?xml version="1.0"?>
<sphinx:docset>
  <sphinx:schema>
    <sphinx:field name="name"/>
    <sphinx:field name="content"/>
    <sphinx:attr name="type" type="int"/>
    <sphinx:attr name="type" type="str2ordianal"/>
  </sphinx:schema>
  <sphinx:document id="1">
    <type>1</type>
    <type>test</type>
    <name>hi</name>
    <content>there</content>
  </sphinx:document>
</sphinx:docset>
