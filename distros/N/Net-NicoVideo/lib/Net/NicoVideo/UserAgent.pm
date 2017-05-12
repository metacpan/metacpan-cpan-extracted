package Net::NicoVideo::UserAgent;

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = '0.28';

# NOTE: Never inherit with classes that have "get()" or "set()",
# because these interfere with _component which is decorated with Net::NicoVideo::Decorator
use base qw(Net::NicoVideo::Decorator);

use HTTP::Cookies;
use HTTP::Request::Common;
use Net::NicoVideo::Request;
use Net::NicoVideo::Response;

our $MOD_MYLISTGROUP = 'Net::NicoVideo::Content::NicoAPI::MylistGroup';
our $MOD_FLV         = 'Net::NicoVideo::Content::Flv';

sub new {
    my ($class, $component, @opts) = @_;

    # component accepts LWP::UserAgent
    $class->SUPER::new($component, @opts);
}

sub login {
    my ($self, $res) = @_;

    my $cookie_jar = HTTP::Cookies->new;
    $cookie_jar->extract_cookies($res);
    $self->cookie_jar($cookie_jar);

    return $self;
}

sub request_login {
    my ($self, $email, $password) = @_;
    Net::NicoVideo::Response->new(
        $self->request(Net::NicoVideo::Request->login($email,$password)));
}

sub request_get {
    my ($self, $url, @args) = @_;
    Net::NicoVideo::Response->new(
        $self->request(Net::NicoVideo::Request->get($url), @args));
}

#-----------------------------------------------------------
# fetch
# 

sub request_thumbinfo {
    my ($self, $video_id) = @_;
    require Net::NicoVideo::Response::ThumbInfo;
    Net::NicoVideo::Response::ThumbInfo->new(
        $self->request(Net::NicoVideo::Request->thumbinfo($video_id)));
}

sub request_flv {
    my ($self, $video_id) = @_;
    require Net::NicoVideo::Response::Flv;
    Net::NicoVideo::Response::Flv->new(
        $self->request(Net::NicoVideo::Request->flv($video_id)));
}

sub request_watch {
    my ($self, $video_id) = @_;
    require Net::NicoVideo::Response::Watch;
    Net::NicoVideo::Response::Watch->new(
        $self->request(Net::NicoVideo::Request->watch($video_id)));
}

sub request_video {
    my ($self, $flv, @args) = @_;
    my $url = (ref($flv) and $flv->isa($MOD_FLV)) ? $flv->url : $flv;
    require Net::NicoVideo::Response::Video;
    Net::NicoVideo::Response::Video->new(
        $self->request(Net::NicoVideo::Request->get($url), @args));
}

sub request_thread {
    my ($self, $flv, $opts) = @_;
    require Net::NicoVideo::Response::Thread;
    Net::NicoVideo::Response::Thread->new(
        $self->request(Net::NicoVideo::Request->thread($flv->ms,$flv->thread_id,$opts)));
}

#-----------------------------------------------------------
# Tag RSS
# 

sub request_tag_rss {
    my ($self, $keyword, $params) = @_;
    require Net::NicoVideo::Response::TagRSS;
    Net::NicoVideo::Response::TagRSS->new(
        $self->request(Net::NicoVideo::Request->tag_rss($keyword,$params)));
}

#-----------------------------------------------------------
# Mylist RSS
# 

sub request_mylist_rss {
    my ($self, $mylist_id) = @_;
    require Net::NicoVideo::Response::MylistRSS;
    Net::NicoVideo::Response::MylistRSS->new(
        $self->request(Net::NicoVideo::Request->mylist_rss($mylist_id)));
}

#-----------------------------------------------------------
# Mylist Base
# 

# taking NicoAPI.token
sub request_mylist_page {
    my $self = shift;
    require Net::NicoVideo::Response::MylistPage;
    Net::NicoVideo::Response::MylistPage->new(
        $self->request(Net::NicoVideo::Request->mylist_page));
}

