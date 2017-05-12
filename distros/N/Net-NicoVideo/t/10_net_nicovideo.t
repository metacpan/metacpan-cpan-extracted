use strict;
use warnings;
use Test::More;

use Net::NicoVideo;
use LWP::UserAgent;


isa_ok( Net::NicoVideo->new, 'Net::NicoVideo');

ok( defined $Net::NicoVideo::VERSION, 'defined VERSION');
is( $Net::NicoVideo::DELAY_DEFAULT, 1, 'default delay');


#-----------------------------------------------------------
# accessor
#

do {
    my ($nnv, $ua, $email, $password, $delay);

    $nnv = Net::NicoVideo->new;

    # member accessor
    is $nnv->user_agent, undef, 'default user_agent';
    is $nnv->email, undef, 'default email';
    is $nnv->password, undef, 'default password';
    is $nnv->delay, undef, 'default delay';

    # setter/getter
    $ua = new LWP::UserAgent;
    is $nnv->user_agent($ua), $ua, 'set user_agent';
    is $nnv->user_agent,      $ua, 'get user_agent';

    $email = 'mail@address.hoge';
    is $nnv->email($email), $email, 'set email';
    is $nnv->email,         $email, 'get email';

    $password = 'foobar';
    is $nnv->password($password), $password, 'set password';
    is $nnv->password,            $password, 'get password';

    $delay = 100;
    is $nnv->delay($delay), $delay, 'set delay';
    is $nnv->delay,         $delay, 'get delay';
};


#-----------------------------------------------------------
# getter
#

do {
    my ($nnv, $ua, $email, $password, $delay);

    $nnv = Net::NicoVideo->new;
    
    isa_ok $nnv->get_user_agent, "Net::NicoVideo::UserAgent", "default user_agent";
    isa_ok $nnv->user_agent, "LWP::UserAgent", "ua set after get";

    do {
        local %ENV = ();
        is $nnv->get_email, undef, 'default undef get_email';
        is $nnv->get_password, undef, 'default undef get_password';
    };
    do {
        local $ENV{NET_NICOVIDEO_EMAIL} = 'net@nicovideo.email';
        local $ENV{NET_NICOVIDEO_PASSWORD} = 'hahahaha';
        is $nnv->get_email, 'net@nicovideo.email', 'get_email via env';
        is $nnv->get_password, 'hahahaha', 'get_password via env';
    };
};

#-----------------------------------------------------------
# utils
#

# through_login
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('through_login'), 'can through_login');
};

# download
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('download'), 'can download');
};


#-----------------------------------------------------------
# fetch
# 

# fetch_thumbinfo
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('fetch_thumbinfo'), 'can fetch_thumbinfo');
};

# fetch_flv
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('fetch_flv'), 'can fetch_flv');
};

# fetch_watch
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('fetch_watch'), 'can fetch_watch');
};

# fetch_video
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('fetch_video'), 'can fetch_video');
};

# fetch_thread
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('fetch_thread'), 'can fetch_thread');
};


#-----------------------------------------------------------
# Tag RSS
# 

# fetch_tag_rss
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('fetch_tag_rss'), 'can fetch_tag_rss');
};


# fetch_tag_rss_by_recent_post
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('fetch_tag_rss_by_recent_post'), 'can fetch_tag_rss_by_recent_post');
};


#-----------------------------------------------------------
# Mylist RSS
# 

# fetch_mylist_rss
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('fetch_mylist_rss'), 'can fetch_mylist_rss');
};


#-----------------------------------------------------------
# Mylist Base
# 

# fetch_mylist_page
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('fetch_mylist_page'), 'can fetch_mylist_page');
};

# fetch_mylist_item
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('fetch_mylist_item'), 'can fetch_mylist_item');
};


#-----------------------------------------------------------
# NicoAPI.MylistGroup
# 

# list_mylistgroup
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('list_mylistgroup'), 'can list_mylistgroup');
};

# get_mylistgroup
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('get_mylistgroup'), 'can get_mylistgroup');
};

# add_mylistgroup
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('add_mylistgroup'), 'can add_mylistgroup');
};

# update_mylistgroup
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('update_mylistgroup'), 'can update_mylistgroup');
};

# remove_mylistgroup
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('remove_mylistgroup'), 'can remove_mylistgroup');
};


#-----------------------------------------------------------
# NicoAPI.Mylist
# 

# list_mylist
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('list_mylist'), 'can list_mylist');
};

# add_mylist
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('add_mylist'), 'can add_mylist');
};

# update_mylist
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('update_mylist'), 'can update_mylist');
};

# remove_mylist
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('remove_mylist'), 'can remove_mylist');
};

# delete_mylist
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('delete_mylist'), 'can delete_mylist');
};

# move_mylist
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('move_mylist'), 'can move_mylist');
};

# copy_mylist
TODO: {
    local $TODO = "writing test";
    my $nnv = Net::NicoVideo->new;
    ok( $nnv->can('copy_mylist'), 'can copy_mylist');
};


done_testing();
1;
__END__
