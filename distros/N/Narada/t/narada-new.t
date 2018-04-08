use lib 't'; use share; guard my $guard;


plan skip_all => 'git not installed'        if !grep {-x "$_/git"} split /:/, $ENV{PATH};


$ENV{GIT_AUTHOR_NAME} = $ENV{GIT_COMMITTER_NAME} = 'Your Name';
$ENV{GIT_AUTHOR_EMAIL}= $ENV{GIT_COMMITTER_EMAIL}= 'you@example.com';
system('{
    git init &&
    git config commit.gpgsign false &&
    git add . && git commit -m 1 &&
    git checkout -b socklog &&
    narada-install 0.2.0 &&
    git add . && git commit -m 2 &&
    git checkout master
    } >/dev/null 2>&1') == 0 or die "system: $?";
my $new = 'narada-new -r '.quotemeta(cwd());

my $wd      = tempdir('narada.XXXXXX');
my $guard_wd= bless {};
chdir $wd or die "chdir($wd): $!";


stderr_like { isnt system("$new -h"),       0, '-h'         } qr/usage/i, 'got usage';
stderr_like { isnt system("$new --help"),   0, '--help'     } qr/usage/i, 'got usage';
stderr_like { isnt system("$new 1 2"),      0, 'bad params' } qr/usage/i, 'got usage';

mkdir 'proj' or die "mkdir(proj): $!";
stderr_like { isnt system("$new"),          0, 'bad .'      } qr/not empty/i, 'not empty';

mkdir 'proj/.git' or die "mkdir(proj/.git): $!";
stderr_like { isnt system("$new"),          0, 'bad proj'   } qr/not empty/i, 'not empty';
rmdir 'proj/.git' or die "rmdir(proj/.git): $!";

is system("$new proj >/dev/null 2>&1"), 0, 'new proj';
ok path('proj/config')->is_dir, 'created';
is system("$new proj2 >/dev/null 2>&1"), 0, 'new proj2';
ok path('proj2/config')->is_dir, 'created';
mkdir 'proj3' or die "mkdir(proj3): $!";
chdir 'proj3' or die "chdir(proj3): $!";
is system("$new >/dev/null 2>&1"), 0, 'new (in proj3)';
chdir '..' or die "chdir(..): $!";
ok path('proj3/config')->is_dir, 'created';

ok !path('proj/service')->is_dir, 'brance master is default';

is system("$new -b master proj4 >/dev/null 2>&1"), 0, 'new -b master proj4';
ok path('proj4/config')->is_dir, 'created';
ok !path('proj4/service')->is_dir, 'brance master';

is system("$new -b socklog proj5 >/dev/null 2>&1"), 0, 'new -b socklog proj5';
ok path('proj5/config')->is_dir, 'created';
ok path('proj5/service')->is_dir, 'brance socklog';

isnt system("$new -b nosuch proj6 >/dev/null 2>&1"), 0, 'new -b nosuch proj6';
ok path('proj6/.git')->is_dir, 'created partially';


done_testing();
