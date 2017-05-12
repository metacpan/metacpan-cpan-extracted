package Qiniu::Storage;
use Moo;
use 5.010;
use Mojo::UserAgent;
use Mojo::Asset::File;
use Qiniu::Util qw/safe_b64_encode encoded_entry_uri/;

our $VERSION  = '0.06';

has auth  => (
    is => 'ro',
);
has bucket => (
    is => 'ro',
    required => 1,
);

has rsapi => (
    is => 'rw',
    default => sub {'http://rs.qiniu.com'},
);

has ua => (
    is => 'rw',
    default => sub { return Mojo::UserAgent->new },
);

has upapi => (
    is => 'rw',
    default => sub {'http://upload.qiniu.com'},
);


sub upload_file {
    my ($self, $token, $local_file, $key ) = @_;
    my $ua = Mojo::UserAgent->new;
    return $ua->post($self->upapi => form => {
        key       => $key,
        token     => $token,
        file => { 
            file => $local_file 
        }}
    )->res->json;
}

sub upload_data {
    my ($self, $token, $data, $key ) = @_;
    my $ua = Mojo::UserAgent->new;
    return $ua->post($self->upapi => form => {
        key       => $key,
        token     => $token,
        file => { 
			filename => $key,
            content  => $data, 
        }}
    )->res->json;
}

sub upload_stream  {
    my ($self, $token, $local_file, $key, $mimetype) = @_;
    my $ua = Mojo::UserAgent->new;
    my $file = Mojo::Asset::File->new(path => $local_file);
     
    my $length = $file->size;
    my @blocks = split_range($length);
    my @ctx;
    for my $block_nu ( 0 .. $#blocks ) {
        my $block = $blocks[$block_nu];
        my $block_data = $file->get_chunk($block->{start_range}, $block->{max});
        my $mkblkAPI = $self->upapi .'/mkblk/'. $block->{end_range};
        my $chunk_data = Mojo::Asset::Memory->new->add_chunk($block_data);
        my @chunk = split_range($chunk_data->size, 1 * (1024 ** 2));

        my $result;
        for my $nu (0..$#chunk) {
            my $chunk_info = $chunk[$nu];
            my $mkblkAPI = $self->upapi . '/mkblk/' . $block->{max};
            if ($nu != 0) {
                $mkblkAPI = $self->upapi . '/bput/' . $result->{ctx} .'/'. $chunk_info->{start_range};  
            }
            my $bput_data = $chunk_data->get_chunk($chunk_info->{start_range}, $chunk_info->{max});
            $result = $ua->post($mkblkAPI => 
                        {
                            'Content-Length'=> $chunk_info->{max},
                            'Content-Type'  => 'application/octet-stream', 
                            'Authorization' => 'UpToken ' . $token,
                        }, 
                        $bput_data)->res->json;
            $ctx[$block_nu] = $result->{ctx};
        }
    }
    my $mkfile_api = $self->upapi . '/mkfile/' . $length . '/key/'. safe_b64_encode($key);
    $mkfile_api = defined $mimetype ?  $mkfile_api . "/mimeType/" .  safe_b64_encode('video/mp4') : $mkfile_api;
    my $data = join(',' , @ctx);
    return $ua->post( $mkfile_api => {
                'Content-Type' =>  'text/plain',
                'Authorization' => 'UpToken ' . $token,
            } => $data )->res->json;  

}

sub stat {
    my $self = shift;
    my $op = '/stat/' . encoded_entry_uri($self->bucket, shift);
	return $self->rsget($op);
}

sub copy {
    my $self = shift;
    my $op = '/copy/' . encoded_entry_uri($self->bucket, $_[0]) . '/' . encoded_entry_uri($self->bucket, $_[1]);
    return $self->rsget($op);
}

sub move {
    my $self = shift;
    my $op = '/move/' . encoded_entry_uri($self->bucket, $_[0]) . '/' . encoded_entry_uri($self->bucket, $_[1]);
    return $self->rsget($op);
}

sub delete {
    my $self = shift;
    my $op = '/delete/' . encoded_entry_uri($self->bucket, shift);
    return $self->rsget($op);
}

sub list {
	my $self = shift;
	my $args = shift;

	$args->{bucket} ||= $self->bucket;
	my $params = Mojo::Parameters->new(%$args);
	my $url = "http://rsf.qbox.me/list?" . $params->to_string;
	$self->register_token($self->ua);
	my $tx = $self->ua->post($url);
	if (my $res = $tx->success) {
		return $res->json;  
	}
	else {
		my $err = $tx->error;
		return "$err->{code} response: $err->{message}" if $err->{code};
		return "Connection error: $err->{message}";
	}
}

sub register_token {
	my ($self, $ua) = (shift, shift);
	$ua->on(start => sub {
        my ($ua, $tx) = @_;
        my $signingStr = $tx->req->url->path_query . "\n";
        if ($tx->req->body) {
            $signingStr = $signingStr . "\n" . $tx->req->body;
            $tx->req->headers->header('Content-Type' => 'application/x-www-form-urlencoded');
        }
        my $manage_token = $self->auth->manage_token($signingStr);
        $tx->req->headers->header('Authorization' => 'QBox ' . $manage_token);
    });
}

# 资源操作接口
sub rsget {
    my ($self, $op) = @_;
	$self->register_token($self->ua);
    my $opapi = $self->rsapi . $op;
	return $self->ua->post( $opapi )->res->json;  
}

sub split_range {
    my ($length, $seg_size) = @_;

    # 每个请求的段大小的范围,字节
    $seg_size ||= 4 * (1024 ** 2); 

    # 要处理的字节的总数
    my $len_remain = $length;

    my @ranges;
    while ( $len_remain > 0 ) {
        # 每个 segment  的大小
        my $seg_len = $seg_size;

        # 偏移长度
        my $ofs = $length - $len_remain;
        
        # 剩余字节
        $len_remain -= $seg_len;

        my $tail  = $ofs + $seg_len; 
        if ( $length  < $tail) {
            $tail = $length;
        }

        push @ranges, { 
            start_range => $ofs,   # 本块的起点
            end_range   => $tail,  # 本块的结束
            max         => $tail - $ofs,
        }; 
    }
    return @ranges
}
1;

__END__

=pod
 
=encoding utf8

=head1 NAME

七牛云存储上传和资源操作 API

=head1 SYNOPSIS

    use Qiniu::Storage;
    use Qiniu::Auth;
	use 5.010;
    
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

    # 资源操作
    my $result = $storage->stat("test_fukai.mp4");
    my $result = $storage->copy("test_fukai.mp4", "kk.mp4");

	# 列出所有文件
	my $result;
	do {
		$result = $storage->list({prefix => 'mp4', limit => 2, marker => $result->{marker}});
		for my $item ( @{ $result->{items} } ) {
			say $item->{key};
		}
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
