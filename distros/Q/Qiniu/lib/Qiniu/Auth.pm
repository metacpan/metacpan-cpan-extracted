package Qiniu::Auth;
use strict;
use Qiniu::Util qw/encode_json safe_b64_encode hmac_sha1/;
use Moo;

our $VERSION  = '0.05';

use constant DEFAULT_AUTH_SECONDS => 3600;

has [qw/access_key secret_key/] => ( 
    is => 'ro', 
    required => 1,
);

has Fields => (
    is => 'rw',
    default => sub {
        return {
            # 字符串类型参数
            scope                 => "",
            saveKey               => "",
            endUser               => "",
            returnUrl             => "", # 浏览器上传后执行 302 的地址
            returnBody            => "",
            callbackUrl           => "", # 业务服务器的回调地址
            callbackBody          => "", # 业务服务器的回调信息
            callbackBodyType      => "", # 业务服务器的Content-Type
            persistentOps         => "",
            persistentNotifyUrl   => "",

            # 数值类型参数
            insertOnly            => "",
            fsizeLimit            => "",
            detectMime            => "",
            mimeLimit             => "",
            deadline              => "", 
        }
    }
);

sub upload_token {
    my ($self, $bucket, $key, $expires_in, $args) = @_;
    
    die "need bucket" if !$bucket;
    $self->setPolicy($args) if $args;
    my $scope    = defined $key ? "${bucket}:${key}" : $bucket;
    my $calculateDeadLine = calculateDeadLine($expires_in);
    $self->setPolicy(scope    => $scope);
    $self->setPolicy(deadline => $calculateDeadLine);

    my $encodedPutPolicy = safe_b64_encode($self->PUTPolicy);
    return $self->createToken($encodedPutPolicy) . ':' . $encodedPutPolicy;
}


# 上传策略,参数规格详见
# http://developer.qiniu.com/docs/v6/api/reference/security/put-policy.html
sub PUTPolicy {
    my ($self) = @_;
    my $Fields = $self->Fields;
    my %args = 
        map { $_ => $Fields->{$_}  } 
            grep { $Fields->{$_} } keys %$Fields;
    return encode_json(\%args) 
}

sub private_url {
    my $self = shift;
    my $download_url = shift;
    my $e = time()+3600;
    $download_url = $download_url . "?e=$e";
    my $token = $self->crate_token($download_url);
    return $download_url . "&token=" . $token;
}

sub manage_token {
    my $self = shift;
    return $self->createToken(@_)
}

sub createToken {
    my ($self, $signing_str) = @_;
    my $sign = hmac_sha1($signing_str, $self->secret_key);
    my $encoded_sign = safe_b64_encode($sign);
    return $self->access_key . ':' . $encoded_sign;
}

sub setPolicy {
    my ($self, $key, $value) = @_;
    if ( ref $key eq 'HASH' ) {
        while ( my ($k, $v) = each %$key ) {
            $self->Fields->{$k} = $v if $v;
        }
    }
    else {
        $self->Fields->{$key} = $value
    }
}

sub calculateDeadLine() {
    my ($expires_in, $deadline) = @_;
    if ($expires_in and $expires_in > 0) {
        return time() + $expires_in;
    }
    return time() +  DEFAULT_AUTH_SECONDS;
}

1;

__END__

=pod
 
=encoding utf8

=head1 NAME

七牛云存储认证用 API () 

=head1 SYNOPSIS

    use Qiniu::Auth;
    
    my $SecretKey = 'xx';
    my $AccessKey = 'oo';
    
    my $auth = Qiniu::Auth->new(
        access_key => $AccessKey,
        secret_key => $SecretKey,
    );
    
    my $token  = $auth->upload_token('my-bucket', 'test', 3600, {  returnBody =>  '{ "name": $(fname),  "size": $(fsize)}' });

=head1 DESCRIPTION

注意本部分是在应用服务器端, 提供给其它上传下载 API 用于签名用的模块. 所以要保护好你的 Secret Key 以防流传出去.

本 API 基于 L<七牛云存储官方 API|http://developer.qiniu.com/docs/v6/index.html> 构建。使用此 API 构建您的网络应用程序,能让您以非常便捷地方式将数据安全地存储到七牛云存储上。

=head2 获取 Access Key 和 Secret Key 

要接入七牛云存储,您需要拥有一对有效的 Access Key 和 Secret Key 用来进行签名认证。可以通过如下步骤获得:

1. L<开通七牛开发者帐号|https://portal.qiniu.com/signup>

2. 登录七牛开发者自助平台,查看 L<Access Key 和 Secret Key|https://portal.qiniu.com/setting/key>

=head1 方法 

=head2 upload_toke

取得上传的 token. 第一个参数是 bucket 的名字空间, 第二个参数是 key , 第三个参数是 token 的过期时间, 第三个参数是一些 L<上传策略|http://developer.qiniu.com/docs/v6/api/reference/security/put-policy.html>

   my $token  = $auth->upload_token('my-bucket', 'test', 3600, {  returnBody =>  '{ "name": $(fname),  "size": $(fsize)}' });

关于上传策略更完整的说明,请参考 L<上传凭证|http://developer.qiniu.com/docs/v6/api/reference/security/upload-token.html>。


=head1 下载

=head2 公有文件下载

如果在给 bucket 绑定了域名的话,可以通过以下地址访问。
    
    [GET] http://<domain>/<key>

其中 <domain> 是bucket所对应的域名。七牛云存储为每一个bucket提供一个默认域名。默认域名可以到七牛云存储开发者平台中,空间设置的域名设置一节查询。用户也可以将自有的域名绑定到bucket上,通过自有域名访问七牛云存储。

注意: key 必须采用 utf8 编码,如使用非 utf8 编码访问七牛云存储将反馈错误

=head2 私有文件下载 

私有资源必须通过临时下载授权凭证, 这个方法用于给传进来的下载地址进行方法的转换, 并加入下载 token 签名.

    my $authUrl = $auth->private_url($baseUrl);

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

扶凯 fukai <iakuf@163.com>

=cut
