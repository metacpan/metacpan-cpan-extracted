package Netstack::Config::Content::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use 5.016;
use Moose::Role;
use autodie;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 定义 Content 通用属性
#------------------------------------------------------------------------------
has hostId => (
  is       => 'ro',
  isa      => 'Int',
  required => 1,
);

has hostname => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has vendor => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has confSign => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has timestamp => (
  is       => 'ro',
  isa      => 'Str',
  required => 1,
);

has lineParsedFlags => (
  is      => 'ro',
  isa     => 'ArrayRef[Int]',
  builder => '_buildLineParsedFlags',
);

#------------------------------------------------------------------------------
# 继承 Role 对象必须实现的属性
#------------------------------------------------------------------------------
requires 'config';
requires 'confContent';
requires 'cursor';

#------------------------------------------------------------------------------
# 继承 Role 对象必须实现的方法 | 解析配置的策略或动作
#------------------------------------------------------------------------------
requires 'goToHead';
requires 'nextLine';
requires 'prevLine';
requires 'nextUnParsedLine';
requires 'backtrack';
requires 'ignore';
requires 'getUnParsedLines';
requires '_buildLineParsedFlags';

1;
