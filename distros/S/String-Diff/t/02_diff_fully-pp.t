BEGIN{ $ENV{STRING_DIFF_PP} = 1; }
use strict;
use utf8;
use Test::Base;

use String::Diff qw( diff_fully );

filters { data1 => [qw/ yaml /], data2 => [qw/ yaml string_diff /] };

sub string_diff {
    my $input = shift;
    my $diff = diff_fully($input->{old}, $input->{new}, %{ $input->{options} });
    $diff;
}

run_compare;

__END__

===
--- data1
- []
-
 - ['+', 'perl']
--- data2
old: 
new: perl

===
--- data1
-
 - ['-', 'perl']
- []
--- data2
old: perl
new: 

===
--- data1
- []
- []
--- data2
old: 
new: 

===
--- data1
-
  - ['u', 'pe']
  - ['u', 'rl']
-
  - ['u', 'pe']
  - ['+', 'a']
  - ['u', 'rl']
--- data2
old: perl
new: pearl

===
--- data1
-
  - ['u', 'th']
  - ['-', 'i']
  - ['u', 's ']
  - ['-', 'is ']
  - ['u', 'a']
  - ['-', ' pen']
-
  - ['u', 'th']
  - ['+', "at'"]
  - ['u', 's ']
  - ['u', 'a']
  - ['+', 'll']
--- data2
old: this is a pen
new: "that's all"

===
--- data1
-
  - ['-', 'S']
  - ['u', 'oo']
  - ['-', 'z']
  - ['u', 'y']
-
  - ['+', 'B']
  - ['u', 'oo']
  - ['+', 'f']
  - ['u', 'y']
--- data2
old: Soozy
new: Boofy

===
--- data1
-
  - ['-', 'あ']
  - ['u', 'る']
  - ['-', '晴れた日に散歩をすると']
  - ['u', '、そ']
  - ['-', 'こに']
  - ['u', 'は']
-
  - ['+', 'いつもい']
  - ['u', 'る']
  - ['+', '人がいないので']
  - ['u', '、そ']
  - ['+', 'れ']
  - ['u', 'は']
--- data2
old: ある晴れた日に散歩をすると、そこには
new: いつもいる人がいないので、それは

===
--- data1
-
  - ['u', 'This library is ']
  - ['-', 'free software']
  - ['u', '; you can ']
  - ['u', 'redistribute it ']
  - ['u', 'and']
  - ['-', '/or']
  - ['u', " modify\nit under the same terms as Pe"]
  - ['u', 'rl it']
  - ['u', 'self.']
-
  - ['u', 'This library is ']
  - ['+', '自由なソフト']
  - ['u', '; you can ']
  - ['+', 'not ']
  - ['u', 'redistribute it ']
  - ['+', 'or/']
  - ['u', 'and']
  - ['u', " modify\nit under the same terms as Pe"]
  - ['+', 'a']
  - ['u', 'rl it']
  - ['+', ' ']
  - ['u', 'self.']
--- data2
old: |-
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.
new: |-
  This library is 自由なソフト; you can not redistribute it or/and modify
  it under the same terms as Pearl it self.

===
--- data1
-
  - ['u', 'This library is ']
  - ['-', 'free software']
  - ['u', '; you can ']
  - ['u', 'redistribute it ']
  - ['u', 'and']
  - ['-', '/or']
  - ['u', ' modify']
  - ['-', "\n"]
  - ['u', 'it under the same terms as Pe']
  - ['u', 'rl it']
  - ['u', 'self.']
-
  - ['u', 'This library is ']
  - ['+', '自由なソフト']
  - ['u', '; you can ']
  - ['+', 'not ']
  - ['u', 'redistribute it ']
  - ['+', 'or/']
  - ['u', 'and']
  - ['u', ' modify']
  - ['+', " "]
  - ['u', 'it under the same terms as Pe']
  - ['+', 'a']
  - ['u', 'rl it']
  - ['+', ' ']
  - ['u', 'self.']
