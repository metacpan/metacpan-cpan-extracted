use strict;
use warnings;
use Test::More 0.88;
use JSON;
use File::Spec;

use PGXN::Meta::Validator;

my $json = do {
    my $file = File::Spec->catfile(qw(t META.json));
    local $/;
    open my $fh, '<:raw', $file or die "Cannot open $file: $!\n";
    <$fh>;
};

# Valid metadata.
for my $spec (
    ['unchanged'       => sub { } ],
    ['maintainer string' => sub { shift->{maintainer} = 'David Wheeler <theory@pgxn.org>' }],
    (map {
        my $l = $_;
        ["license $l" => sub { shift->{license} = $l }],
    } qw(
        agpl_3
        apache_1_1
        apache_2_0
        artistic_1
        artistic_2
        bsd
        freebsd
        gfdl_1_2
        gfdl_1_3
        gpl_1
        gpl_2
        gpl_3
        lgpl_2_1
        lgpl_3_0
        mit
        mozilla_1_0
        mozilla_1_1
        openssl
        perl_5
        postgresql
        qpl_1_0
        ssleay
        sun
        zlib
        open_source
        restricted
        unrestricted
        unknown
    )),
    ['multiple licenses' => sub { shift->{license} = [qw(postgresql perl_5)] }],
    ['license hash' => sub { shift->{license} = { foo => 'http://foo.com' } }],
    ['multilicense hash' => sub { shift->{license} = {
        foo => 'http://foo.com',
        bar => 'http://bar.com',
    } }],
    ['provides docfile' => sub { shift->{provides}{pgtap}{docfile} = 'foo/bar.txt' }],
    ['provides no abstract' => sub { delete shift->{provides}{pgtap}{abstract} }],
    ['provides custom key' => sub { shift->{provides}{pgtap}{x_foo} = 1 }],
    ['no spec url' => sub { delete shift->{'meta-spec'}{url} }],
    ['meta-spec custom key' => sub { shift->{'meta-spec'}{x_foo} = 1 }],
    ['multibyte name' => sub { shift->{name} = 'yoŭknow'}],
    ['name with dash' => sub { shift->{name} = 'foo-bar' }],
    ['no generated_by' => sub { delete shift->{generated_by} }],
    ['one tag' => sub { shift->{tags} = 'foo' }],
    ['no tags' => sub { shift->{tags} = [] }],
    ['no index file' => sub { shift->{no_index}{file} = ['foo']} ],
    ['no index empty file' => sub { shift->{no_index}{file} = []} ],
    ['no index file string' => sub { shift->{no_index}{file} = 'foo'} ],
    ['no index directory' => sub { shift->{no_index}{directory} = ['foo']} ],
    ['no index empty directory' => sub { shift->{no_index}{directory} = []} ],
    ['no index directory string' => sub { shift->{no_index}{directory} = 'foo'} ],
    ['no index file and directory' => sub { shift->{no_index} = {
        file => [qw(foo bar)],
        directory => 'baz',
    }}],
    ['no index custom key' => sub { shift->{no_index}{X_foo} = 1 }],
    (map {
        my $phase = $_;
        map {
            my $rel = $_;
            [
                "$phase $rel prereq",
                sub { my $m = shift; $m->{prereqs}{$phase}{$rel} = { foo => '1.2.0' }},
            ]
        } qw(requires recommends suggests conflicts);
    } qw(configure runtime build test develop)),
    (map {
        my $op = $_;
        [
            "version range with $op operator",
            sub { shift->{prereqs}{runtime}{requires}{PostgreSQL} = "$op 1.8.0"},
        ],
        [
            "version range with unspaced $op operator",
            sub { shift->{prereqs}{runtime}{requires}{PostgreSQL} = "${op}1.8.0"},
        ],
    } qw(== != < <= > >=)),
    [
        'prereq complex version range',
        sub { shift->{prereqs}{runtime}{requires}{PostgreSQL} = '>= 1.2.0, != 1.5.0, < 2.0.0'},
    ],
    [
        'prereq complex unspaced version range',
        sub { shift->{prereqs}{runtime}{requires}{PostgreSQL} = '>=1.2.0,!=1.5.0,<2.0.0'},
    ],
    [
        'prereq version 0',
        sub { shift->{prereqs}{runtime}{requires}{PostgreSQL} = 0 },
    ],
    [
        'no release status',
        sub { delete shift->{release_status} },
    ],
    (map {
        my $rel = $_;
        [
            "release status $rel",
            sub { shift->{release_status} = $rel },
        ],
    } qw(stable testing unstable)),
    [
        'no resources',
        sub { delete shift->{resources} },
    ],
    [
        'homepage resource',
        sub { shift->{resources}{homepage} = 'http://foo.com' },
    ],
    [
        'bugtracker resource',
        sub { shift->{resources}{bugtracker} = {
            web => 'http://example.com/',
            mailto => 'foo@bar.com',
        } },
    ],
    [
        'bugtracker web',
        sub { shift->{resources}{bugtracker} = {
            web => 'http://example.com/',
        } },
    ],
    [
        'bugtracker mailto',
        sub { shift->{resources}{bugtracker} = {
            mailto => 'foo@bar.com',
        } },
    ],
    [
        'bugtracker custom',
        sub { shift->{resources}{bugtracker} = {
            x_foo => 'foo',
        } },
    ],
    [
        'repository resource',
        sub { shift->{resources}{repository} = {
            web => 'http://example.com/',
            url => 'git://example.com/',
            type => 'git',
        } },
    ],
    [
        'repository resource url',
        sub { shift->{resources}{repository} = {
            url => 'git://example.com/',
            type => 'git',
        } },
    ],
    [
        'repository resource web',
        sub { shift->{resources}{repository} = {
            web => 'http://example.com/',
            type => 'git',
        } },
    ],
    [
        'repository custom',
        sub { shift->{resources}{repository} = {
            x_foo => 'foo',
        } },
    ],
) {
    my ($desc, $sub) = @{ $spec };
    my $dm = decode_json $json;
    $sub->($dm);
    my $pmv = PGXN::Meta::Validator->new($dm);
    ok $pmv->is_valid, "Should be valid with $desc"
        or diag "ERRORS:\n" . join "\n", $pmv->errors;
}

