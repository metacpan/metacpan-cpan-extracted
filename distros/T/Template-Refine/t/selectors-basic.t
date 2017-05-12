use strict;
use warnings;
use Test::More tests => 14;

use ok 'Template::Refine::Processor::Rule::Select';
use ok 'Template::Refine::Processor::Rule::Select::Pattern';
use ok 'Template::Refine::Processor::Rule::Select::XPath';
use ok 'Template::Refine::Processor::Rule::Select::CSS';

use XML::LibXML;
use Test::Exception;

my $doc =  XML::LibXML->new->parse_string(
    '<div class="foo"><p class="foo">Foo</p><p id="bar">Bar</p><p>OH HAI</p></div>'
);

{
    my $pattern = Template::Refine::Processor::Rule::Select::XPath->new(
        pattern => '//p[@class="foo"]',
    );

    my @nodes = $pattern->select($doc);
    is scalar @nodes, 1, 'got one node';
    is $nodes[0]->textContent, 'Foo';
}

{
    my $pattern = Template::Refine::Processor::Rule::Select::CSS->new(
        pattern => '#bar',
    );

    my @nodes = $pattern->select($doc);
    is scalar @nodes, 1, 'got one node';
    is $nodes[0]->textContent, 'Bar';
}

{
    my $pattern = Template::Refine::Processor::Rule::Select::CSS->new(
        pattern => 'p',
    );

    my @nodes = $pattern->select($doc);
    is scalar @nodes, 3, 'got three nodes';
    is $nodes[0]->textContent, 'Foo';
    is $nodes[1]->textContent, 'Bar';
    is $nodes[2]->textContent, 'OH HAI';
}

{
    my $frag =  XML::LibXML->new->parse_balanced_chunk(
        '<p>foo</p>',
    );

    throws_ok {
        my $pattern = Template::Refine::Processor::Rule::Select::CSS->new(
            pattern => 'p',
        );
        
        my @nodes = $pattern->select($frag);
    } qr/The document must be an XML::LibXML::Document/;
    
    throws_ok {
        my $pattern = Template::Refine::Processor::Rule::Select::XPath->new(
            pattern => '//p[0]',
        );
        
        my @nodes = $pattern->select($frag);
    } qr/The document must be an XML::LibXML::Document/;
    
}