# taking NicoAPI.token to update Mylist, item_type and item_id for video_id
sub request_mylist_item {
    my ($self, $video_id) = @_;
    require Net::NicoVideo::Response::MylistItem;
    Net::NicoVideo::Response::MylistItem->new(
        $self->request(Net::NicoVideo::Request->mylist_item($video_id)));
}

#-----------------------------------------------------------
# NicoAPI.MylistGroup
# 

# NicoAPI.MylistGroup #list
sub request_mylistgroup_list {
    my ($self) = @_;
    require Net::NicoVideo::Response::NicoAPI;
    Net::NicoVideo::Response::NicoAPI->new(
        $self->request(Net::NicoVideo::Request->mylistgroup_list));
}

# NicoAPI.MylistGroup #get
sub request_mylistgroup_get {
    my ($self, $group) = @_; # mylistgroup or group_id
    $group = $group->id if( ref($group) and $group->isa($MOD_MYLISTGROUP));
    require Net::NicoVideo::Response::NicoAPI;
    Net::NicoVideo::Response::NicoAPI->new(
        $self->request(Net::NicoVideo::Request->mylistgroup_get($group)));
}

# NicoAPI.MylistGroup #add
sub request_mylistgroup_add {
    my ($self, $group, $token) = @_; # mylistgroup
    require Net::NicoVideo::Response::NicoAPI;
    Net::NicoVideo::Response::NicoAPI->new(
        $self->request(Net::NicoVideo::Request->mylistgroup_add({
            name            => $group->name,
            description     => $group->description,
            public          => $group->public,
            default_sort    => $group->default_sort,
            icon_id         => $group->icon_id,
            }, $token )));
}

# NicoAPI.MylistGroup #update
sub request_mylistgroup_update {
    my ($self, $group, $token) = @_; # mylistgroup
    require Net::NicoVideo::Response::NicoAPI;
    Net::NicoVideo::Response::NicoAPI->new(
        $self->request(Net::NicoVideo::Request->mylistgroup_update({
            group_id        => $group->id,
            name            => $group->name,
            description     => $group->description,
            public          => $group->public,
            default_sort    => $group->default_sort,
            icon_id         => $group->icon_id,
            }, $token )));
}

# NicoAPI.MylistGroup #remove
sub request_mylistgroup_remove {
    my ($self, $group, $token) = @_; # mylistgroup or group_id
    $group = $group->id if( ref($group) and $group->isa($MOD_MYLISTGROUP));
    require Net::NicoVideo::Response::NicoAPI;
    Net::NicoVideo::Response::NicoAPI->new(
        $self->request(Net::NicoVideo::Request->mylistgroup_delete({
            group_id        => $group,
            }, $token )));
}

*request_mylistgroup_delete = *request_mylistgroup_remove;

#-----------------------------------------------------------
# NicoAPI.Mylist
# 

# NicoAPI.Mylist #list
sub request_mylist_list {
    my ($self, $group) = @_; # mylistgroup or group_id
    $group = $group->id if( ref($group) and $group->isa($MOD_MYLISTGROUP));
    require Net::NicoVideo::Response::NicoAPI;
    Net::NicoVideo::Response::NicoAPI->new(
        $self->request(Net::NicoVideo::Request->mylist_list($group)));
}

# NicoAPI.Mylist #add
sub request_mylist_add {
    my ($self, $group, $item, $token) = @_; # mylistgroup or group_id
    $group = $group->id if( ref($group) and $group->isa($MOD_MYLISTGROUP));
    require Net::NicoVideo::Response::NicoAPI;
    Net::NicoVideo::Response::NicoAPI->new(
        $self->request(Net::NicoVideo::Request->mylist_add({
            group_id    => $group,
            item_type   => $item->item_type,
            item_id     => $item->item_id,
            description => $item->description,
            }, $token )));
}

