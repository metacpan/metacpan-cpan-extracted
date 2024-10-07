package PDK::Content::Reader;

use v5.30;
use Moose;
use Digest::MD5 qw(md5_hex);
use DateTime;
use Carp qw(confess);
use namespace::autoclean;

has config => (is => 'ro', isa => 'ArrayRef[Str]', required => 1,);

has confContent => (is => 'ro', isa => 'Str', lazy => 1, builder => '_buildConfContent',);

has cursor => (is => 'ro', isa => 'Int', default => 0, writer => '_set_cursor',);

with 'PDK::Content::Role';

has '+sign' => (required => 0, lazy => 1, builder => '_buildSign',);

has '+timestamp' => (required => 0, builder => '_buildTimestamp',);

has '_lineParsedFlags' => (is => 'ro', isa => 'ArrayRef[Bool]', lazy => 1, builder => '_buildLineParsedFlags',);

sub _buildSign {
  my $self = shift;
  return md5_hex(join("\n", @{$self->config}));
}

sub _buildConfContent {
  my $self = shift;
  return join("\n", @{$self->config});
}

sub _buildTimestamp {
  return DateTime->now->strftime('%Y-%m-%d %H:%M:%S');
}

sub _buildLineParsedFlags {
  my $self = shift;
  return [map {0} @{$self->config}];
}

sub goToHead {
  my $self = shift;
  $self->_set_cursor(0);
}

sub nextLine {
  my $self = shift;

  if ($self->cursor < @{$self->config}) {
    my $result = $self->config->[$self->cursor];
    $self->_set_cursor($self->cursor + 1);
    return $result;
  }

  return undef;
}

sub prevLine {
  my $self = shift;

  if ($self->cursor > 0) {
    $self->_set_cursor($self->cursor - 1);
    return 1;
  }
  else {
    my $debug = $self->{debug} || $ENV{PDK_DEBUG};
    if (!$debug) {
      warn "错误：游标已在开头，无法获取上一行\n";
      return undef;
    }
    else {
      confess("错误：游标已在开头，无法获取上一行");
    }
  }
}

sub nextUnParsedLine {
  my $self = shift;

  while ($self->cursor < @{$self->config} && $self->getParseFlag) {
    $self->_set_cursor($self->cursor + 1);
  }

  if ($self->cursor < @{$self->config}) {
    my $result = $self->config->[$self->cursor];

    while (!defined $result || $result =~ /^\s*$/m) {
      $self->setParseFlag(1);
      $self->_set_cursor($self->cursor + 1);

      while ($self->cursor < @{$self->config} && $self->getParseFlag) {
        $self->_set_cursor($self->cursor + 1);
      }

      return undef if $self->cursor >= @{$self->config};
      $result = $self->config->[$self->cursor];
    }

    $self->setParseFlag(1);
    $self->_set_cursor($self->cursor + 1);
    chomp $result;
    return $result;
  }

  return undef;
}

sub backtrack {
  my $self = shift;

  if ($self->cursor > 0) {
    $self->_set_cursor($self->cursor - 1);
    $self->setParseFlag(0);
    return 1;
  }
  else {
    my $debug = $self->{debug} || $ENV{PDK_DEBUG};
    if (!$debug) {
      warn "错误：游标已在开头，无法回溯\n";
      return undef;
    }
    else {
      confess("错误：游标已在开头，无法回溯");
    }
  }
}

sub ignore {
  my $self = shift;
  return $self->backtrack ? $self->nextLine : undef;
}

sub getUnParsedLines {
  my $self = shift;

  return join('', map { $self->config->[$_] } grep { !$self->_lineParsedFlags->[$_] } 0 .. $#{$self->config});
}

sub getParseFlag {
  my $self = shift;

  return ($self->cursor >= 0 && $self->cursor < @{$self->config}) ? $self->_lineParsedFlags->[$self->cursor] : undef;
}

sub setParseFlag {
  my ($self, $flag) = @_;

  if ($self->cursor >= 0 && $self->cursor < @{$self->config}) {
    $self->_lineParsedFlags->[$self->cursor] = $flag // 1;
    return 1;
  }

  return undef;
}

__PACKAGE__->meta->make_immutable;
1;
