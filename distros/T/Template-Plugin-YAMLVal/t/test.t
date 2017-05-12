use Test::More tests => 1;

use Template::Toolkit::Simple;

my $template = <<'...';
[% USE YAMLVal -%]
quoted: [% quoted.yamlval %]
double: [% double.yamlval %]
blank: [% blank.yamlval %]
literal: [% literal.yamlval %]
hash: [% hash.yamlval %]
array: [% array.yamlval %]
empty: [% empty.yamlval %]
nested: [% nested.yamlval %]
spaces: [% spaces.yamlval %]
...

my $data = {
    quoted => 'x: y',
    double => "C'Dent",
    blank => '',
    literal => <<'...',
A flea and a fly in a flue
Were caught, so what could they do?
    Said the fly, "Let us flee."
    "Let us fly," said the flea.
So they flew through a flaw in the flue.
...
    hash => { qw[ I like pie ! ] },
    empty => {},
    nested => {foo => {bar => [1, 2]}},
    array => [2, 4, 42],
    spaces => '   ',
};

is tt->render(\$template, $data), <<'...', 'It just works';
quoted: 'x: y'
double: C'Dent
blank: ''
literal: |
  A flea and a fly in a flue
  Were caught, so what could they do?
      Said the fly, "Let us flee."
      "Let us fly," said the flea.
  So they flew through a flaw in the flue.
hash: 
  I: like
  pie: '!'
array: 
- 2
- 4
- 42
empty: {}
nested: 
  foo:
    bar:
    - 1
    - 2
spaces: '   '
...
