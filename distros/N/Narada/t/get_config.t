use lib 't'; use share; guard my $guard;

use Narada::Config qw( get_config );


my @badvar = ('a b', qw( a:b $a a+b a\b ./ a/./b ../ a/../b . .. a/.. a/. dir/ version/ ));

throws_ok { get_config() }          qr/Usage:/,     'no params';
throws_ok { get_config(1, 2) }      qr/Usage:/,     'too many params';

throws_ok { get_config($_) }        qr/bad config:/i,
    "bad variable: $_"
    for @badvar;

throws_ok { get_config($_) }        qr/no such file/i,
    "no such file: $_"
    for qw( no_file no_dir/no_file backup/no-file );

SKIP: {
    skip 'non-root user required', 1 if $< == 0;
    chmod 0, 'config/log/level';
    throws_ok { get_config('log/level') } qr/permission/i,
        "bad permissions";
    chmod 0644, 'config/log/level';
}

like get_config('log/level'), qr/\w/,
    'read log/level';

Echo('config/empty', q{});
is get_config('empty'), q{}, 'empty';
Echo('config/test', "test\n");
is get_config('test'), "test\n", 'single line with \n';
Echo('config/test-n', "test");
is get_config('test-n'), "test", 'single line without \n';
Echo('config/test_multi', "test\ntest2\n");
is get_config('test_multi'), "test\ntest2\n", 'multi line';
mkdir 'config/testdir' or die "mkdir: $!";
Echo('config/testdir/test', "testdir\n");
is get_config('testdir/test'), "testdir\n", 'variable in directory';


done_testing();


sub Echo {
    my ($file, $data) = @_;
    open my $fh, '>', $file or die "open: $!";
    print {$fh} $data;
    close $fh or die "close: $!";
    return;
}
