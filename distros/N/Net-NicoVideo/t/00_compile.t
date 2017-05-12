use strict;
use warnings;

use Test::More;

my @modules = qw(
Net::NicoVideo
Net::NicoVideo::Content
Net::NicoVideo::Content::Flv
Net::NicoVideo::Content::MylistItem
Net::NicoVideo::Content::MylistPage
Net::NicoVideo::Content::MylistRSS
Net::NicoVideo::Content::NicoAPI
Net::NicoVideo::Content::TagRSS
Net::NicoVideo::Content::Thread
Net::NicoVideo::Content::ThumbInfo
Net::NicoVideo::Content::Video
Net::NicoVideo::Content::Watch
Net::NicoVideo::Decorator
Net::NicoVideo::Request
Net::NicoVideo::Response
Net::NicoVideo::Response::Flv
Net::NicoVideo::Response::MylistItem
Net::NicoVideo::Response::MylistPage
Net::NicoVideo::Response::MylistRSS
Net::NicoVideo::Response::NicoAPI
Net::NicoVideo::Response::TagRSS
Net::NicoVideo::Response::Thread
Net::NicoVideo::Response::ThumbInfo
Net::NicoVideo::Response::Video
Net::NicoVideo::Response::Watch
Net::NicoVideo::URL
Net::NicoVideo::UserAgent
);

use_ok "$_" for ( @modules );


done_testing();
1;
__END__
