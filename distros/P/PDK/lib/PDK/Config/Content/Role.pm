package PDK::Config::Content::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moo::Role;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 定义 PDK::Config::Content::Role 通用属性
#------------------------------------------------------------------------------
has id => (is => 'ro', isa => 'Int', required => 1,);

has name => (is => 'ro', isa => 'Str', required => 1,);

has vendor => (is => 'ro', isa => 'Str', required => 1,);

has confSign => (is => 'ro', isa => 'Str', required => 1,);

has timestamp => (is => 'ro', isa => 'Str', required => 1,);

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
