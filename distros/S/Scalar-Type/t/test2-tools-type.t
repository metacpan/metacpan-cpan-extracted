use Test2::V0;
use Test2::Tools::Type; # NB no :extras!
use Test2::API qw/intercept/;

use Capture::Tiny qw(capture);
use Config;

ok(
    dies { is_positive(1) },
    "extra functions aren't available unless asked for"
);

subtest "show supported types" => sub {
    my $types_supported = capture {
        Test2::Tools::Type->import(qw(show_types))
    };
    like
        $types_supported,
        match(qr/\n  number\n/),
        "default types";
    like
        $types_supported,
        !match(qr/\n  positive\n/),
        "default types doesn't include the extras";

    # this does *not* make extras available for the test of the tests
    # because `show_types` aborts import() before it can do anything
    $types_supported = capture {
        Test2::Tools::Type->import(qw(show_types :extras))
    };
    like
        $types_supported,
        match(qr/\n  positive\n/),
        ":extras makes extras visible";
};

Test2::Tools::Type->import(qw(:extras));

subtest "is_* tests" => sub {
    my $events = intercept {
        is_integer(1,   "wow, a pass!");
        is_integer(1.2);
        is_integer("1", "fail");

        is_number(1,   "pass");
        is_number(1.2, "pass");
        is_number("1", "fail");

        is_positive(1.2,   "pass");
        is_positive(-1.2,  "fail");
        is_negative(-1.2,  "pass");
        is_negative(1.2,   "fail");

        is_positive("1.2",  "pass");
        is_negative("-1.2", "pass");

        is_ref(1);                # fail
        is_ref(\1);               # pass
        is_object(1);             # fail
        is_object(bless {});      # pass
        is_hashref([]);           # fail
        is_hashref({});           # pass
        is_arrayref({});          # fail
        is_arrayref([]);          # pass
        is_scalarref(sub {});     # fail
        is_scalarref(\"");        # pass
        is_coderef(\"");          # fail
        is_coderef(sub {});       # pass
        is_globref(*is_integer);  # fail
        is_globref(\*is_integer); # pass
        is_refref(\1);            # fail
        is_refref(\\1);           # pass

        if(regex_supported()) {
            is_regex(1);              # fail
            is_regex(qr/abc/);        # pass
        }

        if(bool_supported()) {
            is_bool(1==1, "pass");
            is_bool(1==2, "pass");
            is_bool(1,    "fail");
            is_integer(1==1, "fail");
            is_number(1==1, "fail");
            is_integer(1==2, "fail");
            is_number(1==2, "fail");
        }
    };

    is($events->[0]->name, "wow, a pass!", "test names emitted correctly when supplied");
    is($events->[1]->name, undef, "no name supplied? no name emitted");

    foreach my $test (
        { result => 'Pass', name => 'is_integer(1)'   },
        { result => 'Fail', name => 'is_integer(1.2)' },
        { result => 'Fail', name => 'is_integer("1")' },

        { result => 'Pass', name => 'is_number(1)'    },
        { result => 'Pass', name => 'is_number(1.2)'  },
        { result => 'Fail', name => 'is_number("1")'  },

        { result => 'Pass', name => 'is_positive(1.2)'   },
        { result => 'Fail', name => 'is_positive(-1.2)'  },
        { result => 'Pass', name => 'is_negative(-1.2)'  },
        { result => 'Fail', name => 'is_negative(1.2)'   },

        { result => 'Pass', name => 'is_positive("1.2")'  },
        { result => 'Pass', name => 'is_negative("-1.2")' },

        { result => 'Fail', name => 'is_ref(1)'                },
        { result => 'Pass', name => 'is_ref(\\1)'              },
        { result => 'Fail', name => 'is_object(1)'             },
        { result => 'Pass', name => 'is_object(bless {})'      },
        { result => 'Fail', name => 'is_hashref([])'           },
        { result => 'Pass', name => 'is_hashref({})'           },
        { result => 'Fail', name => 'is_arrayref({})'          },
        { result => 'Pass', name => 'is_arrayref([])'          },
        { result => 'Fail', name => 'is_scalarref(sub {})'     },
        { result => 'Pass', name => 'is_scalarref(\"")'        },
        { result => 'Fail', name => 'is_coderef(\""'           },
        { result => 'Pass', name => 'is_coderef(sub {})'       },
        { result => 'Fail', name => 'is_globref(*is_integer)'  },
        { result => 'Pass', name => 'is_globref(\*is_integer)' },
        { result => 'Fail', name => 'is_refref(\\1)'           },
        { result => 'Pass', name => 'is_refref(\\\\1)'         },

        { result => 'Fail', name => 'is_regex(1)',       regex_required => 1 },
        { result => 'Pass', name => 'is_regex(qr/abc/)', regex_required => 1 },

        { result => 'Pass', name => 'is_bool(1==1)',    bool_required => 1 },
        { result => 'Pass', name => 'is_bool(1==2)',    bool_required => 1 },
        { result => 'Fail', name => 'is_bool(1)',       bool_required => 1 },
        { result => 'Fail', name => 'is_integer(1==1)', bool_required => 1 },
        { result => 'Fail', name => 'is_number(1==1)',  bool_required => 1 },
        { result => 'Fail', name => 'is_integer(1==2)', bool_required => 1 },
        { result => 'Fail', name => 'is_number(1==2)',  bool_required => 1 },
    ) {
        my $event = shift(@{$events});
        SKIP: {
            skip "Your perl doesn't support the regex type"
                if($test->{regex_required} && !regex_supported());
            skip "Your perl doesn't support the Boolean type"
                if($test->{bool_required} && !bool_supported());
            isa_ok(
                $event,
                ["Test2::Event::".$test->{result}],
                $test->{name}."\t".$test->{result}
            );
        }
    }

    if(!regex_supported()) {
        like
            dies { is_regex(1==1) },
            qr/You need perl 5.12/,
            "is_regex: perl too old, exception";
    } else {
        is_regex(qr/abc/, "regex_supported on your perl");
    }
    if(!bool_supported()) {
        like
            dies { is_bool(1==1) },
            qr/You need perl 5.36/,
            "is_bool: perl too old, exception";
    } else {
        is_bool(1==1, "bool_supported on your perl");
    }
};

