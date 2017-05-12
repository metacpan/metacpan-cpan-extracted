#!perl -w

use strict;

my @templates = (
    {
      name => 'empty',
      in  => '',
      out => '',
      sections => [ ],
    },
    {
      name => 'nolang section',
      in  => 'foo',
      out => 'foo',
      sections => [ { nolang => 'foo' } ],
    },
    {
      name => 'empty lang section',
      in  => '<t></t>',
      out => '',
      sections => [ ],
    },
    {
      name => 'simple lang section',
      in  => '<t><fr>foo</fr></t>',
      out => 'foo',
      sections => [ { lang => { fr => 'foo' } } ],
    },
    {
      name => 'other lang section',
      in  => '<t><en>foo</en></t>',
      out => '',
      sections => [ { lang => { en => 'foo' } } ],
    },
    {
      name => 'multi lang section',
      in  => "<t><fr>foo</fr>\n<en>bar</en></t>",
      out => "foo",
      sections => [ { lang => { fr => 'foo', en => 'bar' } } ],
    },
    {
      name => 'arbitrary lang names',
      lang => ';',
      in => '<t><;>foo</;></t>',
      out => 'foo',
      sections => [ { lang => { ';' => 'foo' } } ],
    },
    {
      name => 'multiple sections',
      in  => "A<t><fr>foo</fr></t>B<t><en>bar</en></t>C",
      out => 'AfooBC',
      sections => [ { nolang => 'A' },
                    {   lang => { fr => 'foo' } },
                    { nolang => 'B' },
                    {   lang => { en => 'bar' } },
                    { nolang => 'C' },
                  ],
    },
    {
      name => 'fr_CA exact match',
      lang => 'fr_CA',
      in  => "<t><fr>foo</fr><fr_CA>bar</fr_CA></t>",
      out => 'bar',
      sections => [ { lang => { fr => 'foo', fr_CA => 'bar' } } ],
    },
    {
      name => 'fr exact match',
      lang => 'fr',
      in  => "<t><fr>foo</fr><fr_CA>bar</fr_CA></t>",
      out => 'foo',
      sections => [ { lang => { fr => 'foo', fr_CA => 'bar' } } ],
    },
    {
      name => 'fr_CA fallback to fr',
      lang => 'fr_CA',
      in  => "<t><fr>foo</fr><fr_BE>bar</fr_BE></t>",
      out => 'foo',
      sections => [ { lang => { fr => 'foo', fr_BE => 'bar' } } ],
    },
    {
      name => 'fr-CA fallback to fr',
      lang => 'fr-CA',
      in  => "<t><fr>foo</fr><fr_BE>bar</fr_BE></t>",
      out => 'foo',
      sections => [ { lang => { fr => 'foo', fr_BE => 'bar' } } ],
    },
    {
      name => 'fr_CA fallback to fr_BE',
      lang => 'fr_CA',
      in  => "<t><fr_FR>foo</fr_FR><fr_BE>bar</fr_BE><fr_CH>baz</fr_CH></t>",
      out => 'bar',
      sections => [ { lang => { fr_FR => 'foo', fr_BE => 'bar', fr_CH => 'baz' } } ],
    },
    {
      name => 'fr fallback to fr_BE',
      lang => 'fr',
      in  => "<t><fr_FR>foo</fr_FR><fr_BE>bar</fr_BE><fr_CH>baz</fr_CH></t>",
      out => 'bar',
      sections => [ { lang => { fr_FR => 'foo', fr_BE => 'bar', fr_CH => 'baz' } } ],
    },
);
use Test::More;
plan tests => 3 + 7 * @templates;

require_ok('Template::Multilingual');
my $template = Template::Multilingual->new;
ok($template);

for my $t (@templates) {
    my $lang = $t->{lang} || 'fr';
    $template->language($lang);
    is($template->language, $lang, "$t->{name}: get/set language");
    my $output;
    ok($template->process(\$t->{in}, {}, \$output), "$t->{name}: process");
    is($output, $t->{out}, "$t->{name}: output");
    is_deeply($template->{PARSER}->sections, $t->{sections}, "$t->{name}: sections");
}

# 2nd pass with overridden LANGUAGE_VAR
$template = Template::Multilingual->new(LANGUAGE_VAR => 'global.language');
ok($template);

for my $t (@templates) {
    my $lang = $t->{lang} || 'fr';
    my $output;
    ok($template->process(\$t->{in}, { global => { language => $lang }}, \$output), "$t->{name}: process (overridden LANGUAGE_VAR)");
    is($output, $t->{out}, "$t->{name}: output (overridden LANGUAGE_VAR)");
    is_deeply($template->{PARSER}->sections, $t->{sections}, "$t->{name}: sections (overridden LANGUAGE_VAR)");
}

__END__
