use strict;
use warnings;
use Test::More;

use Net::NicoVideo::Request;
use URI::Escape;


# get
for ((1..2)){
    my $r;
    if( $_ % 2 ){
        # as class method 
        $r = Net::NicoVideo::Request->get('http://www.nicovideo.jp/');
    }else{
        # as instnce method
        $r = Net::NicoVideo::Request->new->get('http://www.nicovideo.jp/');
    }
    #print $r->as_string;
    is( $r->method, 'GET');
    is( $r->url, 'http://www.nicovideo.jp/');
}


# login
for ((1..2)){
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->login('address','secret');
    }else{
        $r = Net::NicoVideo::Request->new->login('address','secret');
    }
    is($r->method, "POST");
    is($r->url, 'https://secure.nicovideo.jp/secure/login?site=niconico');
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 38);
    is($r->content, "next_url=&mail=address&password=secret");

}
eval { Net::NicoVideo::Request->login };
ok( $@ );
eval { Net::NicoVideo::Request->login('address') };
ok( $@ );


# thumbinfo
for ((1..2)){
    my $r;
    my $video_id = 1;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->thumbinfo($video_id);
     }else{
        $r = Net::NicoVideo::Request->new->thumbinfo($video_id);
     }
     
    is( $r->method, 'GET');
    is( $r->url, 'http://ext.nicovideo.jp/api/getthumbinfo/'.$video_id);
}
eval { Net::NicoVideo::Request->thumbinfo };
ok( $@ );


# flv (1)
for ((1..2)){
    my $video_id = "sm00000";
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->flv($video_id);
    }else{
        $r = Net::NicoVideo::Request->new->flv($video_id);
    }
    is( $r->method, 'POST');
    is( $r->url, 'http://flapi.nicovideo.jp/api/getflv/'.$video_id);
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 0);
    is($r->content, '');
}
eval { Net::NicoVideo::Request->flv };
ok( $@ );


# flv (2)
for ((1..2)){
    my $video_id = "nm00000";
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->flv($video_id);
    }else{
        $r = Net::NicoVideo::Request->new->flv($video_id);
    }
    is( $r->method, 'POST');
    is( $r->url, 'http://flapi.nicovideo.jp/api/getflv/'.$video_id);
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 5);
    is($r->content, 'as3=1');
}


# watch
for ((1..2)){
    my $video_id = "sm00000";
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->watch($video_id);
     }else{
        $r = Net::NicoVideo::Request->new->watch($video_id);
     }
    is( $r->method, 'GET');
    is( $r->url, 'http://www.nicovideo.jp/watch/'.$video_id);
}
eval { Net::NicoVideo::Request->watch };
ok( $@ );


# thread (1)
for ((1..2)){
    my $ms          = 'http://www.nicovideo.jp/'; # TODO - it is dummy, check actual url
    my $thread_id   = '123';
    my $opts        = {
        'chats'     => undef,
        'fork'      => undef,
        };
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->thread($ms, $thread_id, $opts);
    }else{
        $r = Net::NicoVideo::Request->new->thread($ms, $thread_id, $opts);
    }
    is( $r->method, 'POST');
    is( $r->url, $ms);
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 65);
    is($r->content, sprintf('<thread thread="%s" version="20061206" res_from="%s"></thread>', "123", "-250"));
}
eval { Net::NicoVideo::Request->thread };
ok( $@ );
eval { Net::NicoVideo::Request->thread('http://www.nicovideo.jp/') };
ok( $@ );


# thread (2)
for ((1..2)){
    my $ms          = 'http://www.nicovideo.jp/'; # TODO - it is dummy, check actual url
    my $thread_id   = '456';
    my $opts        = {
        'chats'     => 100,
        'fork'      => 1,
        };
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->thread($ms, $thread_id, $opts);
    }else{
        $r = Net::NicoVideo::Request->new->thread($ms, $thread_id, $opts);
    }
    is( $r->method, 'POST');
    is( $r->url, $ms);
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 74);
    is($r->content, sprintf('<thread thread="%s" version="20061206" res_from="%s" fork="1"></thread>', "456", "-100"));
}


# tag_rss
for ((1..2)){
    my $keyword = '初音ミク';
    my $params = {
        rss => '2.0',
        };
    $params->{extra} = '鏡音リン';
    my $r;
    if( $_ % 2 ){
        # as class method 
        $r = Net::NicoVideo::Request->tag_rss($keyword, $params);
     }else{
        # as instnce method
        $r = Net::NicoVideo::Request->new->tag_rss($keyword, $params);
     }
    is( $r->method, 'GET');
    is( $r->url, sprintf('http://www.nicovideo.jp/tag/%s?%s=%s&rss=2.0',
        uri_escape_utf8($keyword), uri_escape_utf8('extra'), uri_escape_utf8('鏡音リン')
        ));
}
eval { Net::NicoVideo::Request->tag_rss };
ok( $@ );