subtest "type() tests" => sub {
    my $events = intercept {
        # NB order is important! if you insert or remove tests, some of the checks
        # that failure messages are correct in like()s below may fail!
        is(1,   type('integer'));  # pass
        is(1.2, type('integer'));  # fail
        is(1,   !type('integer')); # fail
        is(1.2, !type('integer')); # pass

        is(1.2, type('number'));   # pass

        is('1.2', !type('positive', 'number')); # pass
        is('1.2', type('positive', 'number')); # fail
        is(1.2,   type('positive', 'number')); # pass
        is(-1.2,  type('positive', 'number')); # fail
        is(-1.2,  type('negative', 'number')); # pass
        is(-1.2,  type('negative', 'integer')); # fail

        is(-1.2,  type('number', number(-1.1))); # fail
        is(-1.2,  type('number', number(-1.2))); # pass

        is(4, type(integer => in_set(1, 5, 8))); # fail
        is(4, type(integer => in_set(1, 4, 8))); # pass

        is(  # pass
            { int => 1, chicken => 'bird', elephant => 'seal' },
            type(
                'hashref',
                hash {
                    field int      => 1;
                    field chicken  => 'bird';
                    field elephant => 'seal'
                }
            )
        );
        is(  # fail
            { int => 1, chicken => 'bird', elephant => 'seal' },
            type(
                'hashref',
                hash {
                    field int     => 1;
                    field chicken => 'coward';
                }
            )
        );
        is(  # fail
            bless({ int => 1, chicken => 'bird', elephant => 'seal' }),
            type(
                !type('object'),
                'hashref',
                hash {
                    field int      => 1;
                    field chicken  => 'bird';
                    field elephant => 'seal';
                }
            )
        );

        if(bool_supported()) {
            is(1==1, type('bool')); # pass
            is(1==2, type('bool')); # pass
            is(1.2,  type('bool')); # fail
        }
    };

    like(
        $events->[1]->info->[0]->details,
        qr/\bis of type .* integer\b/,
        "failed test, op and name emitted in diagnostics are correct"
    );
    like(
        $events->[2]->info->[0]->details,
        qr/is not of type/,
        "failed negated test, op emitted in diagnostics is correct"
    );
    like(
        $events->[6]->info->[0]->details,
        qr/\bis of type .* positive and number\b/,
        "failed test, op and multi-name emitted in diagnostics are correct"
    );
    like(
        $events->[11]->info->[0]->details,
        qr/\bis of type .* number and Test2::Compare::Number /,
        "failed test, op and name with 'has value' emitted in diagnostics are correct"
    );
    like(
        $events->[13]->info->[0]->details,
        qr/\bis of type .* integer and Test2::Compare::Set /,
        "failed test, op and name with another checker emitted in diagnostics are correct"
    );
    foreach my $test (
        { result => "Ok",   name => "is(1,    type('integer'))"  },
        { result => "Fail", name => "is(1.2,  type('integer'))"  },
        { result => "Fail", name => "is(1,    !type('integer'))" },
        { result => "Ok",   name => "is(1.2,  !type('integer'))" },

        { result => "Ok",   name => "is(1.2,  type('number'))"   },

        { result => "Ok",   name => "is('1.2', !type('positive', 'number'))"  },
        { result => "Fail", name => "is('1.2', type('positive', 'number'))"   },
        { result => "Ok",   name => "is(1.2,   type('positive', 'number'))"   },
        { result => "Fail", name => "is(-1.2,  type('positive', 'number'))"   },
        { result => "Ok",   name => "is(-1.2,  type('negative', 'number'))"   },
        { result => "Fail", name => "is(-1.2,  type('negative', 'integer'))"   },

        { result => "Fail", name => "is(-1.2,  type('number', -1.1))" },
        { result => "Ok",   name => "is(-1.2,  type('number', -1.2))" },

        { result => "Fail", name => "is(4, type(integer => in_set(1, 5, 8)))" },
        { result => "Ok",   name => "is(4, type(integer => in_set(1, 4, 8)))" },

        { result => "Ok",   name => "is({ ... },        type(hashref => { same }))"         },
        { result => "Fail", name => "is({ ... },        type(hashref => { not the same }))" },
        { result => "Fail", name => "is(bless({ ... }), type(!type('object'), hashref => { same }))" },

        { result => "Ok",   name => "is(1==1, type('bool'))", bool_required => 1 },
        { result => "Ok",   name => "is(1==2, type('bool'))", bool_required => 1 },
        { result => "Fail", name => "is(1.2,  type('bool'))", bool_required => 1 },
    ) {
        my $event = shift(@{$events});
        SKIP: {
            skip "Your perl doesn't support the Boolean type"
                if($test->{bool_required} && !bool_supported());
            isa_ok(
                $event,
                ["Test2::Event::".$test->{result}],
                $test->{name}."\t".$test->{result}
            );
        }
    }

    if(!bool_supported()) {
        like
            dies { is(1, type('bool')) },
            qr/You need perl 5.36/,
            "type('bool'): perl too old, exception";
    }

    like
        dies { type() },
        qr/'type' requires at least one argument/,
        "argument is mandatory";

    like
        dies { type('mammal') },
        qr/'mammal' is not a valid argument, must either be Test2::Tools::Type checkers or Test2::Compare::\* object/,
        "exception: 'mammal' isn't a valid argument to type()";
    like
        dies { type('hashref' => { foo => 'bar' }) },
        qr/'HASH.*' is not a valid argument/,
        "exception: random data isn't a valid argument either";
};

