package PDK::Utils::UserAgent;

#------------------------------------------------------------------------------
# 设定模块依赖
#------------------------------------------------------------------------------
use 5.016;
use warnings;
use Mojo::UserAgent;
use Sub::Exporter -setup => {exports => [qw/getData postData/]};

#------------------------------------------------------------------------------
# 设定模块依赖
#------------------------------------------------------------------------------
sub getData {
  my $url = shift;

  # 初始化并设定 UA 相关属性
  my $ua = Mojo::UserAgent->new(max_redirects => 3);
  $ua->inactivity_timeout(30);
  $ua->insecure(1);
  $ua->transactor->name("PERL UA");

  # 请求链接并根据响应值做出相关动作
  # my $tx = $ua->get($url => json => $json);
  my $tx = $ua->get($url);
  if (my $err = $tx->error) {
    if ($err->{code}) {
      return {status => $err->{code}, message => $err->{message}};
    }
    else {
      return {status => 500, message => "Connection error: $err->{message}"};
    }
  }
  else {
    return $tx->result->json;
  }
}

#------------------------------------------------------------------------------
# 设定模块依赖
#------------------------------------------------------------------------------
sub postJson {
  my ($url, $json) = @_;

  # 初始化并设定 UA 相关属性
  my $ua = Mojo::UserAgent->new(max_redirects => 3);
  $ua->inactivity_timeout(30);
  $ua->insecure(1);
  $ua->transactor->name("PERL UA");

  # 请求链接并根据响应值做出相关动作
  my $tx = $ua->post($url => json => $json);
  if (my $err = $tx->error) {
    if ($err->{code}) {
      return {status => $err->{code}, message => $err->{message}};
    }
    else {
      return {status => 500, message => "Connection error: $err->{message}"};
    }
  }
  else {
    return $tx->result->json;
  }
}

1;
