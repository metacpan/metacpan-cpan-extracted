package PDK::Utils::Date;

use utf8;
use v5.30;
use Moose;
use namespace::autoclean;

sub getFormatedDate {
  my ($self, @param) = @_;

  my ($format, $time);

  if (defined $param[0] && $param[0] =~ /^\d+$/) {
    ($time, $format) = @param;
  }
  else {
    ($format, $time) = @param;
  }

  $format //= 'yyyy-mm-dd hh:mi:ss';
  $time   //= time();

  my ($sec, $min, $hour, $mday, $mon, $year) = localtime($time);

  my %timeMap = (yyyy => $year + 1900, mm => $mon + 1, dd => $mday, hh => $hour, mi => $min, ss => $sec, );

  my %formatMap = (yyyy => '%04d', mm => '%02d', dd => '%02d', hh => '%02d', mi => '%02d', ss => '%02d', );

  my $regex = '(' . join('|', keys %timeMap) . ')';
  my @times = map { $timeMap{$_} } ($format =~ /$regex/g);

  if (@times == 0) {
    confess("错误: 格式字符串 [$format] 中没有有效的时间字符");
  }

  $format =~ s/$regex/$formatMap{$1}/g;

  my $formatedTime = sprintf($format, @times);
  return $formatedTime;
}

__PACKAGE__->meta->make_immutable;

1;
