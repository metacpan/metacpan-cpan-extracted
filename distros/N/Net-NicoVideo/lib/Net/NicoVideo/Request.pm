package Net::NicoVideo::Request;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.27';

use base qw(HTTP::Request);
use HTTP::Request::Common;
use Carp qw/croak/;
use URI::Escape;

sub get {
    my $class = shift;
    return GET @_;
}

sub login {
    my ($class, $email, $password) = @_;
    croak "missing mandatory parameter"
        if( ! defined $email or ! defined $password );
    my $url = 'https://secure.nicovideo.jp/secure/login?site=niconico';
    return POST $url, [
        next_url    => '',
        mail        => $email,
        password    => $password,
        ];
}

sub thumbinfo {
    my ($class, $video_id) = @_;
    croak "missing mandatory parameter"
        if( ! defined $video_id );
    my $url = 'http://ext.nicovideo.jp/api/getthumbinfo/'.$video_id;
    return GET $url;
}

sub flv {
    my ($class, $video_id) = @_;
    croak "missing mandatory parameter"
        if( ! defined $video_id);
    my $url = 'http://flapi.nicovideo.jp/api/getflv/'.$video_id;
    my $params = $video_id =~ /^nm/ ? ['as3' => 1] : [];
    return POST $url, $params;
}

sub watch {
    my ($class, $video_id) = @_;
    croak "missing mandatory parameter"
        if( ! defined $video_id);
    my $url = 'http://www.nicovideo.jp/watch/'.$video_id;
    return GET $url;
}

sub thread {
    my ($class, $ms, $thread_id, $opts) = @_;
    croak "missing mandatory parameter"
        if( ! defined $ms or ! defined $thread_id );
    $opts ||= {};
    return POST $ms,
        Content => sprintf '<thread thread="%s" version="20061206" res_from="-%d"%s></thread>',
            $thread_id, ($opts->{'chats'} || 250), ($opts->{'fork'} ? ' fork="1"' : '');    
}

sub tag_rss {
    my ($class, $keyword, $params) = @_;
    croak "missing mandatory parameter"
        if( ! defined $keyword );
    $params ||= {};
    $params->{rss} = '2.0';
    my @q = ();
    for my $k ( sort keys %{$params} ){
        my $v = $params->{$k};
        $v = '' unless( defined $v );
        push @q, sprintf('%s=%s', uri_escape_utf8($k), uri_escape_utf8($v));
    }
    my $url = sprintf 'http://www.nicovideo.jp/tag/%s', uri_escape_utf8($keyword);
    $url = sprintf('%s?%s', $url, join('&', @q)) if( @q );
    return GET $url;
}

sub mylist_rss {
    my ($class, $mylist_id) = @_;
    croak "missing mandatory parameter"
        if( ! defined $mylist_id );
    my $url = 'http://www.nicovideo.jp/mylist/'.$mylist_id.'?rss=2.0';
    return GET $url;
}

sub mylist_page {
    my ($class) = @_;
    return GET 'http://www.nicovideo.jp/my/mylist';
}

sub mylist_item {
    my ($class, $video_id) = @_;
    croak "missing mandatory parameter"
        if( ! defined $video_id );
    my $url = 'http://www.nicovideo.jp/mylist_add/video/'.$video_id;
    return GET $url;
}

sub mylistgroup_list {
    my ($class) = @_;
    return POST 'http://www.nicovideo.jp/api/mylistgroup/list';
}

sub mylistgroup_get {
    my ($class, $mylist_id) = @_;
    croak "missing mandatory parameter"
        if( ! defined $mylist_id );
    my $params = [ group_id => $mylist_id ];
    return POST 'http://www.nicovideo.jp/api/mylistgroup/get', $params;
}

sub mylistgroup_add {
    my ($class, $params, $token) = @_;
    $params ||= {};
    return POST 'http://www.nicovideo.jp/api/mylistgroup/add', [
        token       => $token,
        name        => $params->{name},
        description => $params->{description},
        public      => $params->{public},
        default_sort=> $params->{default_sort},
        icon_id     => $params->{icon_id},
        ];
}

sub mylistgroup_update {
    my ($class, $params, $token) = @_;
    $params ||= {};
    return POST 'http://www.nicovideo.jp/api/mylistgroup/update', [
        token       => $token,
        group_id    => $params->{group_id},
        name        => $params->{name},
        description => $params->{description},
        public      => $params->{public},
        default_sort=> $params->{default_sort},
        icon_id     => $params->{icon_id},
        ];
}

sub mylistgroup_delete {
    my ($class, $params, $token) = @_;
    $params ||= {};
    return POST 'http://www.nicovideo.jp/api/mylistgroup/delete', [
        token       => $token,
        group_id    => $params->{group_id},
        ];
}

sub mylist_list {
    my ($class, $group_id) = @_;
    croak "missing mandatory parameter"
        if( ! defined $group_id );
    my $params = [ group_id => $group_id ];
    return POST 'http://www.nicovideo.jp/api/mylist/list', $params;
}

sub mylist_add {
    my ($class, $params, $token) = @_;
    $params ||= {};
    return POST 'http://www.nicovideo.jp/api/mylist/add', [
        token       => $token,
        group_id    => $params->{group_id},
        item_type   => $params->{item_type},
        item_id     => $params->{item_id},
        description => $params->{description},
        ];
}

sub mylist_update {
    my ($class, $params, $token) = @_;
    $params ||= {};
    return POST 'http://www.nicovideo.jp/api/mylist/update', [
        token       => $token,
        group_id    => $params->{group_id},
        item_type   => $params->{item_type},
        item_id     => $params->{item_id},
        description => $params->{description},
        ];
}

sub mylist_delete {
    my ($class, $params, $token) = @_;
    $params ||= {};
    my @args = $class->make_id_list($params->{item_type}, $params->{item_id});
    push @args, (
        token       => $token,
        group_id    => $params->{group_id},
        );
    return POST 'http://www.nicovideo.jp/api/mylist/delete', \@args;
}

sub mylist_move {
    my ($class, $params, $token) = @_;
    $params ||= {};
    my @args = $class->make_id_list($params->{item_type}, $params->{item_id});
    push @args, (
        token           => $token,
        group_id        => $params->{group_id},
        target_group_id => $params->{target_group_id},
        );
    return POST 'http://www.nicovideo.jp/api/mylist/move', \@args;
}

sub mylist_copy {
    my ($class, $params, $token) = @_;
    $params ||= {};
    my @args = $class->make_id_list($params->{item_type}, $params->{item_id});
    push @args, (
        token           => $token,
        group_id        => $params->{group_id},
        target_group_id => $params->{target_group_id},
        );
    return POST 'http://www.nicovideo.jp/api/mylist/copy', \@args;
}

sub make_id_list {
    my ($class, $item_type, $item_id) = @_;
    croak "missing mandatory parameter"
        if( ! defined $item_type or ! defined $item_id );
    my @id_list = ('id_list['.$item_type.'][]' => $item_id);
    return wantarray ? @id_list : \@id_list;
}

1;
__END__
