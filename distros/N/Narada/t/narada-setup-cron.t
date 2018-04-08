use lib 't'; use share; guard my $guard;
use Narada::Config qw( set_config );

require (wd().'/blib/script/narada-setup-cron');


# - main()
#   * too many params
#   * wrong params
#   * no params and config/crontab/backup not readable: throw exception
#   * --clean: make sure del_cron() called
#   * no --clean and no config/crontab/backup: make sure del_cron() called
#   * no --clean and exists config/crontab/backup: make sure set_cron called
#   * many files in config/crontab/: make sure set_cron called for them all
#   * manage var/use/cron

throws_ok { main('param-1', 'param-2') }    qr/Usage:/,
    'main: too many params';

throws_ok { main('not_existing_param') }    qr/Usage:/,
    'main: wrong param';

SKIP: {
    skip 'non-root user required', 1 if $< == 0;
    chmod 0, 'config/crontab/backup'                        or die "chmod: $!";
    throws_ok { main() }                    qr/permission/i,
        'main: not readable';
    chmod 0644, 'config/crontab/backup'                     or die "chmod: $!";
}

{ 
    my (@log, $lines);
    my $is_log = sub { is("@log", "@{$_[0]}", $_[1]); @log=(); };
    my $m = new Test::MockModule('main');
    $m->mock('del_cron', sub { push @log, 'del_cron'; $lines = 0 });
    $m->mock('set_cron', sub { push @log, 'set_cron'; $lines = shift=~tr/\n// });

    main('--clean');
    $is_log->(['del_cron'],
        'main: call del_cron() on --clean');

    rename 'config/crontab/backup', 'config/crontab.orig'   or die "rename: $!";
    main();
    rename 'config/crontab.orig', 'config/crontab/backup'   or die "rename: $!";
    $is_log->(['del_cron'],
        'main: call del_cron() on no config/crontab/backup without --clean');

    main();
    $is_log->(['set_cron'],
        'main: call set_cron() on config/crontab/backup without --clean');

    my $wait = path('config/crontab/backup')->lines;
    is $lines, $wait, 'one config';

    set_config('crontab/service', "# line1\n# line2\n");
    main();
    $is_log->(['set_cron'],
        'main: call set_cron() on config/crontab/*');
    $wait += 1 + path('config/crontab/service')->lines;
    is $lines, $wait, 'many configs';

    main('--clean');
    ok !path('var/use/cron')->exists, 'no var/use/cron';
    output_from { main() };
    ok path('var/use/cron')->is_file, 'created var/use/cron';
    main('--clean');
    ok !path('var/use/cron')->exists, 'removed var/use/cron';
}

# - get_project_dir()
#   * throw on \n inside directory name

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
#   * test multi line data, with several commands and comments

my $process = process(
    "# comment1\n"
  . "* * * * * echo ok\n"
  . "# comment2\n"
  . "10 6 * * * date\n"
  . "0 23-7/2,8 * * *   ( date >/tmp/date ) &"
);
my $cwd = quotemeta(get_project_dir());
$cwd =~ s{\\([/,._-])}{$1}xmsg; # unquote safe chars for readability
my $expect =
    "# comment1\n"
  . "* * * * * cd $cwd || exit; echo ok\n"
  . "# comment2\n"
  . "10 6 * * * cd $cwd || exit; date\n"
  . "0 23-7/2,8 * * *   cd $cwd || exit; ( date >/tmp/date ) &"
    ;
is($process, $expect,
    'process: ok');

# - get_markers()
#   . test regexp will match blocks composed from:
#     * start."\n".end."\n"
#     * start."\n".line1."\n".end."\n"
#     * start."\n".line1."\n".line2."\n".end."\n"
#     * start."\n".end
#   . test regexp will not match blocks composed from:
#     * junk.start."\n".end."\n"
#     * start.junk."\n".end."\n"
#     * start."\n".junk.end."\n"
#     * start."\n".end.junk."\n"

$cwd = get_project_dir();
my($re, $start, $end) = get_markers();

my $expected =
    "# ENTER Narada: $cwd"
  . "\n"
  . "# LEAVE Narada: $cwd"
  . "\n"
    ;
like($expected, $re, 'get_markers: start.\n.end.\n');

$expected =
    "# ENTER Narada: $cwd"
  . "\n"
  . "1 * * * * echo line1\n"
  . "\n"
  . "# LEAVE Narada: $cwd"
  . "\n"
    ;
like($expected, $re, 'get_markers: start.\n.line1.\n.end.\n');

$expected =
    "# ENTER Narada: $cwd"
  . "\n"
  . "1 * * * * echo line1\n"
  . "\n"
  . "1 * * * * echo line2\n"
  . "\n"
  . "# LEAVE Narada: $cwd"
  . "\n"
    ;
like($expected, $re, 'get_markers: start.\n.line1.\n.line2.\n.end.\n');

$expected =
    "# ENTER Narada: $cwd"
  . "\n"
  . "# LEAVE Narada: $cwd"
    ;
like($expected, $re, 'get_markers: start.\n.end');

$expected =
    "* 1 * * * echo ups;"
  . "# ENTER Narada: $cwd"
  . "\n"
  . "# LEAVE Narada: $cwd"
  . "\n"
    ;
unlike($expected, $re, 'get_markers: junk.start.\n.end.\n');

$expected =
    "# ENTER Narada: $cwd"
  . "# some unexpected user comment"
  . "\n"
  . "# LEAVE Narada: $cwd"
  . "\n"
    ;
unlike($expected, $re, 'get_markers: start.junk\n.end.\n');

$expected =
    "# ENTER Narada: $cwd"
  . "\n"
  . "* 1 * * * echo junk!"
  . "# LEAVE Narada: $cwd"
  . "\n"
    ;
unlike($expected, $re, 'get_markers: start.\n.junk.end.\n');

$expected =
    "# ENTER Narada: $cwd"
  . "\n"
  . "# LEAVE Narada: $cwd"
  . "* 1 * * * echo junk!"
  . "\n"
    ;
unlike($expected, $re, 'get_markers: start.\n.end.junk.\n');



# get_user_crontab(), set_user_crontab()
#   . Test MANUALLY!
# - force_last_cr()
#   . Will be tested while testing set_cron().
# - set_cron()
#   . project crontab variants:
#     * empty
#     * single line without last \n
#     * single line with last \n
#     * multi line without last \n
#     * multi line with last \n
#   . user crontab variants:
#     * empty
#     * has user data and another narada project block without last \n
#     * has user data and another narada project block with last \n
#   . operations:
#     * add
#     * update

{ 
    my $got;
    my $user_crontab;
    my $m = new Test::MockModule('main');
    $m->mock('get_user_crontab', sub { $user_crontab; });
    $m->mock('set_user_crontab', sub { $got = shift() });

    my $start = "# ENTER Narada: $cwd";
    my $end   = "# LEAVE Narada: $cwd";

    my $single_line = '* * 1 * * echo singleline';
    my $multi_line = 
        '# multiline crontab example'
      . "\n"
      . '* * 1 * * echo firstline;'
      . "\n"
      . '* * 1 * * echo secondline;'
        ;
    my $narada_project = 
        '* 1 * * * * echo user_data;' 
      . "\n"
      . '# ENTER Narada: /some/path/to/narada'
      . "\n"
      . '1 * * * * cd /some/path/to/narada || exit; echo Narada;'
      . "\n"
      . '# LEAVE Narada: /some/path/to/narada'
        ;
    my $my_narada_project = $start
              . "\n"
              . "1 * * * * echo current_narada_proj;"
              . "\n"
              . $end
              ;

    my %crontab = ('empty'                       => q{},
                   'single line without last \n' => $single_line,
                   'single line with last \n'    => $single_line."\n",
                   'multi line without last \n'  => $multi_line,
                   'multi line with last \n'     => $multi_line."\n",
                  );
    my %user_crontab = (
        'empty' => q{},
        'has user data and another narada project block without last \n'
                => $narada_project,
        'has user data and another narada project block with last \n'
                => $narada_project."\n",
                       );
   
    for my $action('add','edit'){
        for my $crontab (sort keys %crontab){
            for (sort keys %user_crontab){
                if ($action eq 'add'){
                    $user_crontab = $user_crontab{$_};
                    $expected = force_last_cr($user_crontab{$_})
                              . $start
                              . "\n"
                              . force_last_cr($crontab{$crontab})
                              . $end
                              . "\n"
                            ;
                }else{
                    $user_crontab = $my_narada_project."\n".$user_crontab{$_};
                    $expected = $start
                              . "\n"
                              . force_last_cr($crontab{$crontab})
                              . $end
                              . "\n"
                              . $user_crontab{$_}
                            ;
                }
                $got=q{};
                set_cron($crontab{$crontab});
                is ($got,
                    $expected,
                    "action: $action crontab: $crontab user crontab: $_"
                   );
            }
        }
    }
# - del_cron()
# #   . user crontab variants:
# #     * no block
# #     * empty block
# #     * block with data
    $user_crontab = $multi_line;
    del_cron();
    $expected = $multi_line;
    is($got, $expected, 'del_cron: no block');

    $user_crontab = $start."\n".$end."\n".$multi_line;
    del_cron();
    $expected = $multi_line;
    is($got, $expected, 'del_cron: empty block');

    $user_crontab = $single_line."\n".$start."\n".$multi_line."\n".$end."\n".$narada_project;
    del_cron();
    $expected = $single_line."\n".$narada_project;
    is($got, $expected, 'del_cron: block with data');
}


done_testing();


sub Echo {
    my ($filename, $content) = @_;
    open my $fh, '>', $filename                         or die "open: $!";
    print {$fh} $content;
    close $fh                                           or die "close: $!";
    return;
}
