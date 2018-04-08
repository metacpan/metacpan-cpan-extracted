use lib 't'; use narada1::share; guard my $guard;

require (wd().'/blib/script/narada-setup-qmail');


my ($d, $mode);
my $umask = umask;
setlocale(LC_ALL, 'C');


# - _readlink($link)
#   * throw on non-links
#   * return link content

$d = File::Temp::tempdir(CLEANUP => 1);
touch("$d/file");
symlink 'file', "$d/link"                       or die "symlink: $!";
symlink 'nofile', "$d/badlink"                  or die "symlink: $!";
symlink "$d/file", "$d/abslink"                 or die "symlink: $!";

throws_ok { _readlink("$d/file") }      qr/readlink.*Invalid argument/,
    '_readlink(file) throw';
is(_readlink("$d/link"), 'file',
    '_readlink(link)');
is(_readlink("$d/badlink"), 'nofile',
    '_readlink(badlink)');
is(_readlink("$d/abslink"), "$d/file",
    '_readlink(abslink)');

# - ls($dir)
#   * throw on non-dir
#   * throw on non-readable dir
#   * return relative file names for files of all types

$d = File::Temp::tempdir(CLEANUP => 1);
touch("$d/file");
mkdir "$d/dir", 0                               or die "mkdir($d/dir): $!";
symlink 'file', "$d/link"                       or die "symlink: $!";

throws_ok { ls("$d/file") }             qr/opendir.*Not a directory/,
    'ls(non-dir) throw';
SKIP: {
    skip 'non-root user required', 1 if $< == 0;
    throws_ok { ls("$d/dir") }              qr/opendir.*Permission denied/,
        'ls(non-readable dir) throw';
}
is_deeply [sort {$a cmp $b} ls($d)], [sort {$a cmp $b} qw(file dir link)],
    'ls() return relative files but not subdirectories';

chmod 0700, "$d/dir";   # allow File::Temp to do CLEANUP

# - replacefile($file, $data)
#   * require writable parent dir instead of writable $file to work:
#     . throw on non-writable parent dir while $file is writable
#     . works on non-writable $file in writable parent dir
#   * $file permissions will be 0600 with umask(0)
#   * $data placed into $file correctly:
#     . single line without \n
#     . single line with \n
#     . multiline without \n on last line
#     . multiline with \n on last line
#     . binary data 0x00-0xFF

$d = File::Temp::tempdir(CLEANUP => 1);
mkdir "$d/dir", 0                               or die "mkdir($d/dir): $!";
touch("$d/file");
chmod 0, "$d/file"                              or die "chmod($d/file): $!";

SKIP: {
    skip 'non-root user required', 1 if $< == 0;
    throws_ok { replacefile("$d/dir/file", q{}) }   qr/Parent directory.*is not writable|Permission denied/,
        'replacefile(non-writable dir) throw';
}
lives_ok  { replacefile("$d/file", q{}) }
    'replacefile(non-writable file)';

$mode = (stat("$d/file"))[2] & 07777;
is $mode, 0600,
    'replacefile: mode 0000 -> 0600';
umask 0;
replacefile("$d/file", q{});
$mode = (stat("$d/file"))[2] & 07777;
is $mode, 0600,
    'replacefile: mode 0600 with umask 0';
umask $umask;

my %data = (
    singlenoeol     => "line",
    single          => "line\n",
    multinoeol      => "line1\nline2\nline3",
    multi           => "line1\nline2\nline3\n",
    binary          => join(q{}, map {chr} 0x00 .. 0xFF),
);
for my $test (keys %data) {
    my $s = $data{$test};
    replacefile("$d/file", $s);
    open my $f, '<', "$d/file"                  or die "open($d/file): $!";
    my $content = do { local $/; <$f> };
    close $f                                    or die "close($d/file): $!";
    is $s, $content, $test;
}

chmod 0700, "$d/dir";   # allow File::Temp to do CLEANUP

# - ls_qmail()
#   * return absolute path names to ~/.qmail-* files related to this project:
#     . no files in ~/.qmail-*
#     . no files in ~/.qmail-* related to this project
#     . some files in ~/.qmail-* related to this project (some correct links,
#       some broken links) while other files are: usual files, broken links
#       to other project, correct links to other project

$ENV{HOME} = File::Temp::tempdir(CLEANUP => 1);

is_deeply [ls_qmail()], [],
    'ls_qmail(no ~/.qmail-* files)';

touch("$ENV{HOME}/.qmail");
touch("$ENV{HOME}/.qmail-1");
symlink '.qmail-1', "$ENV{HOME}/.qmail-2"       or die "symlink: $!";
is_deeply [ls_qmail()], [],
    'ls_qmail(no ~/.qmail-* files related to this project)';

sandbox();
qmail_flood();
is_deeply
    [sort {$a cmp $b} ls_qmail()],
    ["$ENV{HOME}/.qmail-1", "$ENV{HOME}/.qmail-2"],
    'ls_qmail(flood)';

# - main(...)
#   * too many params
#   * wrong params

throws_ok { main('param-1', 'param-2') }    qr/Usage:/,
    'main: too many params';