subtest "checks don't mess with types" => sub {
    my $events = intercept {
        my $integer = 1;
        is_integer($integer);    # pass
        is_positive($integer);
        is_ref($integer);
        is_object($integer);
        is_hashref($integer);
        is_negative($integer);
        is_zero($integer);
        is($integer, !type(qw(integer positive negative zero))); # LOL
        is_integer($integer);    # pass
    };
    isa_ok(
        $events->[0],
        ['Test2::Event::Pass'],
        "starting with an int"
    );
    isa_ok(
        $events->[-1],
        ['Test2::Event::Pass'],
        "is_{positive,negative,zero} and ref/reftype/blessed don't accidentally un-intify an int"
    );

    $events = intercept {
        my $number = 1.1;
        is_integer($number);   # fail
        is_positive($number);
        is_ref($number);
        is_object($number);
        is_hashref($number);
        is_negative($number);
        is_zero($number);
        is($number, type(qw(integer positive negative zero))); # LOL
        is_number($number);    # pass
    };
    isa_ok(
        $events->[0],
        ['Test2::Event::Fail'],
        "starting with a float"
    );
    isa_ok(
        $events->[-1],
        ['Test2::Event::Pass'],
        "is_{positive,negative,zero} and ref/reftype/blessed don't accidentally intify a float"
    );

    $events = intercept {
        my $string = "1.1";
        is_number($string);    # fail
        is_positive($string);
        is_ref($string);
        is_object($string);
        is_hashref($string);
        is_negative($string);
        is_zero($string);
        is($string, type(qw(integer positive negative zero))); # LOL
        is_number($string);    # fail
    };
    isa_ok(
        $events->[0],
        ['Test2::Event::Fail'],
        "starting with a string"
    );
    isa_ok(
        $events->[-1],
        ['Test2::Event::Fail'],
        "is_{positive,negative,zero} and ref/reftype/blessed don't accidentally numify a string"
    );
};

done_testing;
