package PDK::Content::Reader;

use utf8;
use v5.30;
use Moose;
use Digest::MD5;
use DateTime;
use Carp qw'croak';
use namespace::autoclean;
use Data::Dumper;

has config => (is => 'ro', isa => 'ArrayRef[Str]', required => 1, );

has confContent => (is => 'ro', isa => 'Str', lazy => 1, builder => '_buildConfContent', );

has cursor => (is => 'ro', isa => 'Int', default => 0, );

with 'PDK::Content::Role';
with 'PDK::Content::Dumper';

has '+sign' => (required => 0, lazy => 1, builder => '_buildSign', );

has '+timestamp' => (required => 0, builder => '_buildTimestamp', );

sub _buildSign {
  my $self = shift;

  return Digest::MD5::md5_hex(join("\n", @{$self->config}));
}

sub _buildConfContent {
  my $self = shift;

  return join("\n", @{$self->config});
}

sub _buildTimestamp {
  shift;

  return DateTime->now->strftime('%Y-%m-%d %H:%M:%S');
}

sub _buildLineParsedFlags {
  my $self = shift;

  return [map {0} (1 .. @{$self->config})];
}

sub goToHead {
  my $self = shift;

  $self->{cursor} = 0;
  $self->dump("[goToHead] 游标已移至首行：$self->{config}->[$self->{cursor}]");
}

sub nextLine {
  my $self = shift;
  my $result;

  if ($self->cursor < scalar(@{$self->config})) {

    $result = $self->config->[$self->cursor];
    $self->dump("[nextLine] 获取当前游标指向的下一行内容：$result");

    $self->{cursor}++;
  }

  return $result;
}

sub prevLine {
  my $self = shift;

  if ($self->{cursor} > 0) {
    $self->dump("[prevLine] 获取当前游标指向的上一行：$self->{config}->[$self->{cursor}]");
    $self->{cursor}--;
    return 1;
  }
  else {
    $self->dump("[prevLine] 获取当前游标指向的上一行异常：当前游标已经在第一行 $self->{cursor}");
    warn("游标已经在头部：$self->{cursor}");
    return undef;
  }
}

sub nextUnParsedLine {
  my $self = shift;
  my $result;

  while ($self->cursor < scalar(@{$self->config}) && $self->getParseFlag == 1) {
    $self->{cursor}++;
  }

  if ($self->cursor < scalar(@{$self->config})) {
    $result = $self->config->[$self->cursor];

    while (!defined $result || $result =~ /^\s*$/m) {
      $self->setParseFlag(1);
      $self->{cursor}++;

      while ($self->cursor < scalar(@{$self->config}) && $self->getParseFlag == 1) {
        $self->{cursor}++;
      }

      if ($self->cursor < scalar(@{$self->config})) {
        $result = $self->config->[$self->cursor];
      }
      else {
        return undef;
      }
    }

    $self->setParseFlag(1);
    $self->{cursor}++;
  }

  chomp $result;


  $self->dump("[nextUnParsedLine] 获取到下一个未解析的行：$result");
  return $result;
}

sub moveBack {
  my $self = shift;

  if ($self->{cursor} > 0) {
    $self->{cursor}--;
    $self->setParseFlag(0);
    $self->dump("[moveBack] 如果游标不在头部，则将游标向前移动并重置解析标志：" . $self->config->[$self->{cursor}]);
    return 1;
  }
  else {
    $self->dump("[moveBack] 将游标向前移动一位异常：当前游标已在行首 $self->{cursor}");
    warn("游标已经在头部：$self->{cursor}");
    return undef;
  }
}

sub ignore {
  my $self = shift;
  $self->dump("[ignore] 忽略当前行解析状态：" . $self->config->[$self->{cursor}]);

  return $self->moveBack ? $self->nextLine : undef;
}

sub getUnParsedLines {
  my $self = shift;

  my $unParsedLines = join('',
    map { $self->config->[$_] } grep { $self->{lineParsedFlags}->[$_] == 0 } (0 .. scalar(@{$self->config}) - 1) );

  $self->dump("[getUnParsedLines] 获取所有未解析的行并打印：" . Dumper $unParsedLines);
  return $unParsedLines;
}

sub getParseFlag {
  my $self = shift;

  if ($self->cursor >= 0 && $self->cursor < scalar(@{$self->config})) {
    return $self->{lineParsedFlags}->[$self->cursor];
  }

  return;
}

sub setParseFlag {
  my ($self, $flag) = @_;

  if ($self->cursor >= 0 && $self->cursor < scalar(@{$self->config})) {
    $self->{lineParsedFlags}->[$self->cursor] = $flag // 1;

    return 1;
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;