throws_ok { main('not_existing_param') }    qr/Usage:/,
    'main: wrong param';

# - main(--clean)
#   * remove all files ~/.qmail-* related to this project (some correct links,
#     some broken links) while other files are: usual files, broken links
#     to other project, correct links to other project

sandbox();
qmail_flood();
main('--clean');
is_deeply
    [sort {$a cmp $b} ls($ENV{HOME})],
    [sort {$a cmp $b} qw( .qmail-file .qmail-3 .qmail-4 )],
    'main(--clean)';

# - main() a.k.a. setup_qmail()
#   * complex use case involving most of functionality except "conflict"
#     and exceptions (too hard to simulate in test):
#     . there should be some ~/.qmail-* files unrelated to this project:
#       they shouldn't be modified
#     . in var/qmail/ should be file unrelated to files in config/qmail/
#       with symlink to it in ~/.qmail-*: both should be removed
#     . in ~/.qmail-* should be dangling symlink to our project: it should
#       be removed
#     . in var/qmail/ should be file unrelated to files in config/qmail/:
#       it should be removed
#     . in config/qmail/ should be empty file: installed as is
#     . in config/qmail/ should be file with comment, forward and two
#       commands: lines with commands should be modified while installing
#   * second run after previous test: nothing should change
#   * conflict

sandbox();
qmail_flood();
touch('var/qmail/3');
touch('config/qmail/empty');
open my $cmd, '>', 'config/qmail/cmd'           or die "open(config/qmail/cmd): $!";
print {$cmd}
    "# comment\n",
    "|cd /tmp; mycmd >/dev/null 2>&1\n",
    "&my\@email.com\n",
    "|othercmd",
    ;
close $cmd                                      or die "close(config/qmail/cmd): $!";
main();
is_deeply
    [sort {$a cmp $b} ls($ENV{HOME})],
    [sort {$a cmp $b} qw( .qmail-file .qmail-3 .qmail-4 .qmail-empty .qmail-cmd )],
    'main() ~/.qmail-* ok';
is_deeply
    [sort {$a cmp $b} ls('var/qmail')],
    [sort {$a cmp $b} qw( empty cmd )],
    'main() var/qmail/ ok';
is -s 'var/qmail/empty', 0,
    'main() empty is empty';
open $cmd, '<', 'var/qmail/cmd'                 or die "open(var/qmail/cmd): $!";
my $content = do { local $/; <$cmd> };
close $cmd                                      or die "close(var/qmail/cmd): $!";
my $cwd = cwd();
is $content,
    "# comment\n"
  . "|cd \Q$cwd\E || exit(100); cd /tmp; mycmd >/dev/null 2>&1\n"
  . "&my\@email.com\n"
  . "|cd \Q$cwd\E || exit(100); othercmd",
    'main() var/qmail/cmd processed';


done_testing();


sub sandbox {
    $ENV{HOME} = File::Temp::tempdir(CLEANUP => 1);
    chdir File::Temp::tempdir(CLEANUP => 1)     or die "chdir(tempdir()): $!";
    system('narada-new-1') == 0                 or die "system(narada-new-1): $!";
    return;
}

sub touch {
    my ($file) = @_;
    open my $f, '>', $file                      or die "open($file): $!";
    return;
}

sub qmail_flood {   # WARNING call ONLY after sandbox()
    # ~/.qmail-file
    # ~/.qmail-1        -> /this/project/var/qmail/1
    # ~/.qmail-2        -> /this/project/var/qmail/2 (broken)
    # ~/.qmail-3        -> /other/project/var/qmail/3
    # ~/.qmail-4        -> /other/project/var/qmail/4 (broken)
    touch('var/qmail/1');
    symlink cwd().'/var/qmail/1', "$ENV{HOME}/.qmail-1" or die "symlink: $!";
    symlink cwd().'/var/qmail/2', "$ENV{HOME}/.qmail-2" or die "symlink: $!";
    touch("$ENV{HOME}/.qmail-file");
    my $other = File::Temp::tempdir(CLEANUP => 1);
    system('narada-new-1', $other) == 0         or die "system(narada-new-1): $!";
    touch("$other/var/qmail/3");
    symlink $other.'/var/qmail/3', "$ENV{HOME}/.qmail-3" or die "symlink: $!";
    symlink $other.'/var/qmail/4', "$ENV{HOME}/.qmail-4" or die "symlink: $!";
    return;
}
__END__

# ~/.qmail-test1                -> /PROJECT/var/qmail/test1
# ~/.qmail-test2                -> /PROJECT/var/qmail/test2
# ~/.qmail-test3                -> /PROJECT/var/qmail/test3
# ~/.qmail-3rd-party-file
# ~/.qmail-3rd-party-symlink    -> /no/dir/no/file
# ~/.qmail-no-file-symlink      -> /PROJECT/var/qmail/no_file
# ~/user-file
sub prepare_qmail_home_sandbox {
    my $home_dir    = File::Temp::tempdir(CLEANUP => 1);
    my $project_dir = get_project_dir();

    for (qw{test1 test2 test3}) {
        Echo("$project_dir/var/qmail/$_", '# comment line');
        symlink "$project_dir/var/qmail/$_", "$home_dir/.qmail-$_"
            or die "can't create symlink: $!";
    }
    Echo("$home_dir/.qmail-3rd-party-file", '# comment line');
    symlink '/no/dir/no/file', "$home_dir/.qmail-3rd-party-symlink"
        or die "can't create symlink: $!";
    symlink "$project_dir/var/qmail/no_file", "$home_dir/.qmail-no-file-symlink"
        or die "can't create symlink: $!";

    Echo("$home_dir/user-file", q{});

    return $home_dir;
}


