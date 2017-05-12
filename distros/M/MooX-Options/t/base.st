local $ENV{TEST_FORCE_COLUMN_SIZE} = 78;

my @params = qw/bool counter empty/;
subtest "no args" => sub {
    note "no args";
    local @ARGV = ();
    my $t = t->new_with_options();
    ok( $t->can($_), "$_ defined" ) for @params;
    is( $t->$_, undef, "$_ values is undef" ) for @params;
    is( $t->has_default, 'foo', 'Default works correctly' );
    done_testing();
};

subtest "args value" => sub {
    note "args value with repeatable";
    local @ARGV
        = ( '--bool', '--counter', '--counter', '--counter', '--empty' );
    my $t = t->new_with_options();
    note "bool ",    $t->bool;
    note "counter ", $t->counter;
    note "empty ",   $t->empty;
    ok( $t->$_, "$_ values is defined" ) for @params;
    is( $t->bool,    1, "bool is well defined" );
    is( $t->counter, 3, "counter is well defined" );
    is( $t->empty,   1, "empty is well defined" );
    done_testing();
};

subtest "negativable" => sub {
    note "negativable";
    local @ARGV = ( '--empty', '--no-empty' );
    my $t = t->new_with_options();
    is( $t->empty, 0, "empty is well defined" );
    done_testing();
};

subtest "split" => sub {
    note "split";

    {
        local @ARGV = ('--split=1');
        my $t = t->new_with_options();
        is_deeply( $t->split, [1], "split one arg" );
    }
    {
        local @ARGV = ( '--split=1', '--split=2' );
        my $t = t->new_with_options();
        is_deeply( $t->split, [ 1, 2 ], "split two arg" );
    }
    {
        local @ARGV = ('--split=1,2');
        my $t = t->new_with_options();
        is_deeply( $t->split, [ 1, 2 ], "split one arg autosplit" );
    }
    {
        local @ARGV = ( '--split=1', '--split=2', '--split=3,4' );
        my $t = t->new_with_options();
        is_deeply(
            $t->split,
            [ 1, 2, 3, 4 ],
            "split three arg with autosplit"
        );
    }
    {
        local @ARGV = ( '--split', '1', '--split', '2', '--split', '3,4' );
        my $t = t->new_with_options();
        is_deeply(
            $t->split,
            [ 1, 2, 3, 4 ],
            "split three arg with autosplit and space"
        );
    }
    done_testing();
};

subtest "test required" => sub {
    note "test required";

    {
        local @ARGV = ();
        my @r = trap { r->new_with_options };
        is( $trap->exit, 1, "missing args, exit 1" );
        like( $trap->stderr, qr/^str_req is missing/, "str_reg is missing" );
    }
    {
        local @ARGV = ('--str_req=ok');
        my $t = r->new_with_options;
        is( $t->str_req, 'ok', 'str req is ok' );
    }
    {
        local @ARGV = ();
        my @r = trap { multi_req->new_with_options };
        is( $trap->exit, 1, "missing args exit 1" );
        my @missing = $trap->stderr =~ /(multi_\d is missing)\n/g;
        my @target_isa;
        { no strict 'refs'; @target_isa = @{"multi_req::ISA"} };
        if ( multi_req->isa('Moose::Object') || multi_req->isa('Mo::Object') )
        {
            is( scalar @missing, 1, "only one missing for moose" );
        }
        else {
            is( scalar @missing, 3, "multi is missing" );
        }
    }
    done_testing();
};

subtest "test help" => sub {
    note "test help";
    {
        local @ARGV = ('--help');
        my @r = trap { r->new_with_options };
        is( $trap->exit, 0, "help, exit 0" );
        ok( $trap->stdout !~ /^str_req is missing/, "str_reg is missing" );
    }
    done_testing();
};

subtest "test short help" => sub {
    note "test short help";
    {
        local @ARGV = ('--usage');
        my @r = trap { r->new_with_options };
        is( $trap->exit, 0, "help, exit 0" );
        ok( $trap->stdout !~ /^str_req is missing/, "str_reg is missing" );
        like $trap->stdout,
            qr{\QUSAGE: m\E\w+\Q.t [ --str_req=String ]  |  [ --usage ] [ -h ] [ --help ] [ --man ]\E},
            'usage message ok';
    }
    done_testing();
};

subtest "value override" => sub {
    note "value override";
    {
        local @ARGV = ();
        my $t = r->new_with_options( str_req => "ok" );
        is( $t->str_req, 'ok', 'str req is ok' );
    }
    {
        local @ARGV = ('--str_req=ko');
        my $t = r->new_with_options( str_req => "ok" );
        is( $t->str_req, 'ok', 'str req is override with ok' );
    }
    done_testing();
};

