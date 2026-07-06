#!perl
use v5.36.0;
use lib 't/lib';

use Sieve::Generator::Sugar '-all';
use Sieve::Generator::Element::BracketComment;
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
  my $snooze = Sieve::Generator::Element::Command->new({
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
    qq{snooze :addflags [ "\$new" ] :mailboxid "000-111-222" :times [ "9:00", "12:00" ] :tzid "America/New_York" :weekdays [ "1", "2", "5" ];},
    "can force long command to be one line",
  );
}

sieve_is(
  ifelse(test('true'), block(command('stop'))),
  <<~'END',
  if true {
    stop;
  }
  END
  "single-command if block"
);

sieve_is(
  ifelse(test('true'), command('stop')),
  <<~'END',
  if true stop;
  END
  "single-command if, no block"
);

sieve_is(
  ifelse(
    test('true'),
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
  ifelse(negate(hasflag('\Seen')), block(command('stop'))),
  <<~'END',
  if not hasflag "\\Seen" {
    stop;
  }
  END
  "negate(hasflag(...))"
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
  ifelse(test(size => { over => undef }, number(100, 'K')), block(command('stop'))),
  <<~'END',
  if size :over 100K {
    stop;
  }
  END
  "size with number"
);

sieve_is(
  ifelse(test(size => { over => undef }, number(5, 'm')), block(command('stop'))),
  <<~'END',
  if size :over 5M {
    stop;
  }
  END
  "number with lowercase suffix is uppercased"
);

sieve_is(
  command('whatever', number(42)),
  qq{whatever 42;\n},
  "number with no suffix"
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

sieve_is(
  Sieve::Generator::Element::Heredoc->new({ text => "body\n", comment => "This is a comment" }),
  "text: # This is a comment\nbody\n.\n",
  "heredoc with comment on text: line"
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

# block item built with command sugar
sieve_is(
  ifelse(test('true'), block(command('keep'))),
  <<~'END',
  if true {
    keep;
  }
  END
  "block item built with command sugar"
);

# document item built with command sugar
sieve_is(
  sieve(command('stop')),
  "stop;\n",
  "document item built with command sugar"
);

# multiline condition indented correctly when nested
sieve_is(
  sieve(
    ifelse(
      test('outer'),
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
      test('outer'),
      block(
        ifelse(
          test('inner'),
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
  Sieve::Generator::Element::IfElse->new({
    cond => test('true'),
    true => block(command('stop')),
  }),
  <<~'END',
  if true {
    stop;
  }
  END
  "IfElse constructed directly with no elses"
);

# command with heredoc args
sieve_is(
  command('somecommand', { tag => heredoc("tag value") }, heredoc("first"), heredoc("second")),
  <<~'END',
  somecommand :tag text:
  tag value
  .
  text:
  first
  .
  text:
  second
  .
  ;
  END
  "command with tagged and positional heredoc args"
);

sieve_is(
  ifelse(
    negate(test(foo => { is => undef }, 'xyz')),
    block(command('stop'))
  ),
  <<~'END',
  if not foo :is "xyz" {
    stop;
  }
  END
  "negate wraps a test in not"
);

{
  my $doc = sieve(var_eq(true => 'Y'));
  sieve_is($doc, qq[string :is "\${true}" "Y"\n], "var_eq");
}

# command with block
sieve_is(
  Sieve::Generator::Element::Command->new({
    identifier => 'foreverypart',
    block      => block(command('discard')),
  }),
  <<~'END',
  foreverypart {
    discard;
  }
  END
  "command with block"
);

sieve_is(
  Sieve::Generator::Element::Command->new({
    identifier      => 'foreverypart',
    tagged_args     => { name => [] },
    block           => block(command('discard')),
  }),
  <<~'END',
  foreverypart :name {
    discard;
  }
  END
  "command with tagged arg and block"
);

# bracket comment
sieve_is(
  sieve(
    Sieve::Generator::Element::BracketComment->new({ content => 'this is a comment' }),
    command('stop'),
  ),
  <<~'END',
  /* this is a comment */
  stop;
  END
  "bracket comment in a document"
);

# -- find_elements --------------------------------------------------------

{
  my $doc = sieve(
    command('require', ['fileinto', 'imap4flags']),
    blank(),
    ifelse(
      test(exists => 'X-Spam'),
      block(
        command('addflag', '$Junk'),
        command('fileinto', 'Spam'),
      ),
    ),
    command('keep'),
  );

  my @commands = $doc->find_elements(sub ($el) {
    $el->isa('Sieve::Generator::Element::Command') && $el->semicolon
  });
  is(scalar @commands, 4, "find_elements: found all 4 commands");
  is($commands[0]->identifier, 'require', "find_elements: first is require");
  is($commands[3]->identifier, 'keep',    "find_elements: last is keep");

  my @fileinto = $doc->find_elements(sub ($el) {
    $el->isa('Sieve::Generator::Element::Command')
      && $el->identifier eq 'fileinto'
  });
  is(scalar @fileinto, 1, "find_elements: found fileinto inside if block");

  my @blocks = $doc->find_elements(sub ($el) {
    $el->isa('Sieve::Generator::Element::Block')
  });
  is(scalar @blocks, 1, "find_elements: found the one block");

  my @leaves = $doc->find_elements(sub ($el) {
    $el->isa('Sieve::Generator::Element::Qstr')
  });
  is(scalar @leaves, 3, "find_elements: found 3 Qstr leaves");
}

done_testing;
