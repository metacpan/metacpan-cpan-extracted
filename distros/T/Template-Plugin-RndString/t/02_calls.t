use strict;
use Test::More tests => 5;

my $m;

BEGIN {
    use_ok( $m = 'Template::Plugin::RndString' );
}

can_ok('Template::Plugin::RndString', 'make');

my $out = '';
my $input = '[% USE RndString %][% RndString.make %]';
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
ok(length $out == 32, 'Simple output correct');

done_testing();
