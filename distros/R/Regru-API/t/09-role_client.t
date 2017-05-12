use strict;
use warnings;
use Test::More tests => 3;
use Test::Fatal;

{
    # role consumer
    package Foo::Bar;

    use strict;
    use Moo;

    with 'Regru::API::Role::Client';

    has '+namespace' => (
        default => sub { 'dummy' },
    );

    sub available_methods {[qw(baz quux)]}

    __PACKAGE__->namespace_methods;
    __PACKAGE__->meta->make_immutable;

    1;
}

subtest 'Validate passed options' => sub {
    plan tests => 13;

    my $foo = new_ok 'Foo::Bar' => [(username => 'foo', password => 'bar')];

    my $failed;

    # I/O encodings
    is $foo->io_encoding('utf8'),       'utf8',                         'utf8 encoding is valid';
    is $foo->io_encoding('cp1251'),     'cp1251',                       'cp1251 encoding is valid';
    is $foo->io_encoding('cp866'),      'cp866',                        'cp866 encoding is valid';
    is $foo->io_encoding('koi8-r'),     'koi8-r',                       'koi8-r encoding is valid';
    is $foo->io_encoding('koi8-u'),     'koi8-u',                       'koi8-u encoding is valid';

    $failed = exception { $foo->io_encoding('utf-16') };
    like $failed, qr/^isa check .* Unsupported encoding: utf-16 .*/,    'utf-16 encoding throws an exception';

    $failed = exception { $foo->io_encoding('') };
    like $failed, qr/^isa check .* Empty encoding value .*/,            'empty encoding throws an exception';

    # Language
    is $foo->lang('en'),                'en',                           'EN (english) language is valid';
    is $foo->lang('ru'),                'ru',                           'RU (russian) language is valid';
    is $foo->lang('th'),                'th',                           'TH (thai) language is valid';

    $failed = exception { $foo->lang('es') };
    like $failed, qr/^isa check .* Unsupported language: es .*/,        'ES (Spanish) language throws an exception';

    $failed = exception { $foo->lang('') };
    like $failed, qr/^isa check .* Empty language value .*/,            'empty language throws an exception';
};

subtest 'Client role' => sub {
    plan tests => 10;

    my $foo = new_ok 'Foo::Bar' => [(username => 'foo', password => 'bar')];

    isa_ok $foo, 'Foo::Bar';

    # api methods
    can_ok $foo, qw(baz quux);

    # roles
    ok $foo->does('Regru::API::Role::UserAgent'),       'Instance does the UserAgent role';
    ok $foo->does('Regru::API::Role::Namespace'),       'Instance does the Namespace role';
    ok $foo->does('Regru::API::Role::Serializer'),      'Instance does the Serializer role';
    ok $foo->does('Regru::API::Role::Loggable'),        'Instance does the Loggable role';

    # applied by roles
    can_ok $foo, qw(useragent serializer debug_warn);

    # attributes
    can_ok $foo, qw(username password io_encoding lang debug namespace endpoint);

    # native methods
    can_ok $foo, qw(namespace_methods api_request to_namespace);
};

subtest 'Native methods' => sub {
    plan tests => 13;

    # save endpoint
    my $endpoint = $ENV{REGRU_API_ENDPOINT} || undef;

    $ENV{REGRU_API_ENDPOINT} = 'http://api.example.com/v2';

    my $foo = new_ok 'Foo::Bar' => [(username => 'foo', password => 'bar')];

    is          $foo->namespace,            'dummy',                    'Attribute namespace overwritten okay';
    is_deeply   $foo->available_methods,    [qw(baz quux)],             'Correct list of API methods';
    is          $foo->endpoint,             $ENV{REGRU_API_ENDPOINT},   'API endpoint spoofed okay';

    is          $foo->username('foo1'),     'foo1',                     'Attribute username RW okay';
    is          $foo->password('bar1'),     'bar1',                     'Attribute password RW okay';
    is          $foo->io_encoding('cp1251'),'cp1251',                   'Attribute io_encoding RW okay';
    is          $foo->lang('th'),           'th',                       'Attribute lang RW okay';
    is          $foo->debug(1),             1,                          'Attribute debug RW okay';

    is          $foo->to_namespace(),       '/dummy',                   'Missed namespace okay';
    is          $foo->to_namespace(undef),  '/dummy',                   'Undefined namespace passed okay';
    is          $foo->to_namespace(''),     '/dummy',                   'Empty namespace passed okay';
    is          $foo->to_namespace('foo'),  '/foo',                     'Namespace overwritten okay';

    # restore endpoint
    $ENV{REGRU_API_ENDPOINT} = $endpoint if $endpoint;
};

1;
