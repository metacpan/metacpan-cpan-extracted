package PDK::Firewall::Element::Schedule::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose::Role;
use Time::Local;
use POSIX qw/strftime/;

#------------------------------------------------------------------------------
# 加载 PDK::Firewall::Element::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Role';

#------------------------------------------------------------------------------
# 引用该模块的子类必须实现的方法
#------------------------------------------------------------------------------
# requires 'isExpired';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Schedule::Role 通用属性
#------------------------------------------------------------------------------
has schName => (is => 'ro', isa => 'Str', required => 1,);

has schType => (is => 'ro', isa => 'Str', required => 1, default => 'absolute');

has startDate => (is => 'ro', isa => 'Undef|Str', default => undef,);

has endDate => (is => 'ro', isa => 'Undef|Str', default => undef,);

has startTime => (is => 'ro', isa => 'Undef|Str', default => undef,);

has endTime => (is => 'ro', isa => 'Undef|Str', default => undef,);

has day => (is => 'ro', isa => 'Undef|Str', default => undef,);

#------------------------------------------------------------------------------
# 定义模块通用签名方法
#------------------------------------------------------------------------------
sub _buildSign {
  my $self = shift;
  return $self->createSign($self->schName);
}

#------------------------------------------------------------------------------
# 创建时间区间
#------------------------------------------------------------------------------
sub createTimeRange {
  my $self = shift;
  if ($self->schType eq 'absolute') {
    if (defined $self->endDate) {
      $self->{timeRange}{min} = defined $self->startDate ? $self->getSecondFromEpoch($self->startDate) : 0;
      $self->{timeRange}{max} = $self->getSecondFromEpoch($self->endDate);
    }
  }
  elsif ($self->schType eq 'recurring') {
    if (defined $self->startTime and defined $self->endTime) {
      my $min   = getSecondFromEpoch($self->startTime);
      my $max   = getSecondFromEpoch($self->endTime);
      my $range = {min => $min + 0, max => $max + 0};

      if (defined $self->day) {
        my @weekDays;
        if ($self->day eq 'daily') {
          @weekDays = ("sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday");
        }
        elsif ($self->day eq 'weekdays') {
          @weekDays = ("monday", "tuesday", "wednesday", "thursday", "friday");
        }
        elsif ($self->day eq 'weekend') {
          @weekDays = ("sunday", "saturday");
        }
        else {
          @weekDays = split(/\s/, $self->day);
        }
        for my $weekDay (@weekDays) {
          $self->{timeRange}{$weekDay} = $range;
        }
      }
      else {
        $self->{timeRange}{min} = $min + 0;
        $self->{timeRange}{max} = $max + 0;
      }
    }
  }
}

#------------------------------------------------------------------------------
# 检查基于时间的策略是否超时
#------------------------------------------------------------------------------
sub isExpired {
  my ($self, $time) = @_;
  if (defined $self->{isExpired} and not defined $time) {
    return $self->{isExpired};
  }
  if ($self->schType eq 'absolute') {
    $self->{isExpired} = $self->isEnable($time) ? 0 : 1;
  }
  else {
    $self->{isExpired} = 0;
  }
  return $self->{isExpired};
}

#------------------------------------------------------------------------------
# 检查策略是否启用
#------------------------------------------------------------------------------
sub isEnable {
  my ($self, $time) = @_;
  if (defined $self->{isEnable} and not defined $time) {
    return $self->{isEnable};
  }
  $time ||= time();
  if (not defined $self->{timeRange}) {
    $self->createTimeRange;
  }
  $self->{isEnable} = 0;
  if (not defined $self->{timeRange}) {

    # createTimeRange 失败
    $self->{isEnable} = 1;
  }
  elsif ($self->schType eq 'absolute') {
    if ($time >= $self->{timeRange}{min} and $time <= $self->{timeRange}{max}) {
      $self->{isEnable} = 1;
    }
  }
  elsif ($self->schType eq 'recurring') {

    # 获取当前时间
    my ($wday, $hour, $min) = (localtime($time))[6, 2, 1];
    my $weekDay    = (qw/sunday monday tuesday wednesday thursday friday saturday/)[$wday];
    my $hourAndMin = $hour . sprintf("%02d", $min) + 0;

    # 检查是否周期性策略
    if (exists $self->{timeRange}{$weekDay}) {
      for (@{$self->{timeRange}{$weekDay}}) {
        my ($sMin, $sMax) = ($_->{min}, $_->{max});
        if ($hourAndMin >= $sMin and $hourAndMin <= $sMax) {
          $self->{isEnable} = 1;
          last;
        }
      }
    }
  }
  return $self->{isEnable};
}

#------------------------------------------------------------------------------
# 获取时间戳 - 基于秒
# 2018-04-05 23:59:59
#------------------------------------------------------------------------------
sub getSecondFromEpoch {
  my ($self, $string) = @_;
  my ($year, $mon, $mday, $hour, $min) = split(/[\s+:-]/, $string);
  my $second = timelocal(0, $min, $hour, $mday, $mon - 1, $year - 1900);

  # 兜底的本地时间
  my $curTime = strftime "%Y-%m-%d", localtime;
  my ($curYear, $curMon, $curDay) = split('-', $curTime);
  $year ||= $curYear;
  $mon  ||= $curMon;
  $mday ||= $curDay;
  return $second;
}

#------------------------------------------------------------------------------
# 获取策略时效时间
#------------------------------------------------------------------------------
sub getEndDateStr {
  my $self = shift;
  my ($year, $mon, $mday, $hour, $min) = split(/[\s+:-]/, $self->endDate);

  # 设置缺省的 年月日
  my $curTime = strftime "%Y-%m-%d", localtime;
  my ($curYear, $curMon, $curDay) = split('-', $curTime);
  $year ||= $curYear;
  $mon  ||= $curMon;
  $mday ||= $curDay;

  return $year . "-" . $mon . "-" . $mday . " " . $hour . ":" . $min;
}

1;
