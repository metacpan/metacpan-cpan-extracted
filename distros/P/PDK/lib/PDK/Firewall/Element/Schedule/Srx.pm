package PDK::Firewall::Element::Schedule::Srx;

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
# PDK::Firewall::Element::Schedule::Srx 通用属性
#------------------------------------------------------------------------------
has '+schType' => (required => 0,);

=example
set schedulers scheduler S_20130924 start-date 2013-09-24.00:00 stop-date 2013-10-23.23:59
=cut

#------------------------------------------------------------------------------
# 创建时间区间
#------------------------------------------------------------------------------
sub createTimeRange {
  my $self = shift;
  if (defined $self->startDate and defined $self->endDate) {
    $self->{timeRange}{min} = $self->getSecondFromEpoch($self->startDate);
    $self->{timeRange}{max} = $self->getSecondFromEpoch($self->endDate);
  }
}

#------------------------------------------------------------------------------
# 获取时间戳 - 基于秒
#------------------------------------------------------------------------------
sub getSecondFromEpoch {
  my ($self, $string) = @_;

  # 2013-09-24.00:00 09-24.00:00
  my ($year, $mon, $mday, $hour, $min);
  if ($string =~ /((?<year>\d{4})-)?((?<mon>\d\d)-(?<day>\d\d)\.)?(?<hour>\d+):(?<min>\d+)/) {
    ($year, $mon, $mday, $hour, $min) = ($+{year}, $+{mon}, $+{day}, $+{hour}, $+{min});
    my $curTime = strftime "%Y-%m-%d", localtime;
    my ($curYear, $curMon, $curDay) = split('-', $curTime);
    $year //= $curYear;
    $mon  //= $curMon;
    $mday //= $curDay;
  }
  my $second = timelocal(0, $min, $hour, $mday, $mon - 1, $year - 1900);
  return $second;
}

__PACKAGE__->meta->make_immutable;
1;