subtest "split_complexe_str" => sub {
    note "split on complexe str";
    {
        local @ARGV = ("--split_str=a,b,c");
        my $t = sp_str->new_with_options();
        is_deeply( $t->split_str, [qw/a b c/], 'str req is ok' );
    }
    {
        local @ARGV = ("--split-str=a,b,c");
        my $t = sp_str->new_with_options();
        is_deeply( $t->split_str, [qw/a b c/], 'str req is ok' );
    }
    {
        local @ARGV = ("--split_conflict_str1=a,b,c");
        my $t = sp_str->new_with_options();
        is_deeply( $t->split_conflict_str1, [qw/a b c/], 'str req is ok' );
    }
    {
        local @ARGV = ("--split_conflict-str1=a,b,c");
        my $t = sp_str->new_with_options();
        is_deeply( $t->split_conflict_str1, [qw/a b c/], 'str req is ok' );
    }
    {
        local @ARGV = ("--split-conflict_str1=a,b,c");
        my $t = sp_str->new_with_options();
        is_deeply( $t->split_conflict_str1, [qw/a b c/], 'str req is ok' );
    }
    {
        local @ARGV = ("--split-conflict-str1=a,b,c");
        my $t = sp_str->new_with_options();
        is_deeply( $t->split_conflict_str1, [qw/a b c/], 'str req is ok' );
    }
    {
        local @ARGV = ('--split_str=a,"b,c",d');
        my $t = sp_str->new_with_options();
        is_deeply( $t->split_str, [ 'a', 'b,c', 'd' ], 'str req is ok' );
    }
    {
        local @ARGV = ('--split-str=a,"b,c",d');
        my $t = sp_str->new_with_options();
        is_deeply( $t->split_str, [ 'a', 'b,c', 'd' ], 'str req is ok' );
    }
    done_testing();
};

subtest "split_complexe_str_short" => sub {
    note "split on complexe str short";
    {
        local @ARGV = ("-z=a");
        my $t = sp_str_short->new_with_options();
        is_deeply( $t->split_str, [qw/a/], 'str req is ok' );
    }
    {
        local @ARGV = ("-z=a,b,c");
        my $t = sp_str_short->new_with_options();
        is_deeply( $t->split_str, [qw/a b c/], 'str req is ok' );
    }
    {
        local @ARGV = ('-z=a,"b,c",d');
        my $t = sp_str_short->new_with_options();
        is_deeply( $t->split_str, [ 'a', 'b,c', 'd' ], 'str req is ok' );
    }
    {
        local @ARGV = ( '-z', 'a,"b,c",d' );
        my $t = sp_str_short->new_with_options();
        is_deeply( $t->split_str, [ 'a', 'b,c', 'd' ], 'str req is ok' );
    }
    done_testing();
};

subtest "split_str_shorter_name" => sub {
    note "shorter long split";
    {
        local @ARGV = ("--split_st=a,b,c");
        my $t = sp_str->new_with_options();
        is_deeply( $t->split_str, [qw/a b c/], 'str req is ok' );
    }
    {
        local @ARGV = ("--split-st=a,b,c");
        my $t = sp_str->new_with_options();
        is_deeply( $t->split_str, [qw/a b c/], 'str req is ok' );
    }
    note "shorter long split with conflict";
    {
        local @ARGV = ("--split_co=a,b,c");
        trap {
            sp_str->new_with_options();
        };
        like $trap->stderr, qr/Option\ssplit_co\sis\sambiguous/,
            'conflict detected';
        local @ARGV = ("--split-co=a,b,c");
        trap {
            sp_str->new_with_options();
        };
        like $trap->stderr, qr/Option\ssplit_co\sis\sambiguous/,
            'conflict detected';
    }
    done_testing();
};

subtest "should_die_ok" => sub {
    note "Test chain method";
    trap { d->new_with_options( should_die_ok => 1 ) };
    like( $trap->stderr, qr/this\s\will\sdie\sok/, 'should die ok' );
};

subtest "test usage" => sub {
    note "test usage method";
    my $s = sp_str->new_with_options();
    my @r
        = trap { $s->options_usage( 127, 'usage work', 'usage really work' ) };
    is( $trap->exit, 127, 'exit code is correct' );
    like( $trap->stderr, qr/usage work/, 'custom message is present' );
    like(
        $trap->stderr,
        qr/usage really work/,
        'custom message is really present'
    );
    like(
        $trap->stderr,
        qr/help\s+show a long help message/,
        'help is present'
    );
    like(
        $trap->stderr,
        qr/split_str=\[Strings\]\s+no doc for split_str/,
        'attr no doc is present'
    );
};

