#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 8;

BEGIN {use_ok 'MojoX::I18N::Lexemes'};

my $l = new_ok 'MojoX::I18N::Lexemes';

is_deeply
    $l->parse(q|Simple <%=l 'lexem' %>|),
    ['lexem'],
    'simple lexem';

is_deeply
    $l->parse(q|Escaped <%==l 'lexem' %>|),
    ['lexem'],
    'escaped lexem';

is_deeply
    $l->parse(qq|Multiline <%==l 'lexem\nlexem\nlexem' %>|),
    ["lexem\nlexem\nlexem"],
    'multiline lexem';

my $template = <<TEMPLATE
Just lexems <%=l 'lexem1' %> <%==l 'lexem2' %>
Multiline <%==l 'Hello
World' %>
Another <%=l 'lexem3' %>
TEMPLATE
;

is_deeply
    $l->parse($template),
    ['lexem1', 'lexem2', "Hello\nWorld", 'lexem3'],
    'complex template';

$l->helper('translate');
is_deeply
    $l->parse(q|Can you <%==translate 'this' %>?|),
    ['this'],
    'other helper name';
$l->helper('l');

is_deeply 
    $l->parse(q|Complex <%==l 'text [_1] [_2]', 'with', 'variables'%>|),
    ['text [_1] [_2]'],
    'with arguments';
