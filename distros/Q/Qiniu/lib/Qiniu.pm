package Qiniu;

our $VERSION  = '0.07';

1;

__END__

=pod
 
=encoding utf8

=head1 NAME

七牛云存储上传和资源操作 API

=head1 SYNOPSIS

    use Qiniu::Storage;
    use Qiniu::Auth;
    
    my $SecretKey = 'xx';
    my $AccessKey = 'oo';
    
    my $auth = Qiniu::Auth->new(
        access_key => $AccessKey,
        secret_key => $SecretKey,
    );
    
    my $token  = $auth->upload_token('my-bucket', 'test', 3600, {  returnBody =>  '{ "name": $(fname),  "size": $(fsize)}' });
        
    my $storage = Qiniu::Storage->new( 
        bucket => 'my-bucket',
        auth   => $auth,
    );

    # 直接上传
    my $result = $storage->upload_file($token, '/tmp/fukai.txt', "test");

    # 上传变量, 或者内存中的内容
    my $result = $storage->upload_data($token, 'this is file', "test");

    # 并发多线程流式上传
    my $result = $storage->upload_stream($token, '/tmp/mp4', "test.mp4", "video/mp4");

    # 私有文件下载
    my $authUrl = $auth->private_url($baseUrl);

    # 资源操作
    my $result = $storage->stat("test_fukai.mp4");
    my $result = $storage->copy("test_fukai.mp4", "kk.mp4");

	# 列出文件
	my $result;
	do {
		$result = $storage->list({prefix => 'mp4', limit => 2, marker => $result->{marker}});
	}
	while ($result->{marker});
    
=head1 DESCRIPTION

注意本部分是在应用服务器端, 提供给其它上传下载 API 用于签名用的模块. 所以要保护好你的 Secret Key 以防流传出去.

本 API 基于 L<七牛云存储官方 API|http://developer.qiniu.com/docs/v6/index.html> 构建。使用此 API 构建您的网络应用程序,能让您以非常便捷地方式将数据安全地存储到七牛云存储上。

=head2 获取 Access Key 和 Secret Key 

要接入七牛云存储,您需要拥有一对有效的 Access Key 和 Secret Key 用来进行签名认证。可以通过如下步骤获得:

1. L<开通七牛开发者帐号|https://portal.qiniu.com/signup>

2. 登录七牛开发者自助平台,查看 L<Access Key 和 Secret Key|https://portal.qiniu.com/setting/key>

=head1 属性

=head2 bucket

你这个认证模块所需要操作的 bucket. 这个用于设置一个独立名字空间, 这个空间下在的 key 必须是全局唯一识别. 

=head2 auth

这个需要使用 L<Qiniu::Auth> 的对象, 用于资源操作时生成签名.

=head1 上传

=head2  直接上传

这个 token 需要使用认证的方法直接生成, 第一个参数为 token, 第二个参数为本地文件, 第三个参数为 key.

    my $result = $storage->upload_file($token, '/tmp/fukai.txt', "test");

=head2 上传变量, 或者内存中的内容

这个 token 需要使用认证的方法直接, 第二个参数为变量, 第三个参数为 key.

    my $result = $storage->upload_data($token, 'this is file', "test");

=head2 并发多线程流式上传
    
这个 token 需要使用认证的方法直接, 第二个参数为本地文件, 第三个参数为 key, 第三个参数为 mime 类型.

    my $result = $storage->upload_stream($token, '/tmp/mp4', "test.mp4", "video/mp4");

=head1 下载

=head2 公有文件下载

如果在给 bucket 绑定了域名的话,可以通过以下地址访问。
    
    [GET] http://<domain>/<key>

其中 <domain> 是bucket所对应的域名。七牛云存储为每一个bucket提供一个默认域名。默认域名可以到七牛云存储开发者平台中,空间设置的域名设置一节查询。用户也可以将自有的域名绑定到bucket上,通过自有域名访问七牛云存储。

注意: key 必须采用 utf8 编码,如使用非 utf8 编码访问七牛云存储将反馈错误

=head2 私有文件下载 

私有资源必须通过临时下载授权凭证, 这个方法用于给传进来的下载地址进行方法的转换, 并加入下载 token 签名.

    my $authUrl = $auth->private_url($baseUrl);

=head1 资源操作

资源进行操作的时候, 需要传 L<Qiniu::Auth> 的对象给 L<Qiniu::Storage> 模块来操作. 并且操作的名字空间都是指字的 bucket 范围内.

    my $storage = Qiniu::Storage->new( 
        bucket => 'my-bucket',
        auth   => $auth,
    );

=head2 查询文件状态 

直接查询 new 的时候指定的 bucket 空间对的文件状态.

    my $result = $storage->stat("test_fukai.mp4");

=head2 复制文件 

复制 new 的时候指定的 bucket 内的文件.

    my $result = $storage->copy("test_fukai.mp4", "kk.mp4");

=head2 移动文件 

移动 new 的时候指定的 bucket 内的文件.

    my $result = $storage->move("test_fukai.mp4", "kk.mp4");

=head2 删除文件

删除 new 的时候指定的 bucket 内的文件.

    my $result = $storage->delete("test_fukai.mp4");

=head2 列出文件

列出本 bucket 中的所有文件

	my $result;
	do {
		$result = $storage->list({prefix => 'mp4', limit => 2, marker => $result->{marker}});
		for my $item ( @{ $result->{items} } ) {
			say $item->{key};
		}
	}
	while ($result->{marker});

正常可以使用上面的例子中的语句就能得出所有的文件，默认上面例子是一次查询 2 条，可以写 1000.

=head1 SEE ALSO

L<Mojolicious>

=head1 AUTHOR

扶凯 fukai <iakuf@163.com>

=cut
