use strict;
use warnings;

use Test::Most;

use autodie;
use Cwd qw( abs_path );
use File::Basename qw( dirname );
use File::HomeDir;
use File::Slurp qw( read_file );
use File::Temp qw( tempdir );
use Path::Class qw( dir );
use Silki::Config;

my $dir = tempdir( CLEANUP => 1 );

$ENV{HARNESS_ACTIVE}       = 0;
$ENV{SILKI_CONFIG_TESTING} = 1;

{
    my $config = Silki::Config->new();

    is_deeply(
        $config->_raw_config(),
        {},
        'config hash is empty by default'
    );
}

{
    my $config = Silki::Config->new();

    is(
        $config->secret, 'a big secret',
        'secret has a basic default in dev environment'
    );
}

{
    local $ENV{SILKI_CONFIG} = '/path/to/nonexistent/file.conf';

    throws_ok(
        sub { Silki::Config->new() },
        qr/\QNonexistent config file in SILKI_CONFIG env var/,
        'SILKI_CONFIG pointing to bad file throws an error'
    );
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $file = "$dir/silki.conf";
    open my $fh, '>', $file;
    print {$fh} <<'EOF';
[Silki]
secret = foobar
EOF
    close $fh;

    {
        local $ENV{SILKI_CONFIG} = $file;

        my $config = Silki::Config->new();

        is_deeply(
            $config->_raw_config(), {
                Silki => { secret => 'foobar' },
            },
            'config hash uses data from file in SILKI_CONFIG'
        );
    }

    open $fh, '>', $file;
    print {$fh} <<'EOF';
[Silki]
is_production = 1
EOF
    close $fh;

    {
        local $ENV{SILKI_CONFIG} = $file;

        throws_ok(
            sub { Silki::Config->new() },
            qr/\QYou must supply a value for [Silki] - secret when running Silki in production/,
            'If is_production is true in config, there must be a secret defined'
        );
    }

    open $fh, '>', $file;
    print {$fh} <<'EOF';
[Silki]
is_production = 1
secret = foobar
EOF
    close $fh;

    {
        local $ENV{SILKI_CONFIG} = $file;

        my $config = Silki::Config->new();

        is_deeply(
            $config->_raw_config(), {
                Silki => {
                    secret        => 'foobar',
                    is_production => 1,
                },
            },
            'config hash with is_production true and a secret defined'
        );
    }
}

{
    my $config = Silki::Config->new();

    ok( $config->serve_static_files(), 'by default we serve static files' );

    $config = Silki::Config->new();

    $config->_set_is_production(1);

    ok(
        !$config->serve_static_files(),
        'does not serve static files in production'
    );

    $config = Silki::Config->new();

    $config->_set_is_production(0);

    $config->_set_is_profiling(1);

    ok(
        !$config->serve_static_files(),
        'does not serve static files when profiling'
    );

    $config = Silki::Config->new();

    $config->_set_is_profiling(0);

    {
        local $ENV{MOD_PERL} = 1;

        ok(
            !$config->serve_static_files(),
            'does not serve static files under mod_perl'
        );
    }
}

{
    my $config = Silki::Config->new();

    is(
        $config->is_profiling(), 0,
        'is_profiling defaults to false'
    );
}

{
    local $INC{'Devel/NYTProf.pm'} = 1;

    my $config = Silki::Config->new();

    is(
        $config->is_profiling(), 1,
        'is_profiling defaults is true if Devel::NYTProf is loaded'
    );
}

{
    my $config = Silki::Config->new();

    my $home_dir = dir( File::HomeDir->my_home() );

    is(
        $config->var_lib_dir(),
        $home_dir->subdir( '.silki', 'var', 'lib' ),
        'var lib dir defaults to $HOME/.silki/var/lib'
    );

    is(
        $config->share_dir(),
        dir( dirname( abs_path($0) ), '..', '..', 'share' )->resolve(),
        'share dir defaults to $CHECKOUT/share'
    );

    is(
        $config->etc_dir(),
        $home_dir->subdir( '.silki', 'etc' ),
        'etc dir defaults to $HOME/.silki/etc'
    );

    is(
        $config->cache_dir(),
        $home_dir->subdir( '.silki', 'cache' ),
        'cache dir defaults to $HOME/.silki/cache'
    );

    is(
        $config->files_dir(),
        $home_dir->subdir( '.silki', 'cache', 'files' ),
        'files dir defaults to $HOME/.silki/cache/files'
    );

    is(
        $config->thumbnails_dir(),
        $home_dir->subdir( '.silki', 'cache', 'thumbnails' ),
        'thumbnails dir defaults to $HOME/.silki/cache/thumbnails'
    );
}

