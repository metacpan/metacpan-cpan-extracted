use lib 't'; use share; guard my $guard;


my $full = path('.backup/full.tar');
is system('narada-backup'), 0, 'narada-backup (0)';
$full->copy('.backup/full-0.tar');
path('empty_file')->touch;
path('empty_dir')->mkpath;
path('file')->spew('old1');
path('dir/dir')->mkpath;
path('dir/file')->spew('old2');
path('dir/some')->spew('data');
path('dir/dir/file')->spew('old3');
is system('narada-backup'), 0, 'narada-backup (1)';
$full->copy('.backup/full-1.tar');
sleep 1;
path('dir/file')->spew('modified2');
path('dir/some')->remove;
is system('narada-backup'), 0, 'narada-backup (2)';
$full->copy('.backup/full-2.tar');


# - errors:
#   * no params
stderr_like { isnt system('narada-restore'), 0, 'no params' } qr/usage/msi, 'got usage';
#   * non-existing backup file
stderr_like { isnt system('narada-restore nosuch'), 0, 'bad param' } qr/nosuch/msi, 'got error';
# - full restore in:
#   * empty dir
is r(2), 0, 'full restore in empty dir';
lives_ok {
    is path('tmp/file')->slurp, 'old1';
    is path('tmp/dir/file')->slurp, 'modified2';
    ok !path('tmp/dir/some')->exists;
} 'restored 2';
system('rm -rf tmp/* tmp/.[!.]*');
#   * empty dir with only .release/ and .backup/
path('tmp/.backup')->mkpath;
path('tmp/.release')->mkpath;
path('tmp/.lock')->touch;
path('tmp/.lock.bg')->touch;
is r(0), 0, 'full restore (0) in empty dir with .release & .backup & .lock*';
lives_ok {
    ok path('tmp/config')->is_dir;
    ok !path('tmp/dir/some')->exists;
} 'restored 0';
#   * deploy dir
is r(1), 0, 'full restore (1) in deploy dir';
lives_ok {
    ok path('tmp/empty_file')->is_file;
    ok path('tmp/empty_dir')->is_dir;
    is path('tmp/file')->slurp, 'old1';
    is path('tmp/dir/file')->slurp, 'old2';
    is path('tmp/dir/some')->slurp, 'data';
    is path('tmp/dir/dir/file')->slurp, 'old3';
} 'restored 1';
is r(2), 0, 'full restore (2) in deploy dir';
lives_ok {
    is path('tmp/file')->slurp, 'old1';
    is path('tmp/dir/file')->slurp, 'modified2';
    ok !path('tmp/dir/some')->exists;
} 'restored 2';
system('rm -rf tmp/* tmp/.[!.]*');
#   * fail in non-empty dir
path('tmp/.gitignore')->touch;
stderr_like { isnt r(0), 0, 'fail in non-empty dir' } qr/not narada/msi, 'got error';
system('rm -rf tmp/* tmp/.[!.]*');
# - restore only given files
#   * one file, given as
#     . file
is r(1, 'file'), 0, 'restore file';
is_deeply [sort(path('tmp')->children)], [qw(tmp/file)];
system('rm -rf tmp/* tmp/.[!.]*');
#     . /file
is r(1, '/file'), 0, 'restore /file';
is_deeply [sort(path('tmp')->children)], [qw(tmp/file)];
system('rm -rf tmp/* tmp/.[!.]*');
#     . ./file
is r(1, './file'), 0, 'restore ./file';
is_deeply [sort(path('tmp')->children)], [qw(tmp/file)];
system('rm -rf tmp/* tmp/.[!.]*');
#     . dir/file
is r(1, 'dir/file'), 0, 'restore dir/file';
lives_ok {
    is_deeply [sort(path('tmp')->children)], [qw(tmp/dir)];
    is_deeply [sort(path('tmp/dir')->children)], [qw(tmp/dir/file)];
};
system('rm -rf tmp/* tmp/.[!.]*');
#     . /dir/file
is r(1, '/dir/file'), 0, 'restore /dir/file';
lives_ok {
    is_deeply [sort(path('tmp')->children)], [qw(tmp/dir)];
    is_deeply [sort(path('tmp/dir')->children)], [qw(tmp/dir/file)];
};
system('rm -rf tmp/* tmp/.[!.]*');
#     . ./dir/file
is r(1, './dir/file'), 0, 'restore ./dir/file';
lives_ok {
    is_deeply [sort(path('tmp')->children)], [qw(tmp/dir)];
    is_deeply [sort(path('tmp/dir')->children)], [qw(tmp/dir/file)];
};
system('rm -rf tmp/* tmp/.[!.]*');
#   * one empty dir
is r(1, 'empty_dir'), 0, 'restore empty_dir';
is_deeply [sort(path('tmp')->children)], [qw(tmp/empty_dir)];
system('rm -rf tmp/* tmp/.[!.]*');
#   * one dir with files
is r(1, 'dir'), 0, 'restore dir';
lives_ok {
    is_deeply [sort(path('tmp')->children)], [qw(tmp/dir)];
    is_deeply [sort(path('tmp/dir')->children)], [qw(tmp/dir/dir tmp/dir/file tmp/dir/some)];
    is_deeply [sort(path('tmp/dir/dir')->children)], [qw(tmp/dir/dir/file)];
};
system('rm -rf tmp/* tmp/.[!.]*');
#   * several files/dirs
is r(1, 'file', 'dir/dir'), 0, 'restore file dir/dir';
lives_ok {
    is_deeply [sort(path('tmp')->children)], [qw(tmp/dir tmp/file)];
    is_deeply [sort(path('tmp/dir')->children)], [qw(tmp/dir/dir)];
    is_deeply [sort(path('tmp/dir/dir')->children)], [qw(tmp/dir/dir/file)];
};
system('rm -rf tmp/* tmp/.[!.]*');


done_testing();


sub r {
    my ($n, @files) = map {quotemeta} @_;
    return system(join q{ }, "cd tmp && narada-restore ../.backup/full-$n.tar", @files);
}
