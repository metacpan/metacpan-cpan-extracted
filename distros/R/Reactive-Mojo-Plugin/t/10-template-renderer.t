#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok( 'Reactive::Mojo::TemplateRenderer' ) || print "Bail out!\n";
}

my $renderer = Reactive::Mojo::TemplateRenderer->new;

my $example_html = <<HTML;
    <div>
        hello
    </div>
HTML

my $injected = $renderer->inject_attribute($example_html, 'snapshot', {test => 'value'});

my $expected = <<HTML;
<div snapshot="{
   &quot;test&quot; : &quot;value&quot;
}
" >
        hello
    </div>
HTML

cmp_ok($injected, 'eq', $expected, 'Injected snapshot data');