{
    my $config = Silki::Config->new();

    $config->_set_is_production(1);

    no warnings 'redefine';
    local *Silki::Config::_ensure_dir = sub {return};

    is(
        $config->var_lib_dir(),
        '/var/lib/silki',
        'var lib dir defaults to /var/lib/silki in production'
    );

    my $share_dir = dir(
        dir( $INC{'Silki/Config.pm'} )->parent(),
        'auto', 'share', 'dist',
        'Silki'
    )->absolute()->cleanup();

    is(
        $config->share_dir(),
        $share_dir,
        'share dir defaults to /usr/local/share/silki in production'
    );

    is(
        $config->etc_dir(),
        '/etc/silki',
        'etc dir defaults to /etc/silki in production'
    );

    is(
        $config->cache_dir(),
        '/var/cache/silki',
        'cache dir defaults to /var/cache/silki in production'
    );

    is(
        $config->files_dir(),
        '/var/cache/silki/files',
        'files dir defaults to /var/cache/silki/files in production'
    );

    is(
        $config->thumbnails_dir(),
        '/var/cache/silki/thumbnails',
        'thumbnails dir defaults to /var/cache/silki/thumbnails in production'
    );
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $file = "$dir/silki.conf";
    open my $fh, '>', $file;
    print {$fh} <<'EOF';
[dirs]
var_lib = /foo/var/lib
share   = /foo/share
cache   = /foo/cache
EOF
    close $fh;

    no warnings 'redefine';
    local *Silki::Config::_ensure_dir = sub {return};

    {
        local $ENV{SILKI_CONFIG} = $file;

        my $config = Silki::Config->new();

        is(
            $config->var_lib_dir(),
            dir('/foo/var/lib'),
            'var lib dir defaults gets /foo/var/lib from file'
        );

        is(
            $config->share_dir(),
            dir('/foo/share'),
            'share dir defaults gets /foo/share from file'
        );

        is(
            $config->cache_dir(),
            dir('/foo/cache'),
            'cache dir defaults gets /foo/cache from file'
        );
    }
}

{
    my $config = Silki::Config->new();

    is_deeply(
        $config->database_connection(), {
            dsn      => 'dbi:Pg:dbname=Silki',
            username => q{},
            password => q{},
        },
        'default database config'
    );
}

{
    my $dir = tempdir( CLEANUP => 1 );
    my $file = "$dir/silki.conf";
    open my $fh, '>', $file;
    print {$fh} <<'EOF';
[database]
name = Foo
host = example.com
port = 9876
username = user
password = pass
EOF
    close $fh;

    local $ENV{SILKI_CONFIG} = $file;

    my $config = Silki::Config->new();

    is_deeply(
        $config->database_connection(), {
            dsn      => 'dbi:Pg:dbname=Foo;host=example.com;port=9876',
            username => 'user',
            password => 'pass',
        },
        'database config from file'
    );
}

{
    my $config = Silki::Config->new();

    my $dir = tempdir( CLEANUP => 1 );

    my $new_dir = dir($dir)->subdir('foo');

    $config->_ensure_dir($new_dir);

    ok( -d $new_dir, '_ensure_dir makes a new directory if needed' );
}

{
    my $dir = tempdir( CLEANUP => 1 );

    my $file = "$dir/silki.conf";

    my $config = Silki::Config->new();

    $config->write_config_file(
        file   => $file,
        values => {
            'database_name'     => 'Foo',
            'database_username' => 'fooer',
            'share_dir'         => '/path/to/share',
            'antispam_key'      => 'abcdef',
        },
    );

    my $content = read_file($file);
    like(
        $content, qr/\Q; Config file generated by Silki version \E.+/,
        'generated config file includes Silki version'
    );

    like(
        $content, qr/\Q; static =/,
        'generated config file does not set static'
    );

    like(
        $content, qr/\Qname = Foo/,
        'generated config file includes explicit set value for database name'
    );

    like(
        $content, qr/\Qusername = fooer/,
        'generated config file includes explicit set value for database username'
    );

    like(
        $content, qr/\[database\].+?name = Foo.+?username = fooer/s,
        'generated config file keys are in order defined by meta description'
    );

    like(
        $content, qr/\[Silki\].+?\[database\].+?\[antispam\]/s,
        'section order matches order of definition on Silki::Config'
    );
}

done_testing();
