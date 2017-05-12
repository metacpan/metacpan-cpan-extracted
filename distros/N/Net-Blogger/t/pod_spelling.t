#!perl -w
# $Id: pod_spelling.t 996 2005-12-03 01:37:51Z claco $
use strict;
use warnings;
use Test::More;

eval 'use Test::Spelling 0.11';
plan skip_all => 'Test::Spelling 0.11 not installed' if $@;
plan skip_all => 'set TEST_SPELLING to enable this test' unless $ENV{TEST_SPELLING};

set_spell_cmd('aspell list');

add_stopwords(<DATA>);

all_pod_files_spelling_ok();

__DATA__
API
Straup
UserLand
metaWeblog
postid
weblog
url
hashrefs
Slashcode
RPC
MovableType
dateCreated
categoryId
datetime
isPrimary
pingIP
pingTitle
pingURL
userid
postbody
blogName
Blogger
NumberOfPosts
blogs
chunked
blog
blogid
hostname
CPAN
PostFromFile
OPML
outliner
posttype
GetBlogId
XMLRPC
appkey
username
RadioUserland
blogname
editPost
newPost
postid
archiveIndex
automagic
Pyra
blogger
deletePost
getPost
postids
numposts
login
getRecentPost
getUsersBlogs
OOP
Userland
CDTF
Woot
asc
Movabletype
RadioUserLand
Kittle's
SLASHCODE
tid
ish
numberOfPosts
