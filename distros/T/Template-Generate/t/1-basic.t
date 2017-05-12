#!/usr/bin/perl
# $File: //member/autrijus/Template-Generate/t/1-basic.t $ $Author: autrijus $
# $Revision: #4 $ $Change: 8169 $ $DateTime: 2003/09/18 06:21:31 $ vim: expandtab shiftwidth=4

use strict;
use Test;

BEGIN { plan tests => 6 };

require Template::Generate;
ok(Template::Generate->VERSION);

my $obj = Template::Generate->new;
ok(ref($obj), 'Template::Generate');

my $doc = "<ul>\n<li>1</li><li>2</li>\n</ul>";
my $data = {record => [{val => 1}, {val => 2}]};
ok(
    $obj->generate($data => $doc), 
    "<ul>\n[% FOREACH record %]<li>[% val %]</li>[% END %]\n</ul>",
);

my @input = (
    {
        first	=> 'Autrijus',
        last	=> 'Tang',
        score	=> 55,
    } => "(Simon's Blog) Score: 55, Name: Autrijus Tang",
    {
        first	=> 'Simon',
        last	=> 'Cozens',
        score	=> 61,
    } => "(Simon's Blog) Score: 61, Name: Simon Cozens",
);

my @template = $obj->generate(@input);
ok("@template",  "(Simon's Blog) Score: [% score %], Name: [% first %] [% last %]");

my $template = $obj->generate(@input);
ok($template,  "(Simon's Blog) Score: [% score %], Name: [% first %] [% last %]");

$doc = "1";
$data = {foo => [{bar => [{baz => 1}]}]};
ok(
    $obj->generate($data => $doc), 
    '[% FOREACH foo %][% FOREACH bar %][% baz %][% END %][% END %]',
);

