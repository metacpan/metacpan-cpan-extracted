use Test::More tests => 1;
use Parse::ABNF;
use File::Spec qw();
use IO::File;

my $text = q{
X = %xAA A
A = X %xBB
X =/ ""
};

# Try to avoid the usual newline madness...
$text =~ s/\x0d\x0a|\x0d|\x0a/\n/g;

my $gram = Parse::ABNF->new->parse($text);

my $expt = [
  {
    'value' => {
      'value' => [
        {
          'value' => [
            'AA'
          ],
          'type' => 'hex',
          'class' => 'String'
        },
        {
          'name' => 'A',
          'class' => 'Reference'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'X',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'X',
          'class' => 'Reference'
        },
        {
          'value' => [
            'BB'
          ],
          'type' => 'hex',
          'class' => 'String'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'A',
    'class' => 'Rule'
  },
  {
    'combine' => 'choice',
    'value' => {
      'value' => '',
      'class' => 'Literal'
    },
    'name' => 'X',
    'class' => 'Rule'
  }
];

is_deeply($gram, $expt, "Proper =/ handling");