# mylist_rss
for ((1..2)){
    my $mylist_id = 12345;
    my $r;
    if( $_ % 2 ){
        # as class method 
        $r = Net::NicoVideo::Request->mylist_rss($mylist_id);
    }else{
        # as instnce method
        $r = Net::NicoVideo::Request->new->mylist_rss($mylist_id);
    }
    is( $r->method, 'GET');
    is( $r->url, 'http://www.nicovideo.jp/mylist/'.$mylist_id.'?rss=2.0');
}
eval { Net::NicoVideo::Request->mylist_rss };
ok( $@ );


# mylist_page
for ((1..2)){
    my $r;
    if( $_ % 2 ){
        # as class method 
        $r = Net::NicoVideo::Request->mylist_page;
    }else{
        # as instnce method
        $r = Net::NicoVideo::Request->new->mylist_page;
    }
    is( $r->method, 'GET');
    is( $r->url, 'http://www.nicovideo.jp/my/mylist');
}


# mylist_item
for ((1..2)){
    my $video_id = 'sm00000';
    my $r;
    if( $_ % 2 ){
        # as class method 
        $r = Net::NicoVideo::Request->mylist_item($video_id);
    }else{
        # as instnce method
        $r = Net::NicoVideo::Request->new->mylist_item($video_id);
    }
    is( $r->method, 'GET');
    is( $r->url, 'http://www.nicovideo.jp/mylist_add/video/'.$video_id);
}
eval { Net::NicoVideo::Request->mylist_item };
ok( $@ );


# mylistgroup_list
for ((1..2)){
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->mylistgroup_list;
    }else{
        $r = Net::NicoVideo::Request->new->mylistgroup_list;
    }
    is( $r->method, 'POST');
    is( $r->url, 'http://www.nicovideo.jp/api/mylistgroup/list');
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 0);
    is($r->content, '');
}


# mylistgroup_get
for ((1..2)){
    my $mylist_id = 12345;
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->mylistgroup_get($mylist_id);
    }else{
        $r = Net::NicoVideo::Request->new->mylistgroup_get($mylist_id);
    }
    is( $r->method, 'POST');
    is( $r->url, 'http://www.nicovideo.jp/api/mylistgroup/get');
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 14);
    is($r->content, 'group_id=12345');
}
eval { Net::NicoVideo::Request->mylistgroup_get };
ok( $@ );


# mylistgroup_add
for ((1..2)){
    my $params  = {
        name        => 'this name',
        description => '詳細',
        public      => '1',
        default_sort=> '0',
        icon_id     => '2',
        };
    my $token   = "abcdefg";
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->mylistgroup_add($params, $token);
    }else{
        $r = Net::NicoVideo::Request->new->mylistgroup_add($params, $token);
    }
    is( $r->method, 'POST');
    is( $r->url, 'http://www.nicovideo.jp/api/mylistgroup/add');
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 93);
    is($r->content,
        sprintf('token=%s&name=%s&description=%s&public=%s&default_sort=%s&icon_id=%s',
        $token, 'this+name', '%E8%A9%B3%E7%B4%B0', '1', '0', '2'));
}


# mylistgroup_update
for ((1..2)){
    my $params  = {
        group_id    => '12345',
        name        => 'this name',
        description => '詳細',
        public      => '1',
        default_sort=> '0',
        icon_id     => '2',
        };
    my $token   = "abcdefg";
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->mylistgroup_update($params, $token);
    }else{
        $r = Net::NicoVideo::Request->new->mylistgroup_update($params, $token);
    }
    is( $r->method, 'POST');
    is( $r->url, 'http://www.nicovideo.jp/api/mylistgroup/update');
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 108);
    is($r->content,
        sprintf('token=%s&group_id=%s&name=%s&description=%s&public=%s&default_sort=%s&icon_id=%s',
        $token, '12345', 'this+name', '%E8%A9%B3%E7%B4%B0', '1', '0', '2'));
}


# mylistgroup_delete
for ((1..2)){
    my $params  = {
        group_id    => '12345',
        };
    my $token   = "abcdefg";
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->mylistgroup_delete($params, $token);
    }else{
        $r = Net::NicoVideo::Request->new->mylistgroup_delete($params, $token);
    }
    is( $r->method, 'POST');
    is( $r->url, 'http://www.nicovideo.jp/api/mylistgroup/delete');
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 28);
    is($r->content,
        sprintf('token=%s&group_id=%s',
        $token, '12345'));
}


