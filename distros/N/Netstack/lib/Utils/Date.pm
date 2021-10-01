package Netstack::Utils::Date;

#------------------------------------------------------------------------------
# 加载扩展插件
#------------------------------------------------------------------------------
use 5.016;
use Moose;
use namespace::autoclean;

sub getLocalDate {
  my ( $self, @param ) = @_;
  # 初始化变量
  my ( $format, $time );

  if ( defined $param[0] and $param[0] =~ /^\d+$/ ) {
    ( $time, $format ) = @param;
  }
  else {
    ( $format, $time ) = @param;
  }
  # 缺省时间格式
  if ( not defined $format ) {
    $format = 'yyyy-mm-dd hh:mi:ss';
  }
  # 缺省为本地时间
  if ( not defined $time ) {
    $time = time();
  }
  # 时间对象切片
  my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime($time);
  # 定义本地时间数据字典
  my %timeMap = (
    yyyy => $year + 1900,
    mm   => $mon + 1,
    dd   => $mday,
    hh   => $hour,
    mi   => $min,
    ss   => $sec,
  );
  my %formatMap = (
    yyyy => '%04d',
    mm   => '%02d',
    dd   => '%02d',
    hh   => '%02d',
    mi   => '%02d',
    ss   => '%02d',
  );
  my $regex = '(' . join( '|', keys %timeMap ) . ')';
  my @times = map { $timeMap{$_} } ( $format =~ /$regex/g );
  if ( scalar(@times) == 0 ) {
    confess "ERROR: format string [$format]  has none valid characters\n";
  }
  $format =~ s/$regex/$formatMap{$1}/g;
  my $localTime = sprintf( "$format", @times );

  # 返回计算结果
  return $localTime;
}

__PACKAGE__->meta->make_immutable;
1;
