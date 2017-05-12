package Net::UpYun;

use v5.10;
use namespace::autoclean;
use Moose;
use Moose::Util::TypeConstraints;
use Digest::MD5 qw(md5_hex);
use HTTP::Date;
use WWW::Curl::Easy;
use HTTP::Response;
use URI::Escape;
use Carp ();

our $VERSION = eval '0.001';

has $_ => (isa => 'Str',is => 'ro', required => 1, writer => '_'.$_ )
    for qw(bucket_account bucket_password);

subtype 'BucketName'
    => as Str
    => where { /^[a-z][a-zA-Z_0-9\-]*$/ }
    => message { "The buckname $_ is not a valid name." };

has bucket => (
    isa => 'BucketName',
    is  => 'ro',
    required => 1,
    writer => '_bucket',
);

has api_domain => (   isa => 'Str',   is  => 'rw', default => 'http://v0.api.upyun.com' );

has curl => (
    isa => 'WWW::Curl::Easy',
    is  => 'ro',
    lazy_build => 1,
    clearer => 'reset_curl',
);


sub _build_curl {
    my ($self) = @_;
    WWW::Curl::Easy->new;
}

has agent => (   isa => 'Str',   is  => 'ro', default => 'Net::UpYun Client/'.$VERSION);

has timeout => (   isa => 'Int',   is  => 'ro', default => 30 );

has response => (
    isa => 'HTTP::Response',
    is  => 'ro',
    lazy_build => 1,
    init_arg => undef,
    writer => '_response',
    handles => {
        is_success => 'is_success',
        is_error => 'is_error',
        res_content => 'content',
        res_header => 'header',
        error_code => 'code',
        error_message => 'message',
    },
);

sub _build_response {
    my ($self) = @_;
    #body
    HTTP::Response->new;
}

sub do_request {
    my ($self,$uri,$method,$headers,$content) = @_;

    my $curl = $self->curl;
    $method = 'GET' unless $method;
    $content = '' unless $content;
    $headers = [] unless $headers;
    my $length = length($content);
    if ($method eq 'POST') {
        $curl->setopt(CURLOPT_CUSTOMREQUEST,undef);
        $curl->setopt(CURLOPT_POST, 1);
        $curl->setopt(CURLOPT_POSTFIELDS, $content);
        $curl->setopt(CURLOPT_POSTFIELDSIZE,length($content));
    }
    elsif ($method eq 'GET') {
        $curl->setopt(CURLOPT_CUSTOMREQUEST,undef);
        $curl->setopt(CURLOPT_HTTPGET, 1);
    }
    elsif ($method eq 'DELETE') {
        $curl->setopt(CURLOPT_CUSTOMREQUEST,'DELETE');
    }

    my $date = time2str( time );
    push @$headers,'Authorization: '.$self->sign($method,$uri,$length,$date);
    push @$headers,'Date: '.$date;

    $curl->setopt(CURLOPT_HTTPHEADER,$headers);
    $curl->setopt(CURLOPT_URL,$self->api_domain.$uri);

    # write buffer
    my ($res_body, $res_head) = ('','');
    open (my $fh_body, ">", \$res_body);
    $curl->setopt(CURLOPT_WRITEDATA,$fh_body);
    open (my $fh_head, ">", \$res_head);
    $curl->setopt(CURLOPT_WRITEHEADER,$fh_head);
    my $retcode = $curl->perform();
    if ($retcode == 0) {
        # say $res_head ."\n".$res_body;
        my $res = HTTP::Response->parse($res_head . "\r" . $res_body);
        $res->content($res_body);
        $self->_response($res);
    }
    else {
        Carp::croak("An error happened: ".$curl->strerror($retcode)." ($retcode)".$curl->errbuf."\n");
    }
}

sub sign {
    my ($self,$method,$uri,$length,$date) = @_;
    $date = time2str( time ) unless defined $date;
    my $sign_str = md5_hex($method.'&'.$uri.'&'.$date.'&'.$length.'&'.md5_hex($self->bucket_password));
    'UpYun '.$self->bucket_account.':'.$sign_str;
}


sub use_bucket {
    my ($self,$bucket,$bucket_account,$bucket_password) = @_;
    $self->_bucket($bucket);
    $self->_bucket_account($bucket_account);
    $self->_bucket_password($bucket_password);
    return $self;
}

sub _uri_path {
    my ($self,$path) = @_;
    '/'.$self->bucket.(substr($path,0,1) eq '/' ? '':'/').uri_escape("$path");
}

sub usage {
    my ($self,$dir) = @_;
    $self->do_request($self->_uri_path($dir || '').'?usage','GET');
    return $self->res_content if $self->is_success;
}

sub mkdir {
    my ($self,$dir) = @_;
    $self->do_request($self->_uri_path($dir),'POST',["folder: true"]);
    return $self->is_success;
}

sub delete {
    my ($self,$key) = @_;
    my $res = $self->do_request($self->_uri_path($key),'DELETE');
    return $self->is_success;
}

