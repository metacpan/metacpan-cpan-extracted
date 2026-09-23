#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Path::Tiny 'path';
use lib 'lib';
use Module::Build::SysPath;

my $temporary = Path::Tiny->tempdir('syspath-spc-rewrite-XXXXXXXX');

subtest 'safe complete-accessor rewriting' => sub {
    my $source = $temporary->child('source.pm');
    my $installed = $temporary->child('installed.pm');
    my %paths = (
        prefix     => path('/opt', q{O'Reilly-$HOME-@INC}, 'etc')->stringify,
        sysconfdir => path(q{/opt/back\slash/etc})->stringify,
        datadir    => path('/srv/multiline/data')->stringify,
        docdir     => path('/srv/indented/doc')->stringify,
        localedir  => path('/srv', "snowman-\x{2603}")->stringify,
    );
    my $builder = bless {
        properties => { spc => { path => \%paths } },
    }, 'Module::Build::SysPath';

    $source->spew(<<'PERL');
package R207::Generated;
use strict;
use warnings;

sub prefix { '/before/prefix' };
sub sysconfdir { '/before/sysconfdir' };
sub datadir
{
    return '/before/datadir';
}
    sub docdir {
        '/before/docdir'
    };
sub localedir { '/before/localedir' };

1;
PERL
    $source->copy($installed);

    $builder->_rewrite_installed_spc(
        $source->stringify,
        $installed->stringify,
        'prefix|sysconfdir|datadir|docdir|localedir',
    );

    my $compile_pid = open(
        my $compile_fh, '-|', $^X, '-c', $installed->stringify,
    );
    die $! if not defined $compile_pid;
    local $/;
    my $compile_output = <$compile_fh>;
    close($compile_fh);
    is($?, 0, 'rewritten module compiles') or diag($compile_output || '');

    my $loaded = do $installed->stringify;
    ok($loaded, 'rewritten module loads') or diag($@ || $!);
    SKIP: {
        skip 'rewritten module did not load', 5 if not $loaded;
        is(R207::Generated->prefix, $paths{prefix},
            'apostrophe and interpolation sigils are returned exactly');
        is(R207::Generated->sysconfdir, $paths{sysconfdir},
            'backslash path is returned exactly');
        is(R207::Generated->datadir, $paths{datadir},
            'multiline accessor returns the exact path');
        is(R207::Generated->docdir, $paths{docdir},
            'indented accessor returns the exact path');
        is(R207::Generated->localedir, $paths{localedir},
            'Unicode path is returned exactly');
    }
};

subtest 'unsupported accessors preserve the installed module' => sub {
    my $unsupported = $temporary->child('unsupported.pm');
    my $preserved = $temporary->child('preserved.pm');
    my $builder = bless {
        properties => { spc => { path => { prefix => '/new/prefix' } } },
    }, 'Module::Build::SysPath';

    $unsupported->spew(<<'PERL');
package R207::Unsupported;
sub prefix {
    if (1) {
        return '/before/prefix';
    }
}
1;
PERL
    my $original_installed = "original installed bytes\n";
    $preserved->spew($original_installed);

    my $rewritten = eval {
        $builder->_rewrite_installed_spc(
            $unsupported->stringify,
            $preserved->stringify,
            'prefix',
        );
        1;
    };
    ok(!$rewritten, 'unsupported accessor formatting is rejected');
    like($@, qr/unsupported SPc accessor 'prefix'/,
        'rejection identifies the unsupported accessor');
    is($preserved->slurp, $original_installed,
        'rejection leaves the installed module intact');
};

done_testing;
