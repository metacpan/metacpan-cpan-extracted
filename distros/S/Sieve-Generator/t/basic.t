#!perl
use v5.36.0;
use lib 't/lib';

use Sieve::Generator::Sugar '-all';
use Test::GeneratedSieve '-all';

use Test::More;

sieve_is(
  sieve(
    command("require", qstr([ qw( food thanksgiving ) ])),
    blank(),
    ifelse(
      anyof(
        terms("pie :is baked"),
        terms("cake :is iced"),
      ),
      block(terms("print", qstr("dessert!"))),

      allof(
        terms("turkey :is carved"),
        anyof(
          terms("rolls", ":are", qstr("buttered")),
          test(sides => { are => [ qw(taters yams) ] } => 'creamed'),
        ),
      ),
      block(terms("print", qstr("dinner"))),

      block(comment("...keep waiting...")),
    )
  ),
  <<~'END',
  require [ "food", "thanksgiving" ];

  if anyof(
    pie :is baked,
    cake :is iced
  ) {
    print "dessert!"
  } elsif allof(
    turkey :is carved,
    anyof(
      rolls :are "buttered",
      sides :are [ "taters", "yams" ] "creamed"
    )
  ) {
    print "dinner"
  } else {
    # ...keep waiting...
  }
  END
  "long but simple composite"
);

sieve_is(
  ifelse(
    terms(specialuse_exists => qstr('\Snoozed')),
    block(
      command(snooze => {
        'addflags'  => qstr([ '$new' ]),
        'mailboxid' => qstr("000-111-222"),
        'times'     => qstr([ '9:00', '12:00' ]),
        'tzid'      => qstr('America/New_York'),
        'weekdays'  => qstr([ 1, 2, 5 ])
      }),
    )
  ),
  <<~'END',
  if specialuse_exists "\\Snoozed" {
    snooze :addflags [ "$new" ]
           :mailboxid "000-111-222"
           :times [ "9:00", "12:00" ]
           :tzid "America/New_York"
           :weekdays [ "1", "2", "5" ];
  }
  END
  "commands, generically formatted"
);

sieve_is(
  command('whatever', { novalue => undef }, 'xyzzy'),
  qq{whatever :novalue "xyzzy";\n},
  "tagged arg with no value",
);

sieve_is(
  test('whatever', { novalue => undef }, 'xyzzy'),
  qq{whatever :novalue "xyzzy"\n},
  "test is a command without a semicolon",
);

{
  my $snooze = Sieve::Generator::Lines::Command->new({
    identifier  => 'snooze',
    tagged_args => {
      addflags  => [ qstr([ '$new' ]) ],
      mailboxid => [ qstr("000-111-222") ],
      times     => [ qstr([ '9:00', '12:00' ]) ],
      tzid      => [ qstr('America/New_York') ],
      weekdays  => [ qstr([ 1, 2, 5 ]) ],
    }
  });

  sieve_is(
    ifelse(
      terms(specialuse_exists => qstr('\Snoozed')),
      block($snooze),
    ),
    <<~'END',
    if specialuse_exists "\\Snoozed" {
      snooze :addflags [ "$new" ]
             :mailboxid "000-111-222"
             :times [ "9:00", "12:00" ]
             :tzid "America/New_York"
             :weekdays [ "1", "2", "5" ];
    }
    END
    "commands, prettily formatted"
  );

  is(
    $snooze->_as_sieve_oneline,
    qq{snooze :addflags [ "\$new" ] :mailboxid "000-111-222" :times [ "9:00", "12:00" ] :tzid "America/New_York" :weekdays [ "1", "2", "5" ];\n},
    "can force long command to be one line",
  );
}

sieve_is(
  ifelse('true', block(command('stop'))),
  <<~'END',
  if true {
    stop;
  }
  END
  "single-command if block"
);

sieve_is(
  ifelse('true', command('stop')),
  <<~'END',
  if true stop;
  END
  "single-command if, no block"
);

sieve_is(
  ifelse(
    'true',
    block(
      set('stopping', 'Y'),
      command('stop')
    )
  ),
  <<~'END',
  if true {
    set "stopping" "Y";
    stop;
  }
  END
  "the set sugar"
);

sieve_is(
  sieve(
    comment("Important rule!!", { hashes => 3 }),
    ifelse(
      terms('jmapquery', qstr('{"someInThreadHaveKeyword":"$followed"}')),
      block(
        set('threadstatus', 'muted'),
        command('addflag', qstr('$muted')),
      ),
    )
  ),
  <<~'END',
  ### Important rule!!
  if jmapquery "{\"someInThreadHaveKeyword\":\"$followed\"}" {
    set "threadstatus" "muted";
    addflag "$muted";
  }
  END
  "multi-hash comment"
);

