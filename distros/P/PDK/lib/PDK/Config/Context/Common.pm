package PDK::Config::Context::Common;

#------------------------------------------------------------------------------
# 设定模块依赖
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use utf8;
use Digest::MD5;
use Encode qw/decode_utf8/;
use PDK::Utils::Date;

#------------------------------------------------------------------------------
# 设定模块方法和属性
#------------------------------------------------------------------------------
has config => (is => 'ro', isa => 'ArrayRef[Str]', required => 1,);

has confContent => (is => 'ro', isa => 'Str', lazy => 1, builder => '_buildConfContent',);

has cursor => (is => 'ro', isa => 'Int', default => 0,);

with 'PDK::Config::Context::Role1';

#------------------------------------------------------------------------------
# 具体实现 content 方法
#------------------------------------------------------------------------------
sub _buildConfContent {
  my $self = shift;
  return join("\n", @{$self->config});
}

#------------------------------------------------------------------------------
# 设定文本行初始标记
#------------------------------------------------------------------------------
sub _buildLineParsedFlags {
  my $self = shift;
  return ([map {0} (1 .. @{$self->config})]);
}

#------------------------------------------------------------------------------
# 跳转行首
#------------------------------------------------------------------------------
sub goToHead {
  my $self = shift;
  $self->{cursor} = 0;
}

#------------------------------------------------------------------------------
# 跳转下一行
#------------------------------------------------------------------------------
sub nextLine {
  my $self = shift;

  # 判定文本行是否已经到底
  if ($self->cursor < scalar(@{$self->config})) {
    my $result = $self->config->[$self->cursor];
    $self->{cursor}++;
    return $result;
  }
  else {
    warn "ERROR: nextLine failed, because cursor on the end\n";
  }
}

#------------------------------------------------------------------------------
# 跳转到文本上一行
#------------------------------------------------------------------------------
sub prevLine {
  my $self = shift;
  if ($self->{cursor} > 0) {
    $self->{cursor}--;
    return 1;
  }
  else {
    warn "ERROR: prevLine failed, because cursor on the head\n";
  }
}

#------------------------------------------------------------------------------
# 过滤出未解析的文本行，并按顺序解析到最近下一行
#------------------------------------------------------------------------------
sub nextUnParsedLine {
  my $self = shift;

  # 跳转到空白行
  while ($self->cursor < scalar(@{$self->config}) and $self->getParseFlag == 1) {
    $self->{cursor}++;
  }

  # 进一步判定是否到了文本行尾
  if ($self->cursor < scalar(@{$self->config})) {
    my $result = decode_utf8 $self->config->[$self->cursor];
    $self->setParseFlag(1);
    $self->{cursor}++;
    return $result;
  }
}

#------------------------------------------------------------------------------
# 设定模块依赖
#------------------------------------------------------------------------------
sub backtrack {
  my $self = shift;
  if ($self->{cursor} > 0) {
    $self->{cursor}--;
    $self->setParseFlag(0);
    return 1;
  }
}

#------------------------------------------------------------------------------
# 忽略之前的解析
#------------------------------------------------------------------------------
sub ignore {
  my $self = shift;
  $self->backtrack and $self->nextLine;
}

#------------------------------------------------------------------------------
# 查询所有的未解析的文本
#------------------------------------------------------------------------------
sub getUnParsedLines {
  my $self = shift;
  my $unParsedLines
    = join('', map { $self->config->[$_] } grep { $self->{lineParsedFlags}->[$_] == 0 } (0 .. scalar(@{$self->config}) - 1));
  return $unParsedLines;
}

#------------------------------------------------------------------------------
# 查询文本解析标志
#------------------------------------------------------------------------------
sub getParseFlag {
  my $self = shift;
  if ($self->cursor >= 0 and $self->cursor < scalar(@{$self->config})) {
    return $self->{lineParsedFlags}->[$self->cursor];
  }
}

#------------------------------------------------------------------------------
# 设定文件解析标记
#------------------------------------------------------------------------------
sub setParseFlag {
  my ($self, $flag) = @_;
  if ($self->cursor >= 0 and $self->cursor < scalar(@{$self->config})) {
    $self->{lineParsedFlags}->[$self->cursor] = $flag // 1;
    return 1;
  }
}

__PACKAGE__->meta->make_immutable;
1;
