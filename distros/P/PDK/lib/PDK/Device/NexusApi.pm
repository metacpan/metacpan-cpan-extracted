package PDK::Device::NexusApi;

#------------------------------------------------------------------------------
# 加载项目依赖模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;
use MIME::Base64;
use Mojo::UserAgent;

#------------------------------------------------------------------------------
# 设定模块通用方法和属性
#------------------------------------------------------------------------------
has host => (is => 'ro', isa => 'Str',);

has username => (is => 'ro', does => 'Str', required => 1,);

has password => (is => 'ro', isa => 'Str',);

#------------------------------------------------------------------------------
# 通过 API 接口下发配置
#------------------------------------------------------------------------------
sub execCommands {
  my ($self, $commands) = @_;

  # 将数组引用对象转换为字串
  my $commandStr = "";
  for my $command (@{$commands}) {
    next if $command =~ /^\s*$|^(!#;)/;
    $commandStr .= "$command ;";
  }
  $commandStr .= 'copy run start ;';

  # 设定接口权限账号
  my $auth = encode_base64("$self->{username}:$self->{password}");
  chop $auth;

  # 设定接口请求消息体
  my $request = '<?xml version="1.0"?>
<ins_api>
  <version>1.0</version>
  <type>cli_conf</type>
  <chunk>0</chunk>
  <sid>sid</sid>
  <input>' . $commandStr . '</input>
  <output_format>xml</output_format>
</ins_api>';

  # 实例化 UA，准备 POST 数据
  my $ua  = Mojo::UserAgent->new;
  my $url = "http://$self->{host}/ins";
  $ua->inactivity_timeout(50);
  my $tx = $ua->post($url => {'Content-Type' => 'xml/text', Authorization => "Basic $auth"} => $request);

  # 判定执行成功
  my @result;
  if (my $res = $tx->success) {
    @result = $res->body =~ /<msg>(.+?)<\/msg>/sg;
    for (my $i = 0; $i < @result; $i++) {
      if (not $result[$i] =~ /Success/i) {
        return {success => 0, reason => "failCommand row $i: " . $commands->[$i]};
      }
    }
    return {success => 1};
  }
  else {
    return {success => 0, reason => $tx->error};
  }
}

#------------------------------------------------------------------------------
# 查询设备信息
#------------------------------------------------------------------------------
sub getInfo {
  my ($self, $commands) = @_;

  # 将数组引用对象转换为字串
  my $commandStr = "";
  for my $command (@{$commands}) {
    next if $command =~ /^\s*$/;
    $commandStr .= $command . " ;";
  }

  # 设定接口权限账号
  my $auth = encode_base64("$self->{username}:$self->{password}");
  chop $auth;

  # 设定接口请求消息体
  my $request = '<?xml version="1.0"?>
<ins_api>
  <version>1.0</version>
  <type>cli_conf</type>
  <chunk>0</chunk>
  <sid>sid</sid>
  <input>' . $commandStr . '</input>
  <output_format>xml</output_format>
</ins_api>';

  # 实例化 UA，准备 POST 数据
  my $ua  = Mojo::UserAgent->new;
  my $url = "http://$self->{host}/ins";
  $ua->inactivity_timeout(50);
  my $tx = $ua->post($url => {'Content-Type' => 'xml/text', Authorization => "Basic $auth"} => $request);

  # 判定执行成功
  my @result;
  if (my $res = $tx->success) {
    @result = $res->body =~ /<body>(.+?)<\/body>/sg;
    return {success => 1, result => \@result};
  }
  return {success => 0, reason => $tx->error};
}

#------------------------------------------------------------------------------
# 实例化对象期间参数检查和完善
#------------------------------------------------------------------------------
around BUILDARGS => sub {
  my $orig  = shift;
  my $class = shift;
  my %param = @_;

  # 设定 XML 消息体
  my $xmlData = '<?xml version="1.0"?>
<ins_api>
  <version>1.0</version>
  <type>cli_conf</type>
  <chunk>0</chunk>
  <sid>sid</sid>
  <input>show hostname</input>
  <output_format>xml</output_format>
</ins_api>';

  # 设定权限账号
  my $credit = encode_base64("$param{username}:$param{password}");
  chop $credit;

  # 实例化 UA
  my $ua  = Mojo::UserAgent->new;
  my $url = "http://$param{host}/ins";
  my $tx  = $ua->post($url => {'Content-Type' => 'xml/text', Authorization => "Basic $credit"} => $xmlData);
  if ($tx->success) {
    return $class->$orig(%param);
  }
  else {
    confess $tx->error;
  }
};

__PACKAGE__->meta->make_immutable;
1;
