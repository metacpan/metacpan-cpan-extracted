use lib 't'; use share; guard my $guard;
use Test::Differences;


my $TAR = (grep {-x "$_/gtar"} split /:/, $ENV{PATH}) ? 'gtar' : 'tar';

umask 0022;
my $dir1 = narada_new();
my $dir2 = narada_new();

# $dir1 is test directory
# $dir2 is etalon directory
for my $dir ($dir1, $dir2) {
    filldir($dir);
    system("
        cd \Q$dir\E
        echo val > config/var   &&
        touch var/data          &&
        echo test >> var/log/current
    ") == 0 or die "system: $?";
}
filldir("$dir1/tmp/");
filldir("$dir1/.backup/");


is system("cd \Q$dir1\E; narada-backup"), 0, 'first backup';
ok -e "$dir1/.backup/full.tar", 'full.tar created';
ok ! -e "$dir1/.backup/incr.tar", 'incr.tar not created';
check_backup("$dir1/.backup/full.tar");
system("cd \Q$dir1\E; cp .backup/full.tar tmp/full1.tar") == 0 or die "system: $?";

my $old_size = -s "$dir1/.backup/full.tar";
is system("cd \Q$dir1\E; narada-backup"), 0, 'second backup';
# XXX incremental archives was disabled
# ok $old_size < -s "$dir1/.backup/full.tar", 'full.tar grow up';
# ok -e "$dir1/.backup/incr.tar", 'incr.tar created';
# system("cd \Q$dir1\E; cp .backup/incr.tar tmp/incr1.tar") == 0 or die "system: $?";

sleep 1;    # tar will detect changes based on mtime
for my $dir ($dir1, $dir2) {
    mkdir "$dir/var/some" or die "mkdir: $!";
    filldir("$dir/var/some/");
    system("
        cd \Q$dir\E         &&
        rm config/var       &&
        rmdir .hiddendir    &&
        chmod 0712 var/data
    ");
}
mkdir "$dir1/tmp/some" or die "mkdir: $!";
filldir("$dir1/tmp/some/");
system("cd \Q$dir1\E && rm tmp/some/file && rmdir tmp/some/.hiddendir");

is system("cd \Q$dir1\E; narada-backup"), 0, 'third backup';
# XXX incremental archives was disabled
# system("cd \Q$dir1\E; cp .backup/incr.tar tmp/incr2.tar") == 0 or die "system: $?";
SKIP: {
    skip 'unstable on CPAN Testers', 2 if !$ENV{RELEASE_TESTING} && ($ENV{AUTOMATED_TESTING} || $ENV{PERL_CPAN_REPORTER_CONFIG});
    check_backup("$dir1/.backup/full.tar");
    # XXX incremental archives was disabled
    # check_backup("$dir1/tmp/full1.tar", "$dir1/tmp/incr1.tar", "$dir1/tmp/incr2.tar");
}
unlink "$dir1/.backup/full.tar";
is system("cd \Q$dir1\E; narada-backup"), 0, 'force full backup';
ok -e "$dir1/.backup/full.tar", 'full.tar created';
ok ! -e "$dir1/.backup/incr.tar", 'incr.tar not created';


done_testing();


sub narada_new {
    my $dir = tempdir('narada.project.XXXXXX');
    chdir $dir                                          or die "chdir($dir): $!";
    dircopy(wd()."/t/.release", "$dir/.release")        or die "dircopy: $!";
    system('narada-install 0.1.0 >/dev/null 2>&1') == 0 or die "narada-install 0.1.0 failed";
    chdir q{/};
    return $dir;
}

sub filldir {
    my ($dir) = @_;
    system("
        cd \Q$dir\E             &&
        touch .hidden           &&
        echo ok > file          &&
        mkdir .hiddendir        &&
        mkdir dir               &&
        echo ok > dir/file      &&
        touch dir/.hidden
    ") == 0 or die "system: $?";
    return;
}

sub check_backup {
    my (@files) = @_;
    my $dir = tempdir('narada.project.XXXXXX');
    chdir $dir or die "chdir: $!";
    for my $file (@files) {
        system("$TAR -x -p -g /dev/null -f \Q$file\E >/dev/null 2>&1");
    }
    # looks like dir size on raiserfs differ and break this test (ext3 works ok)
    SKIP: {
        skip 'GNU find required', 1 if `find --version 2>/dev/null` !~ /GNU/ms;
        my $wait = `
            cd \Q$dir2\E
            find \\! -path './.release/*' \\! -path './.lock*' -type d -printf "%M        %p %l\n" | sort
            find \\! -path './.release/*' \\! -path './.lock*' -type f -printf "%M %6s %p %l\n" | sort
            `;
        my $list = `
            find -type d -printf "%M        %p %l\n" | sort
            find -type f -printf "%M %6s %p %l\n" | sort
            `;
        eq_or_diff $list, $wait, 'backup contents ok';
    }
    chdir q{/};
    return;
}
