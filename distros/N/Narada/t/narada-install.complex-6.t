use lib 't'; use share; guard my $guard;

require (wd().'/blib/script/narada-install');


sub is_version;
sub is_backups;
my ($narada_bin) = grep {-x "$_/narada-new"} split /:/, $ENV{PATH};
my $tmp_bin = tempdir('narada.bin.XXXXXX');
$ENV{PATH} = "$tmp_bin:$ENV{PATH}";
my @answers;
my $module = Test::MockModule->new('main');
$module->mock(ask => sub {
    if (@answers) {
        return shift @answers;
    }
    else {
        local *STDOUT = *STDERR;
        $module->original('ask')->(@_);
    }
});


# - complex functional test:
before($tmp_bin, 'narada-backup',  'test -f .release/fail-backup-$(cat VERSION) && exit 1');
before($tmp_bin, 'narada-restore', 'test -f .release/fail-$(basename "$1" .tar) && exit 1');
setup('1.5.0');
is_version '1.5.0';
#   * test error while restore
@answers = qw( restore );
path('.release/fail-full-1.2.0')->touch;
throws_ok { output_from { main(qw( -R 0.0.0 )) } } qr/Migration failed/i, 'error while restore: restore';
is_version '1.3.0';
path('.release/fail-full-1.2.0')->remove;


done_testing();


sub is_version {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    if ($_[0] eq '0.0.0') {
        ok !path('VERSION')->exists, 'no VERSION';
    }
    elsif (path('VERSION')->exists) {
        my ($v) = path('VERSION')->lines({chomp=>1});
        is $v, $_[0], $_[1] // "version: $_[0]";
    }
    else {
        ok 0, $_[1] // "version: $_[0]";
    }
}

sub is_backups {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is_deeply [ sort map { $_->basename('.tar') }
        path('.backup')->children(qr/\A(?!full[.]tar\z|incr[.]tar\z|snap\z)/ms)
        ], $_[0], $_[1] // "backups: @{$_[0]}";
}

sub before {
    my ($tmp_bin, $file, $cmd) = @_;
    path("$tmp_bin/$file")->spew(<<"EOF");
#!/bin/sh
$cmd
exec $narada_bin/$file "\$@"
EOF
    path("$tmp_bin/$file")->chmod(0755);
}

sub setup {
    my ($v) = @_;
    output_from { main(qw( -f .release/1.5.0.migrate -f .release/2.3.0.migrate -R 0.0.0 )) };
    path('.backup')->remove_tree;
    output_from { main($v) };
}