sub rmdir {
    my ($self,$dir) = @_;
    $self->do_request($self->_uri_path($dir),'DELETE');
    return $self->is_success;
}

sub put {
    my ($self,$key,$bytes) = @_;
    $self->do_request($self->_uri_path($key),'POST',["Mkdir: true",'Expect: '],$bytes);
    return $self->is_success;
}

sub get {
    my ($self,$key) = @_;
    $self->do_request($self->_uri_path($key));
    return $self->res_content if $self->is_success;
}

sub list {
    my ($self,$dir) = @_;
    # fuck! if missing trailing slash will be failed.
    $dir .= '/' unless substr($dir,-1,1) eq '/';
    $self->do_request($self->_uri_path($dir));
    return $self->res_content if $self->is_success;
}

__PACKAGE__->meta->make_immutable();
1;
__END__

=head1 NAME

Net::UpYun - Simple client library for UpYun Restful API.

=head1 SYNOPSIS

    # Yes, I love modern perl!
    use v5.12;
    use Net::UpYun;
    
    my $upyun = Net::UpYun->new(
        bucket_account => 'xxxxx',
        bucket_password => 'xxxx',
        bucket => 'bucket_name',
        # optional
        api_domain => 'http://v0.api.upyun.com',
    );

    # get bucket/folder/file usage
    my $usage = $upyun->usage;
    # or folder/file
    say $upyun->usage('/demo');

    # switch bucket
    $upyun->use_bucket('bucket_new');
    # use different account/password
    $upyun->use_bucket('bucket_new',$new_account,$new_password);

    # create dir
    my $ok = $upyun->mkdir('/demo2');

    # list file under the directory
    my $files = $upyun->list('/demo2');

    # rm dir
    my $ok = $upyun->rmdir('/demo2');

    # upload file
    my $ok = $upyun->put($file_key,$file_bytes);

    # get file content
    my $bytes = $upyun->get($file_key);

    # delete file
    $upyun->delete($file_key);

    # change api domaim
    $upyun->api_domain('http://v1.api.upyun.com');


=head1 DESCRIPTION

This module provides very simple interfaces to UpYun Cloud servie,for more details about UpYun storage/CDN clound service, see L<http://www.upyun.com/>.

This module uses WWW::Curl and libcurl for best performance, I just test on Mac Lion and Linux, maybe works on Windows/Cygwin.


=head1 METHODS

=head2 new()

=over

=item bucket

=item bucket_account

=item bucket_password

=item api_domain

=back

=head2 usage($path)

    # whole bucket used storage
    $upyun->usage;
    # some dir/folder
    say $upyun->usage('/dir1');
    # some file size
    say $upyun->usage('/dir1/demo1.jpg');

List bucket or path(folder or file) used space. 

=head2 use_bucket($new_bucket_name,$new_account?,$new_password?)

    # switch to new bucket,account/password same as current
    $upyun->use_bucket('bucket2');
    # switch to new bucket, also set new account/password
    $upyun->use_bucket('bucket3','new_user','new_password');

Switch to another bucket, if omit new_account,new_password, use previous defined.

=head2 mkdir($path)
    
    my $ok = $upyun->mkdir('/path1/path2');

Build directory or path.

=head2 rmdir($path)
    
    my $ok = $upyun->rmdir('/path1');

Delete the directory, it must be empty.

=head2 list($path)

    my $dir_content_str = $upyun->list('/');
    
List files under the directory.

TODO: $dir_content_str is plain text, need to parse.

=head2 put($path,$bytes)
    
    # it will auto mkdir.
    my $ok = $upyun->put('/demo/1.txt','okokok');

Upload content to the file, it will auto create directories.

NOTE: According UpYun note, max directories deep level is limited to 10, be careful.

=head2 get($path)
    
    say $upyun->get('/demo/1.txt');

Get the file content.

=head2 delete($path)

    my $ok = $upyun->delete('/demo/1.txt');

Delete the file. 


=head2 reponse

    my $http_response = $upyun->response;

Returns latest response,it's an instance of HTTP::Response.

=head2 res_content

Raw response content body.

=head2 is_success

=head2 is_error

These methods indicate if the response was informational, successful, or an error.
If the response code was 2xx code, is_success is true, else is_error is true.

=head2 error_code

The code is a 3 digit number that encode the overall outcome of the last HTTP response.

=head2 error_message

The message is a short human readable single line string that explains the last response code.

=head2 do_request

Internal, send signed request to server.

=head2 sign

Private.

=head1 TODOS

Much jobs to do.

=over

=item * handy client shell.

=item * copy/move file under same bucket or between different bucket.

=item * simple check file exists on remote ,no need  to fetch its content,save bandwidth.

=item * display/compare files checksum(MD5) local and remote.

=item * streaming upload to save memory.

=item * useful utility, like tar/untar to/from upyun on fly.

=item * multi operation and performance requests in parallel.

=item * code clean and refactory.

=back

=head1 AUTHOR

Night Sailer(Pan Fan) <nightsailer{at}gmail_dot_com>

=head1 COPYRIGHT

Copyright (C) Pan Fan(nightsailer)

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.