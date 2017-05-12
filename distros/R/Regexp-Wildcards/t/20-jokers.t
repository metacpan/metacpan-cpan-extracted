#!perl -T

use strict;
use warnings;

use Test::More tests => 3 * (4 + 2 + 7 + 8 + 6 + 2) * 3;

use Regexp::Wildcards;

sub try {
 my ($rw, $s, $x, $y) = @_;
 $y = $x unless defined $y;
 my $d = $rw->{do};
 $d = join ' ', keys %$d if ref($d) eq 'HASH';
 is($rw->convert('ab' . $x),      'ab' . $y,      $s . " (begin) [$d]");
 is($rw->convert('a' . $x . 'b'), 'a' . $y . 'b', $s . " (middle) [$d]");
 is($rw->convert($x . 'ab'),      $y . 'ab',      $s . " (end) [$d]");
}

sub alltests {
 my ($d, $one, $any) = @_;

 my $rw = Regexp::Wildcards->new;
 $rw->do(set => $d);

 $d = join ' ', keys %$d if ref($d) eq 'HASH';

 # Simple

 try $rw, "simple $any", $any, '.*';
 try $rw, "simple $one", $one, '.';

 is($rw->convert($one.$any.'ab'), '..*ab',
    "simple $one and $any (begin) [$d]");
 is($rw->convert($one.'a'.$any.'b'), '.a.*b',
    "simple $one and $any (middle) [$d]");
 is($rw->convert($one.'ab'.$any), '.ab.*',
    "simple $one and $any (end) [$d]");

 is($rw->convert($any.'ab'.$one), '.*ab.',
    "simple $any and $one (begin) [$d]");
 is($rw->convert('a'.$any.'b'.$one), 'a.*b.',
    "simple $any and $one (middle) [$d]");
 is($rw->convert('ab'.$any.$one), 'ab.*.',
    "simple $any and $one (end) [$d]");

 # Multiple

 try $rw, "multiple $any", $any x 2, '.*';
 try $rw, "multiple $one", $one x 2, '..';

 # Captures

 $rw->capture('single');
 try $rw, "multiple capturing $one", $one.$one.'\\'.$one.$one,
                                    '(.)(.)\\'.$one.'(.)';

 $rw->capture(add => [ qw<any greedy> ]);
 try $rw, "multiple capturing $any (greedy)", $any.$any.'\\'.$any.$any,
                                              '(.*)\\'.$any.'(.*)';
 my $wc = $any.$any.$one.$one.'\\'.$one.$one.'\\'.$any.$any;
 try $rw, "multiple capturing $any (greedy) and capturing $one",
          $wc, '(.*)(.)(.)\\'.$one.'(.)\\'.$any.'(.*)';

 $rw->capture(set => [ qw<any greedy> ]);
 try $rw, "multiple capturing $any (greedy) and non-capturing $one",
          $wc, '(.*)..\\'.$one.'.\\'.$any.'(.*)';

 $rw->capture(rem => 'greedy');
 try $rw, "multiple capturing $any (non-greedy)", $any.$any.'\\'.$any.$any,
                                                 '(.*?)\\'.$any.'(.*?)';
 try $rw, "multiple capturing $any (non-greedy) and non-capturing $one",
          $wc, '(.*?)..\\'.$one.'.\\'.$any.'(.*?)';

 $rw->capture({ single => 1, any => 1 });
 try $rw, "multiple capturing $any (non-greedy) and capturing $one",
          $wc, '(.*?)(.)(.)\\'.$one.'(.)\\'.$any.'(.*?)';

 $rw->capture();

 # Escaping

 try $rw, "escaping $any", '\\'.$any;
 try $rw, "escaping $any before intermediate newline", '\\'.$any ."\n\\".$any;
 try $rw, "escaping $one", '\\'.$one;
 try $rw, "escaping $one before intermediate newline", '\\'.$one ."\n\\".$one;
 try $rw, "escaping \\\\\\$any", '\\\\\\'.$any;
 try $rw, "escaping \\\\\\$one", '\\\\\\'.$one;
 try $rw, "not escaping \\\\$any", '\\\\'.$any, '\\\\.*';
 try $rw, "not escaping \\\\$one", '\\\\'.$one, '\\\\.';

 # Escaping escapes

 try $rw, 'escaping \\', '\\', '\\\\';
 try $rw, 'not escaping \\', '\\\\', '\\\\';
 try $rw, 'escaping \\ before intermediate newline', "\\\n\\", "\\\\\n\\\\";
 try $rw, 'not escaping \\ before intermediate newline', "\\\\\n\\\\", "\\\\\n\\\\";
 try $rw, 'escaping regex characters', '[]', '\\[\\]';
 try $rw, 'not escaping escaped regex characters', '\\\\\\[\\]';

 # Mixed

 try $rw, "mixed $any and \\$any", $any.'\\'.$any.$any, '.*\\'.$any.'.*';
 try $rw, "mixed $one and \\$one", $one.'\\'.$one.$one, '.\\'.$one.'.';
}

alltests 'jokers',           '?', '*';
alltests 'sql',              '_', '%';
alltests [ qw<jokers sql> ], '_', '*';
