package PDK::Firewall::Element::Schedule::Paloalto;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Time::Local;
use POSIX;

#------------------------------------------------------------------------------
# 加载 PDK::Firewall::Element::Schedule::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Schedule::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Schedule::PaloAlto 方法属性
#------------------------------------------------------------------------------
has startDate => (is => 'ro', isa => 'Str', required => 1,);

has endDate => (is => 'ro', isa => 'Str', required => 1,);

has '+schType' => (required => 0,);

=head3 schedule example

set schedulers scheduler S_20130924 start-date 2013-09-24.00:00 stop-date 2013-10-23.23:59

=cut

#------------------------------------------------------------------------------
# 重写 PDK::Firewall::Element::Role => _buildRange 方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->schName);
}

#------------------------------------------------------------------------------
# 检查是否基于时间的策略
#------------------------------------------------------------------------------
sub isExpired {
  my ($self, $time) = @_;
  if (defined $self->isExpired && not defined $time) {
    return $self->isExpired;
  }
  $self->isExpired = $self->isEnable($time) ? 0 : 1;
  return $self->isExpired;
}

#------------------------------------------------------------------------------
# 检查策略是否启用
#------------------------------------------------------------------------------
sub isEnable {
  my ($self, $time) = @_;
  if (defined $self->isEnable and not defined $time) {
    return $self->isEnable;
  }
  $time = $time // time();
  if (not defined $self->timeRange) {
    $self->createTimeRange;
  }
  $self->isEnable = 0;
  if (not defined $self->timeRange) {

    # createTimeRange 失败
  }
  elsif ($time >= $self->timeRange->min and $time <= $self->timeRange->max) {
    $self->isEnable = 1;
  }
  return $self->isEnable;
}

#------------------------------------------------------------------------------
# 创建时间区间
#------------------------------------------------------------------------------
sub createTimeRange {
  my $self = shift;
  if (defined $self->startDate && defined $self->endDate) {
    $self->timeRange->min = $self->getSecondFromEpoch($self->startDate);
    $self->timeRange->max = $self->getSecondFromEpoch($self->endDate);
  }
}

#------------------------------------------------------------------------------
# 获取时间戳 - 基于秒
#------------------------------------------------------------------------------
sub getSecondFromEpoch {
  my ($self, $string) = @_;

  # 2013-09-24.00:00
  # 09-24.00:00
  my ($year, $mon, $mday, $hour, $min);
  if ($string =~ /((?<year>\d{4})-)?((?<mon>\d\d)-(?<day>\d\d)\.)?(?<hour>\d+):(?<min>\d+)/) {
    ($year, $mon, $mday, $hour, $min) = ($+{year}, $+{mon}, $+{day}, $+{hour}, $+{min});
    my $curTime = strftime "%Y-%m-%d", localtime;
    my ($curYear, $curMon, $curDay) = split('-', $curTime);
    $year = $curYear if not defined $year;
    $mon  = $curMon  if not defined $mon;
    $mday = $curDay  if not defined $mday;
  }
  my $second = timelocal(0, $min, $hour, $mday, $mon - 1, $year - 1900);
  return $second;
}

#------------------------------------------------------------------------------
# 获取策略时效时间
#-------------------------------------------------------------------------
sub getEndDateStr {
  my $self = shift;
  my ($year, $mon, $mday, $hour, $min);
  if ($self->endDate =~ /((?<year>\d{4})-)?((?<mon>\d\d)-(?<day>\d\d)\.)?(?<hour>\d+):(?<min>\d+)/) {
    ($year, $mon, $mday, $hour, $min) = ($+{year}, $+{mon}, $+{day}, $+{hour}, $+{min});
    my $curTime = strftime "%Y-%m-%d", localtime;
    my ($curYear, $curMon, $curDay) = split('-', $curTime);
    $year = $curYear if not defined $year;
    $mon  = $curMon  if not defined $mon;
    $mday = $curDay  if not defined $mday;
  }
  return $year . "-" . $mon . "-" . $mday . " " . $hour . ":" . $min;
}

__PACKAGE__->meta->make_immutable;
1;
