use strict;
use Test::More tests => 8;

my $m;

BEGIN {
    use_ok( $m = 'Template::Plugin::Filter::Scss' );
}

can_ok('Template::Plugin::Filter::Scss', 'init');
can_ok('Template::Plugin::Filter::Scss', 'filter');

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
$input = q~[% USE Filter.Scss output_style => 'compressed' %]
    [% FILTER scss %]
        .col305 {
            position: relative;
        }
    [% END %]
~;

ok($parser->process(\$input), 'Template process method with filter is ok');
ok($out eq '.col305{position:relative}', 'Test-filter output correct');

done_testing();