--- data2
old: |-
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.
new: This library is 自由なソフト; you can not redistribute it or/and modify it under the same terms as Pearl it self.

===
--- data1
-
  - ['-', "remove\n"]
  - ['u', 'This library is ']
  - ['-', 'free software']
  - ['u', '; you can ']
  - ['u', 'redistribute it ']
  - ['u', 'and']
  - ['-', '/or']
  - ['u', " modify\n(snip)\nit under the same terms as Pe"]
  - ['u', 'rl it']
  - ['u', 'self.']
-
  - ['u', 'This library is ']
  - ['+', '自由なソフト']
  - ['u', '; you can ']
  - ['+', 'not ']
  - ['u', 'redistribute it ']
  - ['+', 'or/']
  - ['u', 'and']
  - ['u', " modify\n(snip)\nit under the same terms as Pe"]
  - ['+', 'a']
  - ['u', 'rl it']
  - ['+', ' ']
  - ['u', 'self.']
  - ['+', "\nappend"]
--- data2
old: |-
  remove
  This library is free software; you can redistribute it and/or modify
  (snip)
  it under the same terms as Perl itself.
new: |-
  This library is 自由なソフト; you can not redistribute it or/and modify
  (snip)
  it under the same terms as Pearl it self.
  append

===
--- data1
-
  - ['u', 'This library is ']
  - ['-', 'free software']
  - ['u', '; you can ']
  - ['u', 'redistribute it ']
  - ['u', 'and']
  - ['-', '/or']
  - ['u', ' modify']
  - ['u', "\n"]
  - ['u', 'it under the same terms as Pe']
  - ['u', 'rl it']
  - ['u', 'self.']
-
  - ['u', 'This library is ']
  - ['+', '自由なソフト']
  - ['u', '; you can ']
  - ['+', 'not ']
  - ['u', 'redistribute it ']
  - ['+', 'or/']
  - ['u', 'and']
  - ['u', ' modify']
  - ['u', "\n"]
  - ['u', 'it under the same terms as Pe']
  - ['+', 'a']
  - ['u', 'rl it']
  - ['+', ' ']
  - ['u', 'self.']
--- data2
old: |-
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.
new: |-
  This library is 自由なソフト; you can not redistribute it or/and modify
  it under the same terms as Pearl it self.
options:
  linebreak: 1

===
--- data1
-
  - ['u', 'r']
  - ['u', 'e']
  - ['u', 'mo']
  - ['-', 've']
  - ['u', "\n"]
  - ['-', 'This library is free software; you can redistribute it and/or modify']
  - ['-', "\n"]
  - ['u', '(snip)']
  - ['u', "\n"]
  - ['u', 'it under the same terms as Pe']
  - ['u', 'rl it']
  - ['u', 'self.']
-
  - ['+', 'This lib']
  - ['u', 'r']
  - ['+', 'ary is 自由なソフト; you can not r']
  - ['u', 'e']
  - ['+', 'distribute it or/and ']
  - ['u', 'mo']
  - ['+', 'dify']
  - ['u', "\n"]
  - ['u', '(snip)']
  - ['u', "\n"]
  - ['u', 'it under the same terms as Pe']
  - ['+', 'a']
  - ['u', 'rl it']
  - ['+', ' ']
  - ['u', 'self.']
  - ['+', "\n"]
  - ['+', 'append']
--- data2
old: |-
  remove
  This library is free software; you can redistribute it and/or modify
  (snip)
  it under the same terms as Perl itself.
new: |-
  This library is 自由なソフト; you can not redistribute it or/and modify
  (snip)
  it under the same terms as Pearl it self.
  append
options:
  linebreak: 1

===
--- data1
-
  - ['u', '1']
  - ['-', '0']
-
  - ['u', '1']
  - ['+', '1']
--- data2
old: 10
new: 11

