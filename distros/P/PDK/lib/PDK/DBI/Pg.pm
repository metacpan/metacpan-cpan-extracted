package PDK::DBI::Pg;

# ABSTRACT: PDK::DBI::Pg;
#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 继承 PDK::DBI::Role 方法属性
#------------------------------------------------------------------------------
with 'PDK::DBI::Role';

#------------------------------------------------------------------------------
# 对象初始化属性检查
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;

  my %param = (@_ > 0 and ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
  if (not defined $param{dsn} and defined $param{host} and defined $param{port} and defined $param{dbname}) {
    $param{dsn} = qq{dbi:Pg:dbname=$param{dbname};host=$param{host};port=$param{port}};
  }
  return $class->$orig(%param);
};

__PACKAGE__->meta->make_immutable;
1;
