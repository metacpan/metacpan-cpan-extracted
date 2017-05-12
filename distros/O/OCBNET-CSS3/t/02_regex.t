# -*- perl -*-

use utf8;
use strict;
use warnings;

use Test::More tests => 50;
BEGIN { use_ok('OCBNET::CSS3::Regex::Base') };
BEGIN { use_ok('OCBNET::CSS3::Regex::Numbers') };
BEGIN { use_ok('OCBNET::CSS3::Regex::Background') };

use OCBNET::CSS3::Regex::Base qw(unwrapUrl wrapUrl $re_uri);

is    (unwrapUrl('url("test.png")'),             'test.png',         'unwrapUrl test #1');
is    (unwrapUrl('url(url("test.png"))'),        'test.png',         'unwrapUrl test #2');
is    (unwrapUrl("url(url('test.png'))"),        'test.png',         'unwrapUrl test #3');
is    (unwrapUrl('url(test.png)'),               'test.png',         'unwrapUrl test #4');

is    (wrapUrl('test.png'),               'url("test.png")',           'wrapUrl test #1');

is    (unquot('&#65;!'),                         'A!',                  'unquot test #1');
is    (unquot('.\\E9motion'),                    ".\xE9motion",         'unquot test #2');
is    (unquot('.\\E9 dition'),                   ".\xE9dition",         'unquot test #3');
is    (unquot('.\\0000E9dition'),                ".\xE9dition",         'unquot test #4');
is    (unquot('Vive la France&#xA0;!'),          "Vive la France\xA0!", 'unquot test #5');
is    (unquot('Vive la France&#160;!'),          "Vive la France\xA0!", 'unquot test #6');

use OCBNET::CSS3::Regex::Numbers qw(fromPx toPx);

is    (fromPx('2'),                 '2',             'fromPx test #1');
is    (fromPx('3 '),                '3',             'fromPx test #1');
is    (fromPx('3px '),              '3',             'fromPx test #1');
is    (fromPx('4px'),               '4',             'fromPx test #1');
is    (fromPx(' 5'),                '5',             'fromPx test #1');
is    (fromPx(' 5px'),              '5',             'fromPx test #1');
is    (fromPx(' foo'),              undef,           'fromPx test #1');
is    (fromPx(' 6 px'),             undef,           'fromPx test #1');

is    (toPx('2'),                   '2px',           'toPx test #1');
is    (toPx('3px'),                 '3px',           'toPx test #1');
is    (toPx(' 4px'),                '4px',           'toPx test #1');
is    (toPx(' 5 '),                 '5px',           'toPx test #1');
is    (toPx(' baz '),               undef,           'toPx test #1');

use OCBNET::CSS3::Regex::Background qw(fromPosition);

$@ = undef; eval { fromPosition('') };
like $@, qr/unknown background position/, "fromPosition errors on empty string";
$@ = undef; eval { fromPosition(' ') };
like $@, qr/unknown background position/, "fromPosition errors on empty string";
$@ = undef; eval { fromPosition('0%') };
like $@, qr/unknown background position/, "fromPosition errors on unknown input";
$@ = undef; eval { fromPosition('foobar') };
like $@, qr/unknown background position/, "fromPosition errors on unknown input";
$@ = undef; eval { fromPosition(' top') };
like $@, qr/unknown background position/, "fromPosition errors on unknown input";
$@ = undef; eval { fromPosition(' 42') };
like $@, qr/unknown background position/, "fromPosition errors on unknown input";
$@ = undef; eval { fromPosition('42 ') };
like $@, qr/unknown background position/, "fromPosition errors on unknown input";

is    (fromPosition(undef),                 '0',           'fromPosition test #1');
is    (fromPosition('99px'),                '99',          'fromPosition test #2');
is    (fromPosition('-3px'),                '-3',          'fromPosition test #3');
is    (fromPosition('left'),                '0',           'fromPosition test #4');
is    (fromPosition('top'),                 '0',           'fromPosition test #5');
is    (fromPosition('bottom'),              'bottom',      'fromPosition test #6');
is    (fromPosition('right'),               'right',       'fromPosition test #7');

use OCBNET::CSS3::Regex::Base qw(unquot last_match last_index);

is      ('url("test")' =~ $re_uri,      1,             'match uri test #1');
is      (last_match,                    'test',        'test last match #1');
is      (last_index,                    1,             'test last match #1');
is      ("url('test')" =~ $re_uri,      1,             'match uri test #2');
is      (last_match,                    'test',        'test last match #2');
is      (last_index,                    2,             'test last match #2');
is      ('url(test)' =~ $re_uri,        1,             'match uri test #3');
is      (last_match,                    'test',        'test last match #3');
is      (last_index,                    3,             'test last match #3');
