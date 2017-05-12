#!perl -w

use strict;

my %test = (
    in  => '<t><fr>foo</fr></t>',
    out => 'foo',
    sections => [ { lang => { fr => 'foo' } } ],
);
use Test::More tests => 9;

require_ok('Template::Multilingual');
my $template = Template::Multilingual->new(
  TAG_STYLE => 'star',
);
ok($template);

$template->language('fr');
my $output;
ok($template->process(\$test{in}, {}, \$output), 'process');
is($output, $test{out}, 'output');
is_deeply($template->{PARSER}->sections, $test{sections}, 'sections');


$template = Template::Multilingual->new(
    START_TAG => quotemeta('<+'),
    END_TAG   => quotemeta('+>'),
);
ok($template);
ok($template->process(\$test{in}, {}, \$output), 'process');
is($output, $test{out}, 'output');
is_deeply($template->{PARSER}->sections, $test{sections}, 'sections');

__END__