subtest "test short usage" => sub {
    note "test usage method";
    my $s = sp_str->new_with_options();
    my @r = trap { $s->options_short_usage(127) };

    is( $trap->exit, 127, 'exit code is correct' );
    like $trap->stderr,
        qr{\QUSAGE: m\E\w+\Q.t [ --split_conflict_str1=[Strings] ] [ --split_conflict_str2=[Strings] ] [ --split_str=[Strings] ]  |  [ --usage ] [ -h ] [ --help ] [ --man ]\E},
        'short message ok';
};

subtest "doc usage" => sub {
    note "doc usage";
    my $s = t_doc->new_with_options();
    my @r = trap { $s->options_usage(127) };
    is( $trap->exit, 127, 'exit code is correct' );
    like( $trap->stderr, qr/t\s+this is a test/, 'doc on attribute' );
};

subtest "test short" => sub {
    note "test short";
    my $s = t_short->new_with_options();
    trap { $s->options_usage };
    like( $trap->stdout, qr/\-v \-\-verbose/, 'short doc ok' );
};

subtest "test skip_options" => sub {
    note "test skip_options";
    my $s = t_skipopt->new_with_options();
    trap { $s->options_usage() };
    ok( $trap->stdout !~ /\-\-multi/, 'multi is no more an option' );
};

subtest "test prefer_commandline" => sub {
    note "test prefer_commandline";
    {
        local @ARGV = ('--t=override');
        my $t = t_prefer_cli->new_with_options( t => 'default value' );
        is( $t->t, 'override', 'prefer_commandline ok' );
    }
};

subtest "test dash" => sub {
    note "test dash";
    {
        local @ARGV = ('--start_date=2012-12-12');
        my $t = t_dash->new_with_options();
        is( $t->start_date, '2012-12-12', '--start_date ok' );
    }
    {
        local @ARGV = ('--start-date=2012-12-12');
        my $t = t_dash->new_with_options();
        is( $t->start_date, '2012-12-12', '--start-date ok' );
    }
    {
        local @ARGV = ('-s2012-12-12');
        my $t = t_dash->new_with_options();
        is( $t->start_date, '2012-12-12', '-s ok' );
    }
};

subtest "json" => sub {
    note "json";
    {
        local @ARGV = ( "--t", "{\"a\":1,\"b\":2}" );
        my $t = t_json->new_with_options();
        is_deeply( $t->t, { a => 1, b => 2 }, 'json properly set' );
    }

    {
        local @ARGV = ( "--t", "bad json" );
        my $t = trap { t_json->new_with_options };
        like( $trap->stderr, qr/malformed JSON string/,
            "decode json failed" );
        like( $trap->stderr, qr/\-t=JSON/,
            "json help message properly set" );
    }

    {
        local @ARGV = ('--help');
        my $t = trap { t_json->new_with_options };
        note $trap->stdout;
        like( $trap->stdout, qr/\-t:\sJSON/,
            "json help message properly set" );
    }

    {
        trap {
            t_json->new->options_man( undef, *STDOUT );
        };
        like( $trap->stdout, qr/\-t: JSON/, "json man message properly set" )
            or diag $trap->stdout;
    }
};

subtest "json format" => sub {
    note "json format";
    {
        local @ARGV = ( "--t", "{\"a\":1,\"b\":2}" );
        my $t = t_json_opt->new_with_options();
        is_deeply( $t->t, { a => 1, b => 2 }, 'json properly set' );
    }

    {
        local @ARGV = ( "--t", "bad json" );
        my $t = trap { t_json_opt->new_with_options };
        ok( $trap->stderr =~ /malformed JSON string/, "decode json failed" );
        ok( $trap->stderr =~ /\-t=JSON/, "json help message properly set" );
    }

    {
        local @ARGV = ('--help');
        my $t = trap { t_json_opt->new_with_options };
        ok( $trap->stdout =~ /\-t: JSON/, "json help message properly set" );
    }

    {
        trap {
            t_json_opt->new->options_man( undef, *STDOUT );
        };
        ok( $trap->stdout =~ /\-t: JSON/, "json help message properly set" )
            or diag $trap->stdout;
    }
};

