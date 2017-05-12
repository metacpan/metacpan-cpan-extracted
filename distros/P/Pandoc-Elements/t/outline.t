use strict;
use 5.010;
use Test::More;
use Pandoc::Elements;
use Pandoc;

plan skip_all => 'pandoc >= 1.12.1 not available'
    unless (pandoc and pandoc->version > '1.12.1');

my $doc = pandoc->file('t/documents/outline.md');

my $outline = $doc->outline;

sub simplify {
    my $o = shift;
    $o->{header} //= Header 0, {}, [ Str '' ];
    [
        ('#' x $o->{header}->level . ' ' . $o->{header}->string),
        join(' / ', map { $_->string } @{$o->{blocks}}),
        [ map { simplify($_) } @{$o->{sections}} ]
    ]
}

is_deeply simplify($doc->outline),
[
  ' ', 'test document',
  [
    [
      '## section 0.1', '', [
        [ '### section 0.1.1', '', [] ]
      ]
    ],
    [ '# chapter 1', 'with / content', [] ],
    [
      '# chapter 2', '',
      [
        [ '## section 2.1', '', [] ],
        [
          '## section 2.2', 'text',
          [
            [ '#### subsubsection 2.2.1.1.1', '', [] ],
            [ '### subsubsection 2.2.2', '', [] ]
          ]
        ]
      ]
    ],
    [ '# chapter 3', 'header in table', [] ],
    [ '# chapter 4', '', [] ]
  ]
], 'outline()';

is_deeply simplify($doc->outline(2)),
[
  ' ', 'test document', [
    [ '## section 0.1', 'section 0.1.1', [] ],
    [ '# chapter 1', 'with / content', [] ],
    [
      '# chapter 2', '',
      [
        [ '## section 2.1', '', [] ],
        [
          '## section 2.2',
          'text / subsubsection 2.2.1.1.1 / subsubsection 2.2.2', []
        ]
      ]
    ],
    [ '# chapter 3', 'header in table', [] ],
    [ '# chapter 4', '', [] ]
  ]
], 'outline(2)';

done_testing;
