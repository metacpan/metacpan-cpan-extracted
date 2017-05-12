package Plack::Middleware::JSON;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use JSON::XS;
use URI::Escape;
our $VERSION = 0.01;

use Plack::Util::Accessor qw/json_key callback_key/;

sub prepare_app {
    my $self = shift;
    unless (defined $self->callback_key) {
        $self->callback_key('callback');
    }   
    if (defined $self->json_key) {
        my $json_key = $self->json_key() . '|' . $self->callback_key; 
        $self->json_key($json_key);
    }   
    else {
        $self->json_key($self->callback_key);
    }
}

sub call {
    my($self, $env) = @_; 
    my $res = $self->app->($env);
    $self->response_cb($res, sub {
        my $res = shift;
        if (defined $res->[2]) {
            my $h = Plack::Util::headers($res->[1]);
            my $json_key = $self->json_key;
            my $content_type = $h->get('Content-Type') || '';
            if (($json_key and $env->{QUERY_STRING} =~ /(?:^|&)($json_key)=([^&]+)/) or $content_type =~ m!/(?:json|javascript)!) {
                # json
                if ((ref $res->[2][0] eq 'ARRAY') or (ref $res->[2][0] eq 'HASH')) {
                   $res->[2] =  [ encode_json($res->[2][0]) ]; 
                }
                # jsonp
                if (defined $self->callback_key and $1 and $1 eq $self->callback_key) {
                    my $cb = URI::Escape::uri_unescape($2);
                    if ($cb =~ /^[\w\.\[\]]+$/) {
                        my $body;
                        Plack::Util::foreach($res->[2], sub { $body .= $_[0] }); 
                        my $jsonp = "$cb($body)";
                        $res->[2] = [ $jsonp ];
                    }   
                }
                $h->set('Content-Length', length $res->[2][0]);
                $h->set('Content-Type', 'application/json; charset=utf-8');
            }   
        }   
    }); 
}

1;
__END__

=pod

=encoding utf8

=head1 NAME

Plack::Middleware::JSON - 给输出内容转换成 JSON, 并且自动兼容 JSONP. 

=head1 SYNOPSIS

  enable 'Plack::Middleware::JSON',
      json_key => "json", callback_key => 'callback'; 

=head1 DESCRIPTION

Plack::Middleware::JSON 这个是用于给 PSGI 应用输出结果转换成 JSON 结果, 注意就是 PSGI 的第三个参数 $_[2] 必须是一个数组引用或者哈希引用.


=head1 CONFIGURATION


=head2 json_key

  json_key => "json";

这个可以根据条件来决定是否做这个转换. 比如指定 json_key 用于指定, 当查询参数出现指定的这个 key , 并且这个 key 为真的时候来做结果的转换.
默认如果内容的输出结果中 content-type 中指定了结果需要 json 的时候, 也会做转换.

=head2 callback_key 

  callback_key => 'callback';
 
当请求过来的查询, 如果需要输出 JSONP 的内容时, 可以指定这个参数, 默认这个参数是 callback.

=head1 AUTHOR

扶凯 E<lt>iakuf@163.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Plack::Middleware::JSONP|https://metacpan.org/pod/Plack::Middleware::JSONP>

=cut
