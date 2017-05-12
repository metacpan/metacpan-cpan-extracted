use t::narada1::share; guard my $guard;

require (wd().'/blib/script/narada-new-1');


umask 0022;
my $data_pos = tell DATA;
sub _main {
    seek DATA, $data_pos, 0;
    goto &main;
}

my $dst = tempdir('narada1.project.XXXXXX');


# Usage
throws_ok { _main(1, 2, 3) }             qr/Usage:/,  'too many params';

# Wrong destination
mkdir("$dst/somedir")                               or die "mkdir: $!";
throws_ok { _main($dst) }                qr/directory not empty/i;
rmdir "$dst/somedir"                                or die "rmdir: $!";
system("touch \Q$dst\E/somefile") == 0              or die "system: touch: $?";
throws_ok { _main($dst) }                qr/directory not empty/i;
throws_ok { _main("$dst/somefile") }     qr/not a directory/i;
unlink "$dst/somefile"                              or die "unlink: $!";

# Wrong destination permissions
SKIP: {
    skip 'non-root user required', 3 if $< == 0;
    chmod 0, $dst                                       or die "chmod: $!";
    throws_ok { _main($dst) }              qr/opendir:/;
    throws_ok { _main("$dst/somedir") }    qr/mkdir:/;
    chmod 0500, $dst                                    or die "chmod: $!";
    open my $olderr, '>&', \*STDERR                     or die "open: $!";
    open STDERR, '> /dev/null'                          or die "open: $!";
    throws_ok { _main($dst) }              qr/unpack failed/i;
    open STDERR, '>&', $olderr                          or die "open: $!";
    chmod 0700, $dst                                    or die "chmod: $!";
}

# OK - dir exists
lives_ok  { _main($dst) }              'all ok - dir exists';
chomp(my $version = `cat \Q$dst/config/version`);
$dst =~ m{([^/]+)\z};
is($version, "$1-0.0.000", 'version');

# OK - dir not exists
my $dst3 = tempdir('narada1.project.XXXXXX');
rmdir $dst3                                         or die "rmdir: $!";
lives_ok  { _main($dst3) }              'all ok - dir not exists';

# OK - current dir
my $dst4 = tempdir('narada1.project.XXXXXX');
chdir $dst4                                         or die "chdir: $!";
lives_ok  { _main() }                   'all ok - current dir';

$dst4 =~ m{([^/]+)\z};
ok(-s "var/patch/$1-0.0.000.tar",       'initial backup created');

is((stat 'config/version')[2] & 07777, 0644, 'config/version permissions');


chdir q{/};
done_testing();
