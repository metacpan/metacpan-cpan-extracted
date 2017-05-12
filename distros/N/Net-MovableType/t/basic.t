#!/usr/bin/perl

use strict;
use Test::More tests => 23;

BEGIN {
    $ENV{MT_USER}       ||= 'net-mt';
    $ENV{MT_PASSWORD}   ||= 'secret';
    $ENV{MT_PROXY}      ||='http://mt.handalak.com/cgi-bin/xmlrpc';
}

unless ( eval "require LWP::Simple") {
    print "1..0 # Skipped: LWP::Simple isn't available";
    exit(0);
}

use_ok("Net::MovableType");

#
# Making the connection
#
my $mt = new MovableType($ENV{MT_PROXY}, $ENV{MT_USER}, $ENV{MT_PASSWORD});
ok(defined $mt, ref $mt);

ok(($mt->username eq $ENV{MT_USER}) && ($mt->password eq $ENV{MT_PASSWORD}));

#
# Testing for getUsersBlogs() consistency
#
my $blogs = $mt->getUsersBlogs();

ok($blogs && (ref $blogs eq 'ARRAY') && (@$blogs ==1));
ok($blogs->[0]->{blogName} eq 'Net::MovableType');
ok($blogs->[0]->{blogid});
ok($blogs->[0]->{url} eq 'http://net-mt.handalak.com/');

unless ( $mt->blogId ) { $mt->blogId( $blogs->[0]->{blogid} ) }

#
# resolveBlogId('Net::MovableType')
#
ok($mt->resolveBlogId('Net::MovableType') == 14);


#
# newPost():
#
my %entry = (
    title       => "Hello World from Net::MovableType!",
    description => "Look ma, no hands!",
    mt_keywords => 'test AND Net::MovableType'
);


my $new_post_id = $mt->newPost(\%entry, 0);
ok($new_post_id, "New entry: $new_post_id");

$mt->setPostCategories($new_post_id, ["Testing..."]);
$mt->publishPost($new_post_id);

#
# getRecentPostTitles():
#
my $recentTitles = $mt->getRecentPostTitles(10);
ok( 
    grep { $_->{postid} == $new_post_id } @$recentTitles
);

while ( my $post = shift @$recentTitles ) {
    printf("[%02d] - %s\n", $post->{postid}, $post->{title});
}

my $recentPosts = $mt->getRecentPosts(10);
ok(
    grep { $_->{postid} == $new_post_id } @$recentPosts
);


#
# getPost():
#
my $post = $mt->getPost( $new_post_id );

ok($post->{title} eq "Hello World from Net::MovableType!");
ok($post->{postid} == $new_post_id );

$post->{title} = sprintf "%s (%d)", $post->{title}, $post->{postid};

#
# editPost():
#
ok($mt->editPost($post->{postid}, $post));

my $edited_post = $mt->getPost( $new_post_id );
ok($edited_post->{title} eq "Hello World from Net::MovableType! (" . $edited_post->{postid} . ")");


#
# deletePost():
#
ok($mt->deletePost($new_post_id));
ok($mt->getPost($new_post_id) ? 0 : 1);

#
# upload():
#

#
# first we create a simple post to associate this image with it:
#

require Config;
my $new_post_id_w_upload = $mt->newPost({
    title       => sprintf("Another %s computer got Net::MT! Do you?", $Config::Config{osname}),
    description => Config::myconfig(),
}, 0);
$mt->setPostCategories($new_post_id_w_upload, ["Testing..."]);

require LWP::Simple;
my $logo_content = LWP::Simple::get('http://author.handalak.com/images/perl.gif');

ok($logo_content, "logo downloaded");
my $url = $mt->upload(\$logo_content, sprintf "images/perl_%d.gif", $new_post_id_w_upload);

my ($type, $size, $modtime, $expires, $server) = LWP::Simple::head($url->{url});
ok($type eq 'image/gif');
ok($size > 1);


my $new_post_w_upload = $mt->getPost($new_post_id_w_upload);
ok($new_post_w_upload);

$new_post_w_upload->{description} .= <<ENDTEXTMORE;

<a href="http://www.perl.com/"><img src="$url->{url}" style="margin:5px;border:none" alt="Powered by Perl" /></a>
<i>Note:</i> above image was uploaded with Net::MovableType.

ENDTEXTMORE

ok($mt->editPost($new_post_id_w_upload, $new_post_w_upload));
ok($mt->publishPost($new_post_id_w_upload));

