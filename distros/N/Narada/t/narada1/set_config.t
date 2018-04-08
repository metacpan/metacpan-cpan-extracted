use lib 't'; use narada1::share; guard my $guard;

use Narada::Config qw( set_config get_config );


my @badvar = ('a b', qw( a:b $a a+b a\b ./ a/./b ../ a/../b dir/ version/ ));

throws_ok { set_config() }              qr/Usage:/,     'no params';
throws_ok { set_config(1) }             qr/Usage:/,     'not enough params';
throws_ok { set_config(1, 2, 3) }       qr/Usage:/,     'too many params';

throws_ok { set_config($_, q{}) }       qr/bad config:/i,
    "bad variable: $_"
    for @badvar;

ok(!-e 'config/test',       'no file');
set_config('test', q{});
ok(-e 'config/test',        'file created');
ok(-z 'config/test',        'file empty');

set_config('test', ' ');
ok(1 == -s 'config/test',   'file updated');

SKIP: {
    skip 'non-root user required', 2 if $< == 0;
    chmod 0, 'config' or die "chmod: $!";

    open my $olderr, '>&', \*STDERR                     or die "open: $!";
    open STDERR, '> /dev/null'                          or die "open: $!";
    throws_ok { set_config('dir/test', q{}) }   qr/mkdir|mkpath/,
        'mkdir bad permissions';
    open STDERR, '>&', $olderr                          or die "open: $!";

    throws_ok { set_config('test', q{}) }       qr/config\/test/,
        'rename bad permissions';

    chmod 0755, 'config' or die "chmod: $!";
}

my $value = "line1\nline2";
ok(!-e 'config/dir',            'no dir');
set_config('dir/dir2/test', $value);
ok(-d 'config/dir',             'dir created');
ok(-d 'config/dir/dir2',        'dir2 created');
ok(-s 'config/dir/dir2/test',   'file created');
is(get_config('dir/dir2/test'), $value, 'value ok');


done_testing();