subtest "range_complexe_str" => sub {
    note "range on complexe str";
    {
        local @ARGV = ('--range_str=1,2,4');
        my $t = rg_str->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 4/], 'str1 req is ok' );
    }
    {
        local @ARGV = ('--range-str=1,2,4..');
        my $t = rg_str->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 4/], 'str2 req is ok' );
    }

    {
        local @ARGV = ('--range_str=1,2,4..6');
        my $t = rg_str->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 4 5 6/], 'str3 req is ok' );
    }
    {
        local @ARGV = ('--range-str=1,2,4..6');
        my $t = rg_str->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 4 5 6/], 'str4 req is ok' );
    }
    {
        local @ARGV = ('--range_str=1,2,4..');
        my $t = rg_str->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 4/], 'str req5 is ok' );
    }
    {
        local @ARGV = ('--range-str=1,2,4..');
        my $t = rg_str->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 4/], 'str req6 is ok' );
    }
    {
        local @ARGV = ("--range_str=1,2,4..7,10");
        my $t = rg_str->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 4 5 6 7 10/], 'str7 req is ok' );
    }
    {
        local @ARGV = ("--range-str=1,2,4..7,10");
        my $t = rg_str->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 4 5 6 7 10/], 'str8 req is ok' );
    }
    {
        local @ARGV = ('--range_str=1..3,10..12,20..');
        my $t = rg_str->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 3 10 11 12 20/], 'str9 req is ok' );
    }
    {
        local @ARGV = ('--range-str=1..3,10..12,20..');
        my $t = rg_str->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 3 10 11 12 20/],
            'str10 req is ok' );
    }
    {
        local @ARGV = ('--range_str=1,"2,3",4,"foo bar"');
        my $t = rg_str->new_with_options();
        is_deeply(
            $t->range_str,
            [ 1, "2,3", 4, "foo bar" ],
            'str11 req is ok'
        );
    }
    {
        local @ARGV = ('--range-str=1,"2,3",4,"a,2,c"');
        my $t = rg_str->new_with_options();
        is_deeply(
            $t->range_str,
            [ 1, "2,3", 4, "a,2,c" ],
            'str12 req is ok'
        );
    }
    done_testing();
};

subtest "range_complexe_str_short" => sub {
    note "range on complexe str short";
    {
        local @ARGV = ("-r=1");
        my $t = rg_str_short->new_with_options();
        is_deeply( $t->range_str, [qw/1/], 'str1 req is ok' );
    }
    {
        local @ARGV = ("-r=1,2,4");
        my $t = rg_str_short->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 4/], 'str2 req is ok' );
    }
    {
        local @ARGV = ("-r=1..4");
        my $t = rg_str_short->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 3 4/], 'str3 req is ok' );
    }
    {
        local @ARGV = ( '-r', "1..4" );
        my $t = rg_str_short->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 3 4/], 'str4 req is ok' );
    }
    {
        local @ARGV = ("-r=1,2,4..7,10");
        my $t = rg_str_short->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 4 5 6 7 10/], 'str5 req is ok' );
    }
    {
        local @ARGV = ( '-r', '1..3,10..12,20..' );
        my $t = rg_str_short->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 3 10 11 12 20/], 'str6 req is ok' );
    }
    {
        local @ARGV = ('-r=1,"2,3",4');
        my $t = rg_str_short->new_with_options();
        is_deeply( $t->range_str, [ '1', "2,3", '4' ], 'str7 req is ok' );
    }
    {
        local @ARGV = ( '-r', '1,"2,3",4..7' );
        my $t = rg_str_short->new_with_options();
        is_deeply( $t->range_str, [ 1, "2,3", 4, 5, 6, 7 ],
            'str8 req is ok' );
    }
    done_testing();
};

subtest "range_str_shorter_name" => sub {
    note "shorter long range";
    {
        local @ARGV = ("--range_st=1,2,4..6");
        my $t = rg_str->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 4 5 6/], 'str1 req is ok' );
    }
    {
        local @ARGV = ("--range-st=1,2,4..6,7");
        my $t = rg_str->new_with_options();
        is_deeply( $t->range_str, [qw/1 2 4 5 6 7/], 'str2 req is ok' );
    }
    note "shorter long range with conflict";
    {
        local @ARGV = ("--range_co=1,2,3");
        trap {
            rg_str->new_with_options();
        };
        like $trap->stderr, qr/Option\srange_co\sis\sambiguous/,
            'conflict detected';
        local @ARGV = ("--range-co=1,2,3");
        trap {
            rg_str->new_with_options();
        };
        like $trap->stderr, qr/Option\srange_co\sis\sambiguous/,
            'conflict detected';
    }
    done_testing();
};

1;