for my $spec (
    [
        'no name',
        sub { delete shift->{name} },
        "Required field /name: missing [Spec v1.0.0]",
    ],
    [
        'no version',
        sub { delete shift->{version} },
        "Required field /version: missing [Spec v1.0.0]",
    ],
    [
        'no abstract',
        sub { delete shift->{abstract} },
        "Required field /abstract: missing [Spec v1.0.0]",
    ],
    [
        'no maintainer',
        sub { delete shift->{maintainer} },
        "Required field /maintainer: missing [Spec v1.0.0]",
    ],
    [
        'no license',
        sub { delete shift->{license} },
        "Required field /license: missing [Spec v1.0.0]",
    ],
    [
        'no meta-spec',
        sub { delete shift->{'meta-spec'} },
        "Required field /meta-spec: missing [Spec v1.0.0]",
    ],
    [
        'no provides',
        sub { delete shift->{provides} },
        "Required field /provides: missing [Spec v1.0.0]",
    ],
    [
        'bad version',
        sub { shift->{version} = '1.0' },
        'Field /version: "1.0" is not a valid semantic version [Spec v1.0.0]',
    ],
    [
        'deprecated version',
        sub { shift->{version} = '1.0.0v1' },
        'Field /version: "1.0.0v1" is not a valid semantic version [Spec v1.0.0]',
    ],
    [
        'version zero',
        sub { shift->{version} = '0' },
        'Field /version: "0" is not a valid semantic version [Spec v1.0.0]',
    ],
    [
        'provides version 0',
        sub { shift->{provides}{pgtap}{version} = '0' },
        'Field /provides/pgtap/version: "0" is not a valid semantic version [Spec v1.0.0]',
    ],
    [
        'bad provides version',
        sub { shift->{provides}{pgtap}{version} = 'hi' },
        'Field /provides/pgtap/version: "hi" is not a valid semantic version [Spec v1.0.0]',
    ],
    [
        'bad prereq version',
        sub { shift->{prereqs}{runtime}{requires}{plpgsql} = '1.2b1' },
        'Field /prereqs/runtime/requires/plpgsql: "1.2b1" is not a valid semantic version [Spec v1.0.0]',
    ],
    [
        'invalid key',
        sub { shift->{foo} = 1 },
        'Field /foo: Unknown key; custom keys must begin with "x_" or "X_" [Spec v1.0.0]',
    ],
    [
        'invalid license',
        sub { shift->{license} = 'gobbledygook' },
        'Field /license: "gobbledygook" is an unknown license [Spec v1.0.0]',
    ],
    [
        'invalid licenses',
        sub { shift->{license} = [ 'bsd', 'gobbledygook' ] },
        'Field /license[1]: "gobbledygook" is an unknown license [Spec v1.0.0]',
    ],
    [
        'invalid license URL',
        sub { shift->{license} = { 'foo' => 'not a URL' } },
        'Field /license/foo: "not a URL" is not a valid URL [Spec v1.0.0]',
    ],
    [
        'second invalid license URL',
        sub { shift->{license} = { 'foo' => 'http://foo.com/', bar => 'not a URL' } },
        'Field /license/bar: "not a URL" is not a valid URL [Spec v1.0.0]',
    ],
    [
        'no provides file',
        sub { delete shift->{provides}{pgtap}{file} },
        'Required field /provides/pgtap/file: missing [Spec v1.0.0]',
    ],
    [
        'no provides version',
        sub { delete shift->{provides}{pgtap}{version} },
        'Required field /provides/pgtap/version: missing [Spec v1.0.0]',
    ],
    [
        'invalid provides version',
        sub { shift->{provides}{pgtap}{version} = '1.0' },
        'Field /provides/pgtap/version: "1.0" is not a valid semantic version [Spec v1.0.0]',
    ],
    [
        'provides array',
        sub { shift->{provides} = ['pgtap', '0.24.0' ]},
        'Field /provides: Should be a map structure [Spec v1.0.0]',
    ],
    [
        'undefined provides file',
        sub { shift->{provides}{pgtap}{file} = undef },
        'Required field /provides/pgtap/file: missing [Spec v1.0.0]',
    ],
    [
        'undefined provides abstract',
        sub { shift->{provides}{pgtap}{abstract} = undef },
        'Field /provides/pgtap/abstract: No value [Spec v1.0.0]',
    ],
    [
        'undefined provides version',
        sub { shift->{provides}{pgtap}{version} = undef },
        'Required field /provides/pgtap/version: missing [Spec v1.0.0]',
    ],
    [
        'undefined provides docfile',
        sub { shift->{provides}{pgtap}{docfile} = undef },
        'Field /provides/pgtap/docfile: No value [Spec v1.0.0]',
    ],
    [
        'bad provides custom key',
        sub { shift->{provides}{pgtap}{woot} = 'hi' },
        'Field /provides/pgtap/woot: Unknown key; custom keys must begin with "x_" or "X_" [Spec v1.0.0]',
    ],
    [
        'alt spec version',
        sub { shift->{'meta-spec'}{version} = '2.0.0' },
        "Unknown META specification, cannot validate. [Spec v2.0.0]",
    ],
    [
        'no spec version',
        sub { delete shift->{'meta-spec'}{version}; },
        'Required field /meta-spec/version: missing [Spec v1.0.0]',
    ],
    [
        'bad spec URL',
        sub { shift->{'meta-spec'}{url} = 'not a url' },
        'Field /meta-spec/url: "not a url" is not a valid URL [Spec v1.0.0]',
    ],
    [
        'name with newline',
        sub { shift->{name} = "foo\nbar" },
        qq{Field /name: "foo\nbar" is not a valid term [Spec v1.0.0]},
    ],
    [
        'name with return',
        sub { shift->{name} = "foo\rbar" },
        qq{Field /name: "foo\rbar" is not a valid term [Spec v1.0.0]},
    ],
    [
        'name with slash',
        sub { shift->{name} = "foo/bar" },
        'Field /name: "foo/bar" is not a valid term [Spec v1.0.0]',
    ],
    [
        'name with backslash',
        sub { shift->{name} = "foo\\bar" },
        'Field /name: "foo\\bar" is not a valid term [Spec v1.0.0]',
    ],
    [
        'name with space',
        sub { shift->{name} = "foo bar" },
        'Field /name: "foo bar" is not a valid term [Spec v1.0.0]',
    ],
    [
        'short name',
        sub { shift->{name} = "f" },
        'Field /name: term must be at least 2 characters [Spec v1.0.0]',
    ],
    [
        'undefined description',
        sub { shift->{description} = undef },
        'Field /description: No value [Spec v1.0.0]',
    ],
    [
        'undefined generated_by',
        sub { shift->{generated_by} = undef },
        'Field /generated_by: No value [Spec v1.0.0]',
    ],
    [
        'undef tag',
        sub { shift->{tags} = undef },
        'Field /tags: Should be a list structure [Spec v1.0.0]',
    ],
    [
        'empty tag',
        sub { shift->{tags} = '' },
        'Field /tags: "" is not a valid tag [Spec v1.0.0]',
    ],
    [
        'empty tag item',
        sub { shift->{tags} = ['', 'foo'] },
        'Field /tags[0]: "" is not a valid tag [Spec v1.0.0]',
    ],
    [
        'undef tag item',
        sub { shift->{tags} = ['foo', undef] },
        'Field /tags[1]: value is not defined [Spec v1.0.0]',
    ],
    [
        'long tag',
        sub { shift->{tags} = 'x' x 257 },
        'Field /tags: tag must be no more than 256 characters [Spec v1.0.0]',
    ],
    [
        'no_index empty file string',
        sub { shift->{no_index}{file} = '' },
        'Field /no_index/file: No value [Spec v1.0.0]',
    ],
    [
        'no_index undef file string',
        sub { shift->{no_index}{file} = undef },
        'Field /no_index/file: Should be a list structure [Spec v1.0.0]',
    ],
    [
        'no_index empty file array string',
        sub { shift->{no_index}{file} = [''] },
        'Field /no_index/file[0]: No value [Spec v1.0.0]',
    ],
    [
        'no_index undef file array string',
        sub { shift->{no_index}{file} = [undef] },
        'Field /no_index/file[0]: No value [Spec v1.0.0]',
    ],
    [
        'no_index empty directory string',
        sub { shift->{no_index}{directory} = '' },
        'Field /no_index/directory: No value [Spec v1.0.0]',
    ],
    [
        'no_index undef directory string',
        sub { shift->{no_index}{directory} = undef },
        'Field /no_index/directory: Should be a list structure [Spec v1.0.0]',
    ],
    [
        'no_index empty directory array string',
        sub { shift->{no_index}{directory} = [''] },
        'Field /no_index/directory[0]: No value [Spec v1.0.0]',
    ],
    [
        'no_index undef directory array string',
        sub { shift->{no_index}{directory} = [undef] },
        'Field /no_index/directory[0]: No value [Spec v1.0.0]',
    ],
    [
        'no_index bad key',
        sub { shift->{no_index}{foo} = ['hi'] },
        'Field /no_index/foo: Unknown key; custom keys must begin with "x_" or "X_" [Spec v1.0.0]',
    ],
    [
        'prereq undef version',
        sub { shift->{prereqs}{runtime}{requires}{PostgreSQL} = undef },
        'Field /prereqs/runtime/requires/PostgreSQL: No value [Spec v1.0.0]',
    ],
    [
        'prereq invalid version',
        sub { shift->{prereqs}{runtime}{requires}{PostgreSQL} = '1.0' },
        'Field /prereqs/runtime/requires/PostgreSQL: "1.0" is not a valid semantic version [Spec v1.0.0]',
    ],
    [
        'prereq invalid version op',
        sub { shift->{prereqs}{runtime}{requires}{PostgreSQL} = '= 1.0.0' },
        'Field /prereqs/runtime/requires/PostgreSQL: "=" is not a valid version range operator [Spec v1.0.0]',
    ],
    [
        'prereq wtf version op',
        sub { shift->{prereqs}{runtime}{requires}{PostgreSQL} = '*** 1.0.0' },
        'Field /prereqs/runtime/requires/PostgreSQL: "***" is not a valid version range operator [Spec v1.0.0]',
    ],
    [
        'prereq verersion leading comma',
        sub { shift->{prereqs}{runtime}{requires}{PostgreSQL} = ',1.0.0' },
        'Field /prereqs/runtime/requires/PostgreSQL: "" is not a valid semantic version [Spec v1.0.0]',
    ],
    [
        'invalid prereq phase',
        sub { shift->{prereqs}{howdy}{requires}{PostgreSQL} = '1.0.0' },
        'Field /prereqs/howdy: Unknown preqreq phase; must be one of configure, build, test, runtime, develop [Spec v1.0.0]'
    ],
    [
        'invalid prereq phase',
        sub { shift->{prereqs}{runtime}{wanking}{PostgreSQL} = '1.0.0' },
        'Field /prereqs/runtime/wanking: Unknown preqreq relationship; must be one of requires, recommends, suggests, conflicts [Spec v1.0.0]',
    ],
    [
        'non-map prereq',
        sub { shift->{prereqs}{runtime}{requires} = [ PostgreSQL => '1.0.0' ] },
        'Field /prereqs/runtime/requires: Should be a map structure [Spec v1.0.0]',
    ],
    [
        'non-term prereq',
        sub { shift->{prereqs}{runtime}{requires}{'foo/bar'} = '1.0.0' },
        'Field /prereqs/runtime/requires/foo/bar: "foo/bar" is not a valid term [Spec v1.0.0]',
    ],
    [
        'invalid release status',
        sub { shift->{release_status} = 'rockin' },
        'Field /release_status: "rockin" is not a valid release status; must be one of stable, testing, unstable [Spec v1.0.0]'
    ],
    [
        'undef release status',
        sub { shift->{release_status} = undef },
        'Field /release_status: "" is not a valid release status; must be one of stable, testing, unstable [Spec v1.0.0]',
    ],
    [
        'homepage resource undef',
        sub { shift->{resources}{homepage} = undef },
        'Field /resources/homepage: No value [Spec v1.0.0]',
    ],
    [
        'homepage resource non-url',
        sub { shift->{resources}{homepage} = 'hi' },
        'Field /resources/homepage: "hi" is not a valid URL [Spec v1.0.0]',
    ],
    [
        'bugtracker resource undef',
        sub { shift->{resources}{bugtracker} = undef },
        'Field /resources/bugtracker: Should be a map structure [Spec v1.0.0]',
    ],
    [
        'bugtracker resource array',
        sub { shift->{resources}{bugtracker} = ['hi'] },
        'Field /resources/bugtracker: Should be a map structure [Spec v1.0.0]',
    ],
    [
        'bugtracker empty invalid key',
        sub { shift->{resources}{bugtracker} = { foo => 1 } },
        'Field /resources/bugtracker/foo: Unknown key; custom keys must begin with "x_" or "X_" [Spec v1.0.0]',
    ],
    [
        'bugtracker invalid URL',
        sub { shift->{resources}{bugtracker} = { web => 'hi' } },
        'Field /resources/bugtracker/web: "hi" is not a valid URL [Spec v1.0.0]',
    ],
    [
        'bugtracker invalid email',
        sub { shift->{resources}{bugtracker} = { mailto => 'hi' } },
        'Field /resources/bugtracker/mailto: "hi" is not a valid email address [Spec v1.0.0]',
    ],
    [
        'repository resource undef',
        sub { shift->{resources}{repository} = undef },
        'Field /resources/repository: Should be a map structure [Spec v1.0.0]',
    ],
    [
        'repository resource array',
        sub { shift->{resources}{repository} = ['hi'] },
        'Field /resources/repository: Should be a map structure [Spec v1.0.0]',
    ],
    [
        'repository empty invalid key',
        sub { shift->{resources}{repository} = { foo => 1 } },
        'Field /resources/repository/foo: Unknown key; custom keys must begin with "x_" or "X_" [Spec v1.0.0]',
    ],
    [
        'repository invalid URL',
        sub { shift->{resources}{repository} = { url => 'hi' } },
        'Field /resources/repository/url: "hi" is not a valid URL [Spec v1.0.0]',
    ],
    [
        'repository invalid web URL',
        sub { shift->{resources}{repository} = { web => 'hi' } },
        'Field /resources/repository/web: "hi" is not a valid URL [Spec v1.0.0]',
    ],
    [
        'repository invalid type',
        sub { shift->{resources}{repository} = { type => 'Foo' } },
         'Field /resources/repository/type: "Foo" is not a lowercase string [Spec v1.0.0]'
    ],
) {
    my ($desc, $sub, $err) = @{ $spec };
    my $dm = decode_json $json;
    $sub->($dm);
    my $pmv = PGXN::Meta::Validator->new($dm);
    ok !$pmv->is_valid, "Should be invalid with $desc";
    is [$pmv->errors]->[0], $err, "Should get error for $desc";
}

done_testing;
