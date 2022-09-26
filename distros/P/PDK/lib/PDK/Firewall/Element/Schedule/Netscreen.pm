package PDK::Firewall::Element::Schedule::Netscreen;

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
# PDK::Firewall::Element::Schedule::Netscreen 通用属性
#------------------------------------------------------------------------------
has weekday => (is => 'ro', isa => 'Undef|Str', default => undef,);

has startTime1 => (is => 'ro', isa => 'Undef|Str', default => undef,);

has endTime1 => (is => 'ro', isa => 'Undef|Str', default => undef,);

has startTime2 => (is => 'ro', isa => 'Undef|Str', default => undef,);

has endTime2 => (is => 'ro', isa => 'Undef|Str', default => undef,);

has description => (is => 'ro', isa => 'Undef|Str', default => undef,);

=example
set scheduler "S_20120331" once start 10/10/2011 0:0 stop 3/31/2012 23:59
set scheduler "S20110630" recurrent friday start 10:00 stop 12:00 start 14:00 stop 16:00 comment "test"
=cut

#------------------------------------------------------------------------------
# 创建时间区间
#------------------------------------------------------------------------------
sub createTimeRange {
  my $self = shift;
  if ($self->schType eq 'once') {
    if (defined $self->startDate and defined $self->endDate) {
      $self->{timeRange}{min} = $self->getSecondFromEpoch($self->startDate);
      $self->{timeRange}{max} = $self->getSecondFromEpoch($self->endDate);
    }
  }
  elsif ($self->schType eq 'recurrent') {
    if (defined $self->weekday and defined $self->startTime1 and defined $self->endTime1) {
      my @times = ({min => $self->startTime1, max => $self->endTime1});
      if (defined $self->startTime2 and defined $self->endTime2) {
        push @times, {min => $self->startTime2, max => $self->endTime2};
      }
      for (@times) {
        my ($min, $max) = ($_->{min}, $_->{max});
        $min =~ s/://;
        $max =~ s/://;
        push @{$self->{timeRange}{$self->weekday}}, {min => $min + 0, max => $max + 0};
      }
    }
  }
}

__PACKAGE__->meta->make_immutable;
1;
