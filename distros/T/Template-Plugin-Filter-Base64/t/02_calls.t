use strict;
use Test::More tests => 10;

my $m;

BEGIN {
    use_ok( $m = 'Template::Plugin::Filter::Base64' );
}

can_ok('Template::Plugin::Filter::Base64', 'init');
can_ok('Template::Plugin::Filter::Base64', 'filter');

my $out = '';
my $input = 'Hello!';
my $parser;
eval {
    use Template;
    $parser = Template->new({
        OUTPUT => \$out,
        TRIM => 1,
    });
};
ok($parser, 'new Template object is ok');
ok($parser->process(\$input), 'Template process method is ok');
ok($input eq $out, 'Simple output correct');

$out = '';
$input = q~[% USE Filter.Base64 trim => 1 %]
    [% FILTER b64 %]
        Hello, world!
    [% END %]
~;

ok($parser->process(\$input), 'Template process method with filter 1 is ok');
ok($out eq 'SGVsbG8sIHdvcmxkIQ==', 'Test-filter 1 output correct');

$out = '';
$input = q~[% USE Filter.Base64 trim => 1, use_html_entity => 'cp1251' %]
    [% FILTER b64 %]
        Кириллица cp1251
    [% END %]
~;

ok($parser->process(\$input), 'Template process method with filter 2 is ok');
ok($out eq "JiN4NDFBOyYjeDQzODsmI3g0NDA7JiN4NDM4OyYjeDQzQjsmI3g0M0I7JiN4NDM4OyYjeDQ0Njsm\nI3g0MzA7IGNwMTI1MQ==", 'Test-filter 2 output correct');

done_testing();
