BEGIN{ $ENV{STRING_DIFF_PP} = 1; }
use strict;
use utf8;
use Test::Base;

plan tests => 2 * blocks;

use String::Diff qw( diff );

filters { data1 => 'yaml', data2 => 'yaml' };

sub string_diff {
    my $input = shift;
    my $diff = diff($input->{old}, $input->{new}, %{ $input->{options} });
    $diff;
}

run {
    my $block = shift;

    my $diff = diff($block->data2->{old}, $block->data2->{new}, %{ $block->data2->{options} });
    my @diff = diff($block->data2->{old}, $block->data2->{new}, %{ $block->data2->{options} });

    is_deeply $block->data1, $diff;
    is_deeply $block->data1, \@diff;
};


__END__

===
--- data1
- perl
- pe{a}rl
--- data2
old: perl
new: pearl

===
--- data1
- 'th[i]s [is ]a[ pen]'
- "th{at'}s a{ll}"
--- data2
old: this is a pen
new: that's all

===
--- data1
- '[S]oo[z]y'
- '{B}oo{f}y'
--- data2
old: Soozy
new: Boofy

===
--- data1
- '[あ]る[晴れた日に散歩をすると]、そ[こに]は'
- '{いつもい}る{人がいないので}、そ{れ}は'
--- data2
old: ある晴れた日に散歩をすると、そこには
new: いつもいる人がいないので、それは

===
--- data1
- |-
  This library is [free software]; you can redistribute it and[/or] modify
  it under the same terms as Perl itself.
- |-
  This library is {自由なソフト}; you can {not }redistribute it {or/}and modify
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
- |-
  This library is [free software]; you can redistribute it and[/or] modify[
  ]it under the same terms as Perl itself.
- This library is {自由なソフト}; you can {not }redistribute it {or/}and modify{ }it under the same terms as Pe{a}rl it{ }self.
--- data2
old: |-
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself.
new: This library is 自由なソフト; you can not redistribute it or/and modify it under the same terms as Pearl it self.

===
--- data1
- |-
  [remove
  ]This library is [free software]; you can redistribute it and[/or] modify
  (snip)
  it under the same terms as Perl itself.
- |-
  This library is {自由なソフト}; you can {not }redistribute it {or/}and modify
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
- |-
  This library is [free software]; you can redistribute it and[/or] modify
  it under the same terms as Perl itself.
- |-
  This library is {自由なソフト}; you can {not }redistribute it {or/}and modify
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
- |-
  remo[ve]
  [This library is free software; you can redistribute it and/or modify][
  ](snip)
  it under the same terms as Perl itself.
- |-
  {This lib}r{ary is 自由なソフト; you can not r}e{distribute it or/and }mo{dify}
  (snip)
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
- |-
  This library is <del>free software</del>; you can redistribute it and<del>/or</del> modify
  it under the same terms as Perl itself.
- |-
  This library is <ins>自由なソフト</ins>; you can <ins>not </ins>redistribute it <ins>or/</ins>and modify
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
- 1[0]
- 1{1}
--- data2
old: 10
new: 11