# - main()
#   * too many params
#   * wrong params
#   * config/qmail not readable: throw exception
#   * --clean: make sure clean_qmail('--clean') called
#   * no --clean and no config/qmail/*: make sure set_qmail() called
#     with empty list
#   * no --clean and exists config/qmail/*: make sure set_qmail() called
#     with correct file list

sandbox();

throws_ok { main('param-1', 'param-2') }    qr/Usage:/,
    'main: too many params';

throws_ok { main('not_existing_param') }    qr/Usage:/,
    'main: wrong param';

chmod 0, 'config/qmail'                                 or die "chmod: $!";
throws_ok { main() } qr/can't opendir/,
    'main: qmail config dir not readable';
chmod 0755, 'config/qmail'                              or die "chmod: $!";

{ 
    my (@clean_log, @set_log);
    my $m = new Test::MockModule('main');
    $m->mock('clean_qmail', sub { push @clean_log, @_ });
    $m->mock('set_qmail',   sub { push @set_log, @_ });
    main('--clean');
    is("@clean_log", '--clean',
        'main: call clean_qmail("--clean") on --clean');
    @clean_log = ();

    main();
    is("@set_log", q{},
        'main: call set_qmail() on no config files');
    @set_log = ();
    Echo('config/qmail/qmail-example', q{});
    main();
    is("@set_log", 'qmail-example',
        'main: call set_qmail("qmail-example") with config file');
}

# - get_project_dir()
#   * throw on \n inside directory name

sandbox();

Echo('pwd', "#!/bin/sh\ncat cwd");
chmod 0755, 'pwd'                                   or die "chmod: $!";

{
    local $ENV{PATH} = ".:$ENV{PATH}";

    Echo('cwd', "/a/b/c\n");
    is(get_project_dir(), '/a/b/c',
        'get_project_dir: ok');

    Echo('cwd', "/a/b\nb/c\n");
    throws_ok { get_project_dir() }     qr/must not contain \\n/,
        'get_project_dir: throw on \n inside directory name';
}

# - process()
#   * test multi file, multi line data, with several commands and comments



# - get_file_list()
#   * no param
#   * wrong param
#   * empty dir
#   * dir with 1 file
#   * dir with many files

sandbox();

throws_ok { get_file_list() }               qr/can't opendir/,
    'get_file_list: no param';
throws_ok { get_file_list('nosuchdir') }    qr/can't opendir/,
    'get_file_list: non-existent directory';

is_deeply([get_file_list('config/qmail')], [],
    'get_file_list: no files');

Echo('config/qmail/qfile-1', '# comment line');
is_deeply([get_file_list('config/qmail')], ['qfile-1'],
    'get_file_list: 1 file');

Echo('config/qmail/qfile-2', q{});
is_deeply([get_file_list('config/qmail')], ['qfile-1','qfile-2'],
    'get_file_list: many files');

# - get_config_files()
#   * no files
#   * some files

sandbox();

is_deeply({get_config_files('qmail')}, {},
    'get_config_files: no files');

Echo('config/qmail/qfile-1', '# 1');
Echo('config/qmail/qfile-2', "# 2\n# 22\n");
Echo('config/qmail/qfile-3', q{});
is_deeply({get_config_files('qmail')},
    { 'qfile-1' => '# 1', 'qfile-2' => "# 2\n# 22\n", 'qfile-3' => q{} },
    'get_config_files: some files');

# - clean_qmail()
#   * do not force (remove only broken symlinks to project)
#   * force (remove all symlinks to project)

{
    sandbox();

    my @all_files = (
        '.qmail-test1',
        '.qmail-test2',
        '.qmail-test3',
        '.qmail-3rd-party-file',
        '.qmail-3rd-party-symlink',
        '.qmail-no-file-symlink',
        'user-file',
    );
    my (@expect, @result);

    local $ENV{HOME} = prepare_qmail_home_sandbox();
    clean_qmail();
    @result     = get_allfiles($ENV{HOME});
    @expect     = grep m/test|3rd-party|user/, @all_files;
    is_deeply([sort @result], [sort @expect],
        'clean_qmail: do not force');

    local $ENV{HOME} = prepare_qmail_home_sandbox();
    clean_qmail('--clean');
    @result     = get_allfiles($ENV{HOME});
    @expect     = grep m/3rd-party|user/, @all_files;
    is_deeply([sort @result], [sort @expect],
        'clean_qmail: force');
}

# - set_qmail()


# - check_qmail()


# - clean_config2var()


# - set_config2var()



