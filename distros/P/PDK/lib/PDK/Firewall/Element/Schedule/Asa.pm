package PDK::Firewall::Element::Schedule::Asa;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use Time::Local;

#------------------------------------------------------------------------------
# 加载 PDK::Firewall::Element::Schedule::Role 角色
#------------------------------------------------------------------------------
with 'PDK::Firewall::Element::Schedule::Role';

#------------------------------------------------------------------------------
# PDK::Firewall::Element::Schedule::Asa 通用属性
#------------------------------------------------------------------------------
has periodic => (is => 'ro', isa => 'Undef|Str', default => undef,);

#------------------------------------------------------------------------------
# 获取时间戳 - 基于秒
#------------------------------------------------------------------------------
sub getSecondFromEpoch {
  my ($self, $string) = @_;

  # 本地映射字典
  my %MON = (
    January   => 1,
    February  => 2,
    March     => 3,
    April     => 4,
    May       => 5,
    June      => 6,
    July      => 7,
    August    => 8,
    September => 9,
    October   => 10,
    November  => 11,
    December  => 12,
  );
  my ($hour, $min, $mday, $mon, $year) = split('[ :]', $string);
  $mon = $MON{$mon};
  my $second = timelocal(0, $min, $hour, $mday, $mon - 1, $year - 1900);
  return $second;
}

__PACKAGE__->meta->make_immutable;
1;

=example
time-range S_20091130
 absolute start 00:00 01 November 2009 end 23:59 30 November 2009
time-range S20090926
 absolute end 23:59 26 September 2009
time-range S_20091131
 periodic daily 11:00 to 14:00
time-range S_20091132
 periodic Monday Thursday 11:30 to 14:00
time-range S_20091133
 periodic weekdays 11:00 to 14:00
time-range S_20091134
 periodic weekend 11:00 to 14:00

trange mode commands/options:
  Friday     Friday
  Monday     Monday
  Saturday   Saturday
  Sunday     Sunday
  Thursday   Thursday
  Tuesday    Tuesday
  Wednesday  Wednesday
  daily      Every day of the week
  weekdays   Monday thru Friday
  weekend    Saturday and Sunday
=cut