sieve_is(
  ifelse(test(exists => "X-Spam-Status"), block(command('stop'))),
  <<~'END',
  if exists "X-Spam-Status" {
    stop;
  }
  END
  "header exists"
);

sieve_is(
  ifelse(test('not exists', "X-Spam-Status"), block(command('stop'))),
  <<~'END',
  if not exists "X-Spam-Status" {
    stop;
  }
  END
  "header not exists"
);

sieve_is(
  ifelse(hasflag('\Seen'), block(command('stop'))),
  <<~'END',
  if hasflag "\\Seen" {
    stop;
  }
  END
  "hasflag"
);

sieve_is(
  ifelse(
    test(string => { is => undef }, '${stop}', 'Y'),
    block(command('stop'))
  ),
  <<~'END',
  if string :is "${stop}" "Y" {
    stop;
  }
  END
  "string_test"
);

sieve_is(
  ifelse(
    test('not string' => { is => undef }, '${stop}', 'Y'),
    block(command('stop'))
  ),
  <<~'END',
  if not string :is "${stop}" "Y" {
    stop;
  }
  END
  "not_string_test"
);

sieve_is(
  ifelse(test(size => { over => undef }, \'100K'), block(command('stop'))),
  <<~'END',
  if size :over 100K {
    stop;
  }
  END
  "size"
);

sieve_is(
  ifelse(bool(1), block(command('stop'))),
  <<~'END',
  if true {
    stop;
  }
  END
  "bool true"
);

sieve_is(
  ifelse(bool(0), block(command('stop'))),
  <<~'END',
  if false {
    stop;
  }
  END
  "bool false"
);

# heredoc
sieve_is(
  heredoc("line one\nline two\n"),
  "text:\nline one\nline two\n.\n",
  "heredoc basic"
);

sieve_is(
  heredoc("no trailing newline"),
  "text:\nno trailing newline\n.\n",
  "heredoc adds trailing newline when absent"
);

sieve_is(
  heredoc(".first line starts with dot\nnormal line\n"),
  "text:\n..first line starts with dot\nnormal line\n.\n",
  "heredoc escapes leading dots"
);

# noneof (also covers Junction noneof branch)
sieve_is(
  ifelse(
    noneof(
      terms("pie :is baked"),
      terms("cake :is iced"),
    ),
    block(command('stop'))
  ),
  <<~'END',
  if not anyof(
    pie :is baked,
    cake :is iced
  ) {
    stop;
  }
  END
  "noneof"
);

# comment with ref content
sieve_is(
  sieve(comment(terms("some condition"))),
  "# some condition\n",
  "comment with ref content"
);

# block with plain string item
sieve_is(
  ifelse('true', block("keep;")),
  <<~'END',
  if true {
    keep;
  }
  END
  "block with plain string item"
);

# document with plain string item
sieve_is(
  sieve("stop;"),
  "stop;\n",
  "document with plain string item"
);

# multiline condition indented correctly when nested
sieve_is(
  sieve(
    ifelse(
      'outer',
      block(
        ifelse(
          anyof(
            terms('foo :is bar'),
            terms('baz :is qux'),
          ),
          block(command('stop')),
        )
      )
    )
  ),
  <<~'END',
  if outer {
    if anyof(
      foo :is bar,
      baz :is qux
    ) {
      stop;
    }
  }
  END
  "multiline condition indented correctly when nested"
);

# else clause indentation when nested
sieve_is(
  sieve(
    ifelse(
      'outer',
      block(
        ifelse(
          'inner',
          block(command('stop')),
          block(command('keep')),
        )
      )
    )
  ),
  <<~'END',
  if outer {
    if inner {
      stop;
    } else {
      keep;
    }
  }
  END
  "else clause indented correctly when nested"
);

# IfElse constructed directly without elses attribute
sieve_is(
  Sieve::Generator::Lines::IfElse->new({
    cond => 'true',
    true => block(command('stop')),
  }),
  <<~'END',
  if true {
    stop;
  }
  END
  "IfElse constructed directly with no elses"
);

# Document::append
{
  my $doc = sieve(command('stop'));
  $doc->append(command('keep'));
  sieve_is($doc, "stop;\nkeep;\n", "Document::append");
}

{
  my $doc = sieve(var_eq(true => 'Y'));
  sieve_is($doc, qq[string :is "\${true}" "Y"\n], "var_eq");
}

done_testing;
