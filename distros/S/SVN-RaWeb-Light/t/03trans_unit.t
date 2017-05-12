#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 7;

use lib './t/lib';

# We need to load the mocking modules first because they fill the
# namespaces and %INC. Otherwise, "use CGI" and "use SVN::*" will cause
# the real modules to be loaded.
use SVN::RaWeb::Light::Mock::CGI;
use SVN::RaWeb::Light::Mock::Svn;
use SVN::RaWeb::Light::Mock::Stdout;

use SVN::RaWeb::Light;

sub mytest
{
    my (%args) = (@_);
    my $cgi_params = $args{'cgi'} || {};
    my $is_list_item = $args{'is_list_item'};
    my $url_trans = $args{'url_translations'};
    my $results = $args{'results'};
    my $msg = $args{'msg'};

    @CGI::new_params =
    (
        'path_info' => "/trunk/hello/",
        'params' => $cgi_params,
    );

    my $svn_raweb =
        SVN::RaWeb::Light->new(
            'url_translations' => $url_trans
        );

    is_deeply(
        $svn_raweb->_get_url_translations(
            'is_list_item' => $is_list_item,
        ),
        $results,
        $msg
    );
}

# TEST
mytest(
    'is_list_item' => 0,
    'url_translations' =>
    [
        {
            'label' => "Read-Only",
            'url' => "svn://svn.myhost.mytld/hello/there/",
        },
        {
            'label' => "Write",
            'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
        },
    ],
    'msg' => "Basic Test - No CGI",
    'results' =>
    [
        {
            'label' => "Read-Only",
            'url' => "svn://svn.myhost.mytld/hello/there/",
        },
        {
            'label' => "Write",
            'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
        },
    ],
);

# TEST
mytest(
    'msg' => "With trans_hide_all CGI",
    'cgi' => { 'trans_hide_all' => 1, },
    'is_list_item' => 0,
    'url_translations' =>
    [
        {
            'label' => "Read-Only",
            'url' => "svn://svn.myhost.mytld/hello/there/",
        },
        {
            'label' => "Write",
            'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
        },
    ],
    'results' =>
    [
    ],
);

# TEST
mytest(
    'msg' => "With trans_hide_all CGI and some user-specified translations",
    'cgi' => { 'trans_hide_all' => 1,
        'trans_user' => [
            'MyUrl,https://yoohoo.yoo/hoo/',
            'svn://soohoo.mon/mandarin/',
        ],},
    'is_list_item' => 0,
    'url_translations' =>
    [
        {
            'label' => "Read-Only",
            'url' => "svn://svn.myhost.mytld/hello/there/",
        },
        {
            'label' => "Write",
            'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
        },
    ],
    'results' =>
    [
        {
            'label' => "MyUrl",
            'url' => "https://yoohoo.yoo/hoo/",
        },
        {
            'label' => "UserDef2",
            'url' => 'svn://soohoo.mon/mandarin/',
        },
    ],
);

# TEST
mytest(
    'msg' => "Some pre-defined and some user-specified translations",
    'cgi' => {
        'trans_user' => [
            'MyUrl,https://yoohoo.yoo/hoo/',
            'svn://soohoo.mon/mandarin/',
        ],},
    'is_list_item' => 0,
    'url_translations' =>
    [
        {
            'label' => "Read-Only",
            'url' => "svn://svn.myhost.mytld/hello/there/",
        },
        {
            'label' => "Write",
            'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
        },
    ],
    'results' =>
    [
        {
            'label' => "Read-Only",
            'url' => "svn://svn.myhost.mytld/hello/there/",
        },
        {
            'label' => "Write",
            'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
        },
        {
            'label' => "MyUrl",
            'url' => "https://yoohoo.yoo/hoo/",
        },
        {
            'label' => "UserDef2",
            'url' => 'svn://soohoo.mon/mandarin/',
        },
    ],
);

# TEST
mytest(
    'msg' => "Check no-hiding of trans_no_list to the main URLs",
    'cgi' => {
        'trans_user' => [
            'MyUrl,https://yoohoo.yoo/hoo/',
            'svn://soohoo.mon/mandarin/',
        ],
        'trans_no_list' => 1,
    },
    'is_list_item' => 0,
    'url_translations' =>
    [
        {
            'label' => "Read-Only",
            'url' => "svn://svn.myhost.mytld/hello/there/",
        },
        {
            'label' => "Write",
            'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
        },
    ],
    'results' =>
    [
        {
            'label' => "Read-Only",
            'url' => "svn://svn.myhost.mytld/hello/there/",
        },
        {
            'label' => "Write",
            'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
        },
        {
            'label' => "MyUrl",
            'url' => "https://yoohoo.yoo/hoo/",
        },
        {
            'label' => "UserDef2",
            'url' => 'svn://soohoo.mon/mandarin/',
        },
    ],
);

# TEST
mytest(
    'msg' => "Check hiding of is_list_item",
    'cgi' => {
        'trans_user' => [
            'MyUrl,https://yoohoo.yoo/hoo/',
            'svn://soohoo.mon/mandarin/',
        ],
        'trans_no_list' => 1,
    },
    'is_list_item' => 1,
    'url_translations' =>
    [
        {
            'label' => "Read-Only",
            'url' => "svn://svn.myhost.mytld/hello/there/",
        },
        {
            'label' => "Write",
            'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
        },
    ],
    'results' =>
    [
    ],
);

# TEST
mytest(
    'msg' => "Check that a list item gets all URLs when CGI::trans_no_list is not specified",
    'cgi' => {
        'trans_user' => [
            'MyUrl,https://yoohoo.yoo/hoo/',
            'svn://soohoo.mon/mandarin/',
        ],
    },
    'is_list_item' => 1,
    'url_translations' =>
    [
        {
            'label' => "Read-Only",
            'url' => "svn://svn.myhost.mytld/hello/there/",
        },
        {
            'label' => "Write",
            'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
        },
    ],
    'results' =>
    [
        {
            'label' => "Read-Only",
            'url' => "svn://svn.myhost.mytld/hello/there/",
        },
        {
            'label' => "Write",
            'url' => "svn+ssh://svnwrite.myhost.mytld/root/myroot/",
        },
        {
            'label' => "MyUrl",
            'url' => "https://yoohoo.yoo/hoo/",
        },
        {
            'label' => "UserDef2",
            'url' => 'svn://soohoo.mon/mandarin/',
        },
    ],
);