# NicoAPI.Mylist #update
sub request_mylist_update {
    my ($self, $group, $item, $token) = @_; # mylistgroup or group_id
    $group = $group->id if( ref($group) and $group->isa($MOD_MYLISTGROUP));
    require Net::NicoVideo::Response::NicoAPI;
    Net::NicoVideo::Response::NicoAPI->new(
        $self->request(Net::NicoVideo::Request->mylist_update({
            group_id    => $group,
            item_type   => $item->item_type,
            item_id     => $item->item_id,
            description => $item->description,
            }, $token )));
}

# NicoAPI.Mylist #remove
sub request_mylist_remove {
    my $self = shift;
    $self->request_mylist_remove_multi(@_);
}

*request_mylist_delete = *request_mylist_remove;

# NicoAPI.Mylist #removeMulti
sub request_mylist_remove_multi {
    my ($self, $group, $item, $token) = @_; # mylistgroup or group_id
    $group = $group->id if( ref($group) and $group->isa($MOD_MYLISTGROUP));
    require Net::NicoVideo::Response::NicoAPI;
    Net::NicoVideo::Response::NicoAPI->new(
        $self->request(Net::NicoVideo::Request->mylist_delete({
            group_id    => $group,
            item_type   => $item->item_type,
            item_id     => $item->item_id,
            }, $token )));
}

*request_mylist_delete_multi = *request_mylist_remove_multi;

# NicoAPI.Mylist #move
sub request_mylist_move {
    my $self = shift;
    $self->request_mylist_move_multi(@_);
}

# NicoAPI.Mylist #moveMulti
sub request_mylist_move_multi {
    my ($self, $group, $target, $item, $token) = @_; # mylistgroup or group_id
    $group  =  $group->id if( ref($group)  and  $group->isa($MOD_MYLISTGROUP));
    $target = $target->id if( ref($target) and $target->isa($MOD_MYLISTGROUP));
    require Net::NicoVideo::Response::NicoAPI;
    Net::NicoVideo::Response::NicoAPI->new(
        $self->request(Net::NicoVideo::Request->mylist_move({
            group_id        => $group,
            target_group_id => $target,
            item_type       => $item->item_type,
            item_id         => $item->item_id,
            }, $token )));
}

# NicoAPI.Mylist #copy
sub request_mylist_copy {
    shift->request_mylist_copy_multi(@_);
}

# NicoAPI.Mylist #copyMulti
sub request_mylist_copy_multi {
    my ($self, $group, $target, $item, $token) = @_; # mylistgroup or group_id
    $group  =  $group->id if( ref($group)  and  $group->isa($MOD_MYLISTGROUP));
    $target = $target->id if( ref($target) and $target->isa($MOD_MYLISTGROUP));
    require Net::NicoVideo::Response::NicoAPI;
    Net::NicoVideo::Response::NicoAPI->new(
        $self->request(Net::NicoVideo::Request->mylist_copy({
            group_id        => $group,
            target_group_id => $target,
            item_type       => $item->item_type,
            item_id         => $item->item_id,
            }, $token )));
}

1;
__END__


=pod

=head1 NAME

Net::NicoVideo::UserAgent - Decorate LWP::UserAgent with requests to access to Nico Nico Douga

=head1 SYNOPSIS

    use LWP::UserAgent;
    use Net::NicoVideo::UserAgent;
    
    my $ua = Net::NicoVideo::UserAgent->new(
        LWP::UserAgent->new # or other custom UA by your own needs
        );

    # $flv is a Net::NicoVideo::Response::Flv
    my $flv = $ua->request_flv("smNNNNNNNN");

    # Net::NicoVideo::Response is decorated with HTTP::Response
    $flv->is_success

=head1 DESCRIPTION

Decorate L<LWP::UserAgent> with requests to access to Nico Nico Douga.

=head1 SEE ALSO

L<Net::NicoVideo::Decorator>
L<Net::NicoVideo::Request>
L<Net::NicoVideo::Response>

=cut
