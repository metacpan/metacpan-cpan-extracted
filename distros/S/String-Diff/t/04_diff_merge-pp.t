BEGIN{ $ENV{STRING_DIFF_PP} = 1; }
use strict;
use utf8;
use Test::Base;

use String::Diff qw( diff_merge );

filters { data1 => 'chomp', data2 => [qw/ yaml string_diff /] };

sub string_diff {
    my $input = shift;
    diff_merge($input->{old}, $input->{new}, %{ $input->{options} });
}

run_is;

__END__

===
--- data1
pe[a]r[a]l
--- data2
old: pearal
new: perl

===
--- data1
pe[a]rl
--- data2
old: pearl
new: perl

===
--- data1
pe{a}rl
--- data2
old: perl
new: pearl

===
--- data1
th[i]{at'}s [is ]a[ pen]{ll}
--- data2
old: this is a pen
new: that's all

===
--- data1
[S]{B}oo[z]{f}y
--- data2
old: Soozy
new: Boofy

===
--- data1
(?:S|B)oo(?:z|f)y
--- data2
old: Soozy
new: Boofy
options:
  remove_open: '(?:'
  remove_close: ''
  append_open: ''
  append_close: ')'
  separator: '|'

===
--- data1
[あ]{いつもい}る[晴れた日に散歩をすると]{人がいないので}、そ[こに]{れ}は
--- data2
old: ある晴れた日に散歩をすると、そこには
new: いつもいる人がいないので、それは

===
--- data1
This library is [free software]{自由なソフト}; you can {not }redistribute it {or/}and[/or] modify
it under the same terms as Pe{a}rl it{ }self.
--- data2
old: |-
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.
new: |-
  This library is 自由なソフト; you can not redistribute it or/and modify
  it under the same terms as Pearl it self.

===
--- data1
This library is [free software]{自由なソフト}; you can {not }redistribute it {or/}and[/or] modify[
]{ }it under the same terms as Pe{a}rl it{ }self.
--- data2
old: |-
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.
new: This library is 自由なソフト; you can not redistribute it or/and modify it under the same terms as Pearl it self.

===
--- data1
[remove
]This library is [free software]{自由なソフト}; you can {not }redistribute it {or/}and[/or] modify
(snip)
it under the same terms as Pe{a}rl it{ }self.{
append}
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
This library is [free software]{自由なソフト}; you can {not }redistribute it {or/}and[/or] modify
it under the same terms as Pe{a}rl it{ }self.
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
This library is [free software]{自由なソフト}; you can {not }redistribute it {or/}and[/or] modify
it under the same terms as Pe{a}rl it{ }self.[
][delete]
--- data2
old: |-
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.
  delete
new: |-
  This library is 自由なソフト; you can not redistribute it or/and modify
  it under the same terms as Pearl it self.
options:
  linebreak: 1

===
--- data1
{This lib}r{ary is 自由なソフト; you can not r}e{distribute it or/and }mo[ve]{dify}
[This library is free software; you can redistribute it and/or modify][
](snip)
it under the same terms as Pe{a}rl it{ }self.{
}{append}
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
{This lib}r{ary is 自由なソフト; you can not r}e{distribute it or/and }mo[ve]{dify}
[This library is free software; you can redistribute it and/or modify][
](snip)
it under the same terms as Pe{a}rl it{ }self.[
][delete]
--- data2
old: |-
  remove
  This library is free software; you can redistribute it and/or modify
  (snip)
  it under the same terms as Perl itself.
  delete
new: |-
  This library is 自由なソフト; you can not redistribute it or/and modify
  (snip)
  it under the same terms as Pearl it self.
options:
  linebreak: 1

===
--- data1
This library is <del>free software</del><ins>自由なソフト</ins>; you can <ins>not </ins>redistribute it <ins>or/</ins>and<del>/or</del> modify
it under the same terms as Pe<ins>a</ins>rl it<ins> </ins>self.
--- data2
old: |-
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.
new: |-
  This library is 自由なソフト; you can not redistribute it or/and modify
  it under the same terms as Pearl it self.
options:
  linebreak: 1
  remove_open: <del>
  remove_close: </del>
  append_open: <ins>
  append_close: </ins>

===
--- data1
1[0]{1}
--- data2
old: 10
new: 11
