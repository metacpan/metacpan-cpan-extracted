#!/usr/bin/env perl

use v5.30;
use strict;
use warnings;
use Test::More;

use PDK::Content::Reader;


my $text;

subtest 'PDK::Content::Reader 对象创建' => sub {
  $text = eval { PDK::Content::Reader->new(id => 1, name => 'freedom', type => 'network', config => [1, 2, 3, 5]) };
  is($@, '', '对象创建过程中没有错误');
  isa_ok($text, 'PDK::Content::Reader', '已创建对象');
  is($text->confContent, "1\n2\n3\n5", '内容正确');
};

subtest 'cursor 方法' => sub {
  $text = PDK::Content::Reader->new(id => 1, name => 'freedom', type => 'network', config => [1, 2, 3, 5]);
  $text->nextLine for 1 .. 2;
  is($text->cursor, 2, '光标在正确位置');
};

subtest 'goToHead 方法' => sub {
  $text = PDK::Content::Reader->new(id => 1, name => 'freedom', type => 'network', config => [1, 2, 3, 5]);
  $text->nextLine for 1 .. 2;
  my $last_value = $text->nextLine;
  $text->goToHead;
  is($last_value,     3, 'goToHead 之前的值正确');
  is($text->nextLine, 1, 'goToHead 之后的值正确');
};

subtest 'nextLine 方法' => sub {
  $text = PDK::Content::Reader->new(id => 1, name => 'freedom', type => 'network', config => [1, 2, 3, 5]);
  is($text->nextLine, 1, '第一行正确');
};

subtest 'prevLine 方法' => sub {
  $text = PDK::Content::Reader->new(id => 1, name => 'freedom', type => 'network', config => [1, 2, 3, 5]);
  $text->nextLine for 1 .. 2;
  $text->prevLine;
  my $value = $text->nextLine;
  is($value,        2, 'prevLine 之后的值正确');
  is($text->cursor, 2, '光标位置正确');
};

subtest 'getParseFlag 和 setParseFlag 方法' => sub {
  $text = PDK::Content::Reader->new(id => 1, name => 'freedom', type => 'network', config => [1, 2, 3, 5]);
  $text->nextLine;
  my $initial_flag = $text->getParseFlag;
  $text->setParseFlag(1);
  my $new_flag = $text->getParseFlag;
  $text->nextLine for 1 .. 3;
  is($initial_flag,       0,     '初始解析标志为 0');
  is($new_flag,           1,     '解析标志设置为 1');
  is($text->getParseFlag, undef, '结束时解析标志未定义');
};

subtest 'nextUnParsedLine 方法' => sub {
  $text = PDK::Content::Reader->new(id => 1, name => 'freedom', type => 'network', config => [1, 2, 3, 5]);
  $text->nextUnParsedLine;
  my $second_unparsed = $text->nextUnParsedLine;
  $text->nextLine;
  $text->nextUnParsedLine;
  $text->goToHead;
  is($second_unparsed,        2, '第二个未解析行正确');
  is($text->nextUnParsedLine, 3, 'goToHead 后的未解析行正确');
};

subtest 'backtrack 方法' => sub {
  $text = PDK::Content::Reader->new(id => 1, name => 'freedom', type => 'network', config => [1, 2, 3, 5]);
  $text->nextUnParsedLine for 1 .. 2;
  $text->backtrack;
  is($text->nextUnParsedLine, 2, 'backtrack 后的行正确');
};

subtest 'ignore 方法' => sub {
  $text = PDK::Content::Reader->new(id => 1, name => 'freedom', type => 'network', config => [1, 2, 3, 5]);
  $text->nextUnParsedLine for 1 .. 2;
  $text->ignore;
  my $next_unparsed = $text->nextUnParsedLine;
  $text->goToHead;
  is($text->nextUnParsedLine, 2, 'ignore 后的第一个未解析行正确');
  is($next_unparsed,          3, 'ignore 后的下一个未解析行正确');
};

subtest 'getUnParsedLines 方法' => sub {
  $text = PDK::Content::Reader->new(id => 1, name => 'freedom', type => 'network', config => [1, 2, 3, 5]);
  $text->nextUnParsedLine for 1 .. 2;
  $text->ignore;
  $text->nextUnParsedLine;
  is($text->getUnParsedLines, '25', '未解析行正确');
};

done_testing();
