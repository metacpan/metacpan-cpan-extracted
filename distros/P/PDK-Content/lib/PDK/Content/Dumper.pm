package PDK::Content::Dumper;

use v5.30;
use Moose::Role;
use Carp       qw(croak);
use File::Path qw(make_path);
use namespace::autoclean;


has month => (
  is      => 'ro',
  default => sub {
    my $month = `date +%Y-%m`;
    chomp($month);
    return $month;
  },
);

has date => (
  is      => 'ro',
  default => sub {
    my $date = `date +%Y-%m-%d`;
    chomp($date);
    return $date;
  },
);

has workdir => (
  is      => 'rw',
  default => sub {
    my $value = $ENV{PDK_CONTENT_HOME};
    _debug_init("从环境变量中加载并设置 workdir：($value)") if defined $value;
    return $value // glob('~');
  },
);

has debug => (
  is      => 'rw',
  default => sub {
    my $value = $ENV{PDK_CONTENT_DEBUG};
    _debug_init("从环境变量中加载并设置 debug：($value)") if defined $value;
    return $value // 0;
  },
);


sub now {
  my $now = `date "+%Y-%m-%d %H:%M:%S"`;
  chomp($now);
  return $now;
}

sub dump {
  my ($self, $msg) = @_;

  $msg .= ';' unless $msg =~ /^\s*$/ || $msg =~ /[,，！!。.]$/;

  my $text = $self->now() . " - [debug] $msg";
  if ($self->debug == 1) {
    say $text;
  }
  elsif ($self->debug > 1) {
    my $workdir = "$self->{workdir}/dump/$self->{month}/$self->{date}";
    make_path($workdir) unless -d $workdir;

    my $name     = $self->{name} // $self->now;
    my $filename = "$workdir/$name\_dump.txt";
    open(my $fh, '>>', $filename) or croak "无法打开文件 $filename 进行写入: $!";
    print $fh "$text\n"           or croak "写入文件 $filename 失败: $!";
    close($fh)                    or croak "关闭文件句柄 $filename 失败: $!";
  }
}

sub write_file {
  my ($self, $config, $name) = @_;

  croak("必须提供非空配置信息") unless !!$config;

  my $workdir = "$self->{workdir}/$self->{month}/$self->{date}";
  make_path($workdir) unless -d $workdir;
  my $filename = "$workdir/$name";
  $self->dump("准备将配置文件写入工作目录: ($workdir)");

  open(my $fh, '>', $filename) or croak "无法打开文件 $filename 进行写入: $!";
  print $fh $config            or croak "写入文件 $filename 失败: $!";
  close($fh)                   or croak "关闭文件句柄 $filename 失败: $!";

  $self->dump("成功写入文本数据到文件: $filename");

  return {success => 1};
}

sub _debug_init {
  my ($msg) = @_;
  my $now = `date "+%Y-%m-%d %H:%M:%S"`;
  chomp($now);
  my $text = $now . " - [debug] $msg\n";
  print STDERR $text if $ENV{PDK_CONTENT_DEBUG};
}

1;