# mylist_list
for ((1..2)){
    my $group_id = '12345';
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->mylist_list($group_id);
    }else{
        $r = Net::NicoVideo::Request->new->mylist_list($group_id);
    }
    is( $r->method, 'POST');
    is( $r->url, 'http://www.nicovideo.jp/api/mylist/list');
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 14);
    is($r->content, 'group_id=12345');
}
eval { Net::NicoVideo::Request->mylist_list };
ok( $@ );


# mylist_add
for ((1..2)){
    my $params  = {
        group_id    => '12345',
        item_type   => '0',
        item_id     => '01234',
        description => '詳細',
        };
    my $token   = "abcdefg";
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->mylist_add($params, $token);
    }else{
        $r = Net::NicoVideo::Request->new->mylist_add($params, $token);
    }
    is( $r->method, 'POST');
    is( $r->url, 'http://www.nicovideo.jp/api/mylist/add');
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 85);
    is($r->content,
        sprintf('token=%s&group_id=%s&item_type=%s&item_id=%s&description=%s',
        $token, '12345', '0', '01234', '%E8%A9%B3%E7%B4%B0'));
}


# mylist_update
for ((1..2)){
    my $params  = {
        group_id    => '12345',
        item_type   => '0',
        item_id     => '01234',
        description => '詳細',
        };
    my $token   = "abcdefg";
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->mylist_update($params, $token);
    }else{
        $r = Net::NicoVideo::Request->new->mylist_update($params, $token);
    }
    is( $r->method, 'POST');
    is( $r->url, 'http://www.nicovideo.jp/api/mylist/update');
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 85);
    is($r->content,
        sprintf('token=%s&group_id=%s&item_type=%s&item_id=%s&description=%s',
        $token, '12345', '0', '01234', '%E8%A9%B3%E7%B4%B0'));
}


# mylist_delete
for ((1..2)){
    my $params  = {
        group_id    => '12345',
        item_type   => '0',
        item_id     => '01234',
        };
    my $token   = "abcdefg";
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->mylist_delete($params, $token);
    }else{
        $r = Net::NicoVideo::Request->new->mylist_delete($params, $token);
    }
    is( $r->method, 'POST');
    is( $r->url, 'http://www.nicovideo.jp/api/mylist/delete');
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 55);
    is($r->content, 'id_list%5B0%5D%5B%5D=01234&token=abcdefg&group_id=12345');
}


# mylist_move
for ((1..2)){
    my $params  = {
        group_id    => '12345',
        item_type   => '0',
        item_id     => '01234',
        target_group_id => '9876',
        };
    my $token   = "abcdefg";
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->mylist_move($params, $token);
    }else{
        $r = Net::NicoVideo::Request->new->mylist_move($params, $token);
    }
    is( $r->method, 'POST');
    is( $r->url, 'http://www.nicovideo.jp/api/mylist/move');
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 76);
    is($r->content, 'id_list%5B0%5D%5B%5D=01234&token=abcdefg&group_id=12345&target_group_id=9876');
}


# mylist_copy
for ((1..2)){
    my $params  = {
        group_id    => '12345',
        item_type   => '0',
        item_id     => '01234',
        target_group_id => '9876',
        };
    my $token   = "abcdefg";
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->mylist_copy($params, $token);
    }else{
        $r = Net::NicoVideo::Request->new->mylist_copy($params, $token);
    }
    is( $r->method, 'POST');
    is( $r->url, 'http://www.nicovideo.jp/api/mylist/copy');
    is($r->content_type, 'application/x-www-form-urlencoded');
    is($r->content_length, 76);
    is($r->content, 'id_list%5B0%5D%5B%5D=01234&token=abcdefg&group_id=12345&target_group_id=9876');
}


# make_id_list
for ((1..2)){
    # scalar context
    my $r;
    if( $_ % 2 ){
        $r = Net::NicoVideo::Request->make_id_list('0', '123');
    }else{
        $r = Net::NicoVideo::Request->new->make_id_list('0', '123');
    }
    ok(eq_array( $r, ['id_list[0][]','123']));

    # list context
    my @r;
    if( $_ % 2 ){
        @r = Net::NicoVideo::Request->make_id_list('0', '123');
    }else{
        @r = Net::NicoVideo::Request->new->make_id_list('0', '123');
    }
    ok(eq_array( \@r, ['id_list[0][]','123']));
}
eval { Net::NicoVideo::Request->make_id_list };
ok( $@ );
eval { Net::NicoVideo::Request->make_id_list('1') };
ok( $@ );



done_testing();
1;
__END__
