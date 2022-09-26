#!/usr/bin/perlnew

use 5.016;
use warnings;
use Test::Simple tests => 11;

# 设定加载模块路径
use lib '/home/careline/device/lib';
use PDK::Config::Context::Common;
use Digest::MD5;

# 设定全局变量
my $text;

ok(
  do {
    eval { $text = PDK::Config::Context::Common->new(config => [1, 2, 3, 5]); };
    warn $@ if !!$@;
    $text->isa('PDK::Config::Context::Common') and $text->confContent eq '1235';
  },
  ' 生成 PDK::Config::Context::Common 对象'
);

ok(
  do {
    eval { $text = PDK::Config::Context::Common->new(config => [1, 2, 3, 5]); };
    warn $@ if !!$@;
    $text->nextLine;
    $text->nextLine;
    $text->cursor == 2;
  },
  ' cursor 方法'
);

ok(
  do {
    eval { $text = PDK::Config::Context::Common->new(config => [1, 2, 3, 5]); };
    warn $@ if !!$@;
    $text->nextLine;
    $text->nextLine;
    my $lala = $text->nextLine;
    $text->goToHead;
    $lala == 3 and $text->nextLine == 1;
  },
  ' goToHead 方法'
);

ok(
  do {
    eval { $text = PDK::Config::Context::Common->new(config => [1, 2, 3, 5]); };
    warn $@ if !!$@;
    $text->nextLine == 1;
  },
  ' nextLine 方法'
);

ok(
  do {
    eval { $text = PDK::Config::Context::Common->new(config => [1, 2, 3, 5]); };
    warn $@ if !!$@;
    $text->nextLine;
    $text->nextLine;
    $text->prevLine;
    my $lala = $text->nextLine;
    $lala == 2 and $text->cursor == 2;
  },
  ' prevLine 方法'
);

ok(
  do {
    eval { $text = PDK::Config::Context::Common->new(config => [1, 2, 3, 5]); };
    warn $@ if !!$@;
    $text->nextLine;
    my $lala = $text->getParseFlag;
    $text->nextLine;
    $text->nextLine;
    $text->nextLine;
    $lala == 0 and not $text->getParseFlag;
  },
  ' getParseFlag 方法'
);

ok(
  do {
    eval { $text = PDK::Config::Context::Common->new(config => [1, 2, 3, 5]); };
    warn $@ if !!$@;
    $text->nextLine;
    my $lala = $text->getParseFlag;
    $text->setParseFlag(1);
    my $lele = $text->getParseFlag;
    $text->nextLine;
    $text->nextLine;
    $text->nextLine;
    $lala == 0 and $lele == 1 and not $text->setParseFlag(1);
  },
  ' setParseFlag 方法'
);

ok(
  do {
    eval { $text = PDK::Config::Context::Common->new(config => [1, 2, 3, 5]); };
    warn $@ if !!$@;
    $text->nextUnParsedLine;
    my $lala = $text->nextUnParsedLine;
    $text->nextLine;
    $text->nextUnParsedLine;
    $text->goToHead;
    $lala == 2 and $text->nextUnParsedLine == 3;
  },
  ' nextUnParsedLine 方法'
);

ok(
  do {
    eval { $text = PDK::Config::Context::Common->new(config => [1, 2, 3, 5]); };
    warn $@ if !!$@;
    $text->nextUnParsedLine;
    $text->nextUnParsedLine;
    $text->backtrack;
    $text->nextUnParsedLine == 2;
  },
  ' backtrack 方法'
);

ok(
  do {
    eval { $text = PDK::Config::Context::Common->new(config => [1, 2, 3, 5]); };
    warn $@ if !!$@;
    $text->nextUnParsedLine;
    $text->nextUnParsedLine;
    $text->ignore;
    my $lala = $text->nextUnParsedLine;
    $text->goToHead;
    $text->nextUnParsedLine == 2 and $lala == 3;
  },
  ' ignore 方法'
);

ok(
  do {
    eval { $text = PDK::Config::Context::Common->new(config => [1, 2, 3, 5]); };
    warn $@ if !!$@;
    $text->nextUnParsedLine;
    $text->nextUnParsedLine;
    $text->ignore;
    $text->nextUnParsedLine;
    $text->getUnParsedLines eq '25';
  },
  ' getUnParsedLines 方法'
);
