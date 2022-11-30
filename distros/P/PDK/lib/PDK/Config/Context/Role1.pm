package PDK::Config::Context::Role1;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;
our $VERSION = '0.011';

#------------------------------------------------------------------------------
# 定义 PDK::Config::Context::Role 通用属性
#------------------------------------------------------------------------------
has lineParsedFlags => (is => 'ro', isa => 'ArrayRef[Int]', builder => '_buildLineParsedFlags',);

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
