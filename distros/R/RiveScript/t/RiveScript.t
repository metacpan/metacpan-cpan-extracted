#!/usr/bin/perl

# RiveScript Unit Tests
use utf8;
use strict;
use Test::More tests => 162;

binmode(STDOUT, ":utf8");

use_ok('RiveScript');
my @tests;

# Constants.
my $MATCH = RiveScript::RS_ERR_MATCH();
my $REPLY = RiveScript::RS_ERR_REPLY();

#-----------------------------------------------------------------------------#
# Begin Block Tests                                                           #
#-----------------------------------------------------------------------------#

push @tests, sub {
    # No begin blocks.
    my $rs = bot("
        + hello bot
        - Hello human.
    ");
    test($rs, "Hello Bot", "Hello human.", "No begin block.");
    test($rs, "How are you?", $MATCH, "No trigger matched.");
};

push @tests, sub {
    # Simple begin blocks.
    my $rs = bot("
        > begin
            + request
            - {ok}
        < begin

        + hello bot
        - Hello human.
    ");
    test($rs, "Hello Bot", "Hello human.", "Simple begin block.");
};

push @tests, sub {
    # 'Blocked' begin blocks.
    my $rs = bot("
        > begin
            + request
            - Nope.
        < begin

        + hello bot
        - Hello human.
    ");
    test($rs, "Hello Bot", "Nope.", "Begin blocks access to real reply.");
};

push @tests, sub {
    # Conditional begin blocks.
    my $rs = bot("
        > begin
            + request
            * <get met> == undefined => <set met=true>{ok}
            * <get name> != undefined => <get name>: {ok}
            - {ok}
        < begin

        + hello bot
        - Hello human.

        + my name is *
        - <set name=<formal>>Hello, <get name>.
    ");
    test($rs, 'Hello bot.', 'Hello human.', 'Trigger works.');
    tv($rs, 'met', 'true', '"met" variable set to true.');
    tv($rs, 'name', undef, '"name" is still undefined.');
    test($rs, 'My name is bob', 'Hello, Bob.', 'Set user name.');
    tv($rs, 'name', 'Bob', '"name" was successfully set.');
    test($rs, 'Hello Bot', 'Bob: Hello human.', 'Name condition worked.');
};

#-----------------------------------------------------------------------------#
# Bot vars & substitutions                                                    #
#-----------------------------------------------------------------------------#

push @tests, sub {
    # Bot vars.
    my $rs = bot("
        ! var name = Aiden
        ! var age  = 5

        + what is your name
        - My name is <bot name>.

        + how old are you
        - I am <bot age>.

        + what are you
        - I'm <bot gender>.

        + happy birthday
        - <bot age=6>Thanks!
    ");
    test($rs, 'What is your name?', 'My name is Aiden.', 'Bot name.');
    test($rs, 'How old are you?', 'I am 5.', 'Bot age.');
    test($rs, 'What are you?', "I'm undefined.", 'Undefined bot variable.');
    test($rs, 'Happy birthday!', 'Thanks!', 'Set bot variable.');
    test($rs, 'How old are you?', 'I am 6.', 'Bot age was updated.');
};

push @tests, sub {
    # Global vars.
    my $rs = bot("
        ! global debug = false

        + debug mode
        - Debug mode is: <env debug>

        + set debug mode *
        - <env debug=<star>>Switched to <star>.
    ");
    test($rs, 'Debug mode.', 'Debug mode is: false', 'Global variable test.');
    test($rs, 'Set debug mode true', 'Switched to true.', 'Change global variable.');
    test($rs, 'Debug mode?', 'Debug mode is: true', 'Global variable was updated.');
};

push @tests, sub {
    # Before and after subs.
    my $rs = bot("
        + whats up
        - nm.

        + what is up
        - Not much.
    ");
    test($rs, 'whats up', 'nm.', 'Literal "whats up"');
    test($rs, 'what\'s up', 'nm.', 'Literal "what\'s up"');
    test($rs, 'what is up', 'Not much.', 'Literal "what is up"');

    # Add subs
    extend($rs, "
        ! sub whats  = what is
        ! sub what's = what is
    ");
    test($rs, 'whats up', 'Not much.', 'Literal "whats up"');
    test($rs, 'what\'s up', 'Not much.', 'Literal "what\'s up"');
    test($rs, 'what is up', 'Not much.', 'Literal "what is up"');
};

push @tests, sub {
    # Before and after person subs.
    my $rs = bot("
        + say *
        - <person>
    ");
    test($rs, 'say i am cool', 'i am cool', 'Person substitution 1');
    test($rs, 'say you are dumb', 'you are dumb', 'Person substitution 2');

    extend($rs, "
        ! person i am    = you are
        ! person you are = I am
    ");
    test($rs, 'say i am cool', 'you are cool', 'Person substitution 3');
    test($rs, 'say you are dumb', 'I am dumb', 'Person substitution 4');
};

#-----------------------------------------------------------------------------#
# Triggers                                                                    #
#-----------------------------------------------------------------------------#

push @tests, sub {
    # Atomic & Wildcard
    my $rs = bot("
        + hello bot
        - Hello human.

        + my name is *
        - Nice to meet you, <star>.

        + * told me to say *
        - Why did <star1> tell you to say <star2>?

        + i am # years old
        - A lot of people are <star>.

        + i am _ years old
        - Say that with numbers.

        + i am * years old
        - Say that with fewer words.
    ");
    test($rs, 'hello bot', 'Hello human.', 'Atomic trigger.');
    test($rs, 'my name is Bob', 'Nice to meet you, bob.', 'One star.');
    test($rs, 'bob told me to say hi', 'Why did bob tell you to say hi?',
        'Two stars.');
    test($rs, 'i am 5 years old', 'A lot of people are 5.', 'Number wildcard.');
    test($rs, 'i am five years old', 'Say that with numbers.',
        'Underscore wildcard.');
    test($rs, 'i am twenty five years old', 'Say that with fewer words.',
        'Star wildcard.');
};

push @tests, sub {
    # Alternatives & Optionals
    my $rs = bot("
        + what (are|is) you
        - I am a robot.

        + what is your (home|office|cell) [phone] number
        - It is 555-1234.

        + [please|can you] ask me a question
        - Why is the sky blue?

        + (aa|bb|cc) [bogus]
        - Matched.

        + (yo|hi) [computer|bot] *
        - Matched.
    ");
    test($rs, 'what are you', 'I am a robot.', 'Alternatives 1.');
    test($rs, 'what is you', 'I am a robot.', 'Alternatives 2.');
    foreach my $kind (qw(home office cell)) {
        test($rs, "what is your $kind phone number", 'It is 555-1234.',
            "Alternatives & optionals - $kind.");
        test($rs, "what is your $kind number", 'It is 555-1234.',
            "Alternatives & optionals - $kind.");
    }
    test($rs, 'can you ask me a question', 'Why is the sky blue?',
        'Optionals 1.');
    test($rs, 'ask me a question', 'Why is the sky blue?',
        'Optionals 2.');
    test($rs, 'please ask me a question', 'Why is the sky blue?',
        'Optionals 3.');

    test($rs, "aa", "Matched.", "Optionals 4.");
    test($rs, "bb", "Matched.", "Optionals 5.");
    test($rs, "aa bogus", "Matched.", "Optionals 6.");
    test($rs, "aabogus", $MATCH, "Optionals 7.");
    test($rs, "bogus", $MATCH, "Optionals 8.");

    test($rs, "hi Aiden", "Matched.", "Optionals 9.");
    test($rs, "hi bot how are you?", "Matched.", "Optionals 10.");
    test($rs, "yo computer what time is it?", "Matched.", "Optionals 11.");
    test($rs, "yoghurt is yummy", $MATCH, "Optionals 12.");
    test($rs, "hide and seek is fun", $MATCH, "Optionals 13.");
    test($rs, "hip hip hurrah", $MATCH, "Optionals 14.");
};

push @tests, sub {
    # Arrays.
    my $rs = bot('
        ! array colors = red blue green yellow white
          ^ dark blue|light blue

        + what color is my (@colors) *
        - Your <star2> is <star1>.

        + what color was * (@colors) *
        - It was <star2>.

        + i have a @colors *
        - Tell me more about your <star>.
    ');
    test($rs, 'what color is my red shirt', 'Your shirt is red.',
        'Array with wildcards 1.');
    test($rs, 'what color is my blue car', 'Your car is blue.',
        'Array with wildcards 2.');
    test($rs, 'what color is my pink house', $MATCH,
        'Array doesn\'t match message.');
    test($rs, 'what color is my dark blue jacket', 'Your jacket is dark blue.',
        'Array with wildcards 3.');

    test($rs, 'What color was Napoleon\'s white horse?', 'It was white.',
        'Array with wildcards 3.');
    test($rs, 'What color was my red shirt?', 'It was red.',
        'Array with wildcards 4.');

    test($rs, 'I have a blue car', 'Tell me more about your car.',
        'Non-capturing array.');
    test($rs, 'I have a cyan car', $MATCH,
        'Non-capturing array doesn\'t match message.');
};

push @tests, sub {
    # Priority triggers.
    my $rs = bot('
        + * or something{weight=10}
        - Or something. <@>

        + can you run a google search for *
        - Sure!

        + hello *{weight=20}
        - Hi there!
    ');
    test($rs, 'Hello robot', 'Hi there!', 'Highest weight trigger (20).');
    test($rs, 'Hello or something', 'Hi there!',
        'Weight of 20 is higher than 10.');
    test($rs, 'Can you run a Google search for Perl', 'Sure!',
        'Normal trigger.');
    test($rs, 'Can you run a Google search for Python or something',
        'Or something. Sure!', 'Higher weight trigger matched over normal.');
};

#-----------------------------------------------------------------------------#
# Responses                                                                   #
#-----------------------------------------------------------------------------#

# TODO: no way to reliably test random responses in a way that doesn't create
# a slim chance that the unit tests will fail?

push @tests, sub {
    # %Previous.
    my $rs = bot("
        ! sub who's  = who is
        ! sub it's   = it is
        ! sub didn't = did not

        + knock knock{weight=1}
        - Who's there?

        + *
        % who is there
        - <star> who?

        + *
        % * who
        - Haha! <star>!

        + *
        - I don't know.
    ");
    test($rs, 'knock knock', "Who's there?", 'Knock-knock joke pt1.');
    test($rs, 'Canoe', 'canoe who?', 'Knock-knock joke pt2.');
    test($rs, 'Canoe help me with my homework?',
        'Haha! canoe help me with my homework!', 'Knock-knock joke pt3.');

    test($rs, 'hello', "I don't know.", 'Normal catch-all still works.');
};

push @tests, sub {
    # Continuations.
    my $rs = bot('
        + tell me a poem
        - There once was a man named Tim,\s
        ^ who never quite learned how to swim.\s
        ^ He fell off a dock, and sank like a rock,\s
        ^ and that was the end of him.
    ');
    test($rs, 'Tell me a poem.', "There once was a man named Tim, "
        . "who never quite learned how to swim. "
        . "He fell off a dock, and sank like a rock, "
        . "and that was the end of him.",
        'Continuation for a multi-line poem.');
};

push @tests, sub {
    # Redirects.
    my $rs = bot('
        + hello
        - Hi there!

        + hey
        @ hello

        + hi there
        - {@hello}
    ');
    foreach my $greet ('hello', 'hey', 'hi there') {
        test($rs, $greet, 'Hi there!', "Redirect w/ greeting: $greet");
    }
};

push @tests, sub {
    # Conditional testing.
    my $rs = bot("
        + i am # years old
        - <set age=<star>>OK.

        + what can i do
        * <get age> == undefined => I don't know.
        * <get age> > 25  => Anything you want.
        * <get age> == 25 => Rent a car for cheap.
        * <get age> >= 21 => Drink.
        * <get age> >= 18 => Vote.
        * <get age> < 18  => Not much of anything.

        + am i your master
        * <get master> == true => Yes.
        - No.
    ");
    my $q = 'What can I do?';
    test($rs, $q, "I don't know.", "Conditions 1.");
    test($rs, 'I am 16 years old.', 'OK.', "Set age=16.");
    test($rs, $q, "Not much of anything.", "Conditions 2.");
    test($rs, 'I am 18 years old.', 'OK.', "Set age=18.");
    test($rs, $q, "Vote.", "Conditions 3.");
    test($rs, 'I am 20 years old.', 'OK.', "Set age=20.");
    test($rs, $q, "Vote.", "Conditions 4.");
    test($rs, 'I am 22 years old.', 'OK.', "Set age=22.");
    test($rs, $q, "Drink.", "Conditions 5.");
    test($rs, 'I am 24 years old.', 'OK.', "Set age=24.");
    test($rs, $q, "Drink.", "Conditions 6.");
    test($rs, 'I am 25 years old.', 'OK.', "Set age=25.");
    test($rs, $q, "Rent a car for cheap.", "Conditions 7.");
    test($rs, 'I am 27 years old.', 'OK.', "Set age=27.");
    test($rs, $q, "Anything you want.", "Conditions 8.");

    test($rs, 'Am I your master?', 'No.', 'Conditions 9.');
    $rs->setUservar('user', 'master' => 'true');
    test($rs, 'Am I your master?', 'Yes.', 'Conditions 10.');
};

push @tests, sub {
    # Embedded Tag Testing
    my $rs = bot("
        + my name is *
        * <get name> != undefined => <set oldname=<get name>>I thought\\s
          ^ your name was <get oldname>?
          ^ <set name=<formal>>
        - <set name=<formal>>OK.

        + what is my name
        - Your name is <get name>, right?

        + html test
        - <set name=<b>Name</b>>This has some non-RS <em>tags</em> in it.
    ");
    test($rs, "What is my name?", "Your name is undefined, right?", "Embed tag test 1.");
    test($rs, "My name is Alice.", "OK.", "Embed tag test 2.");
    test($rs, "My name is Bob.", "I thought your name was Alice?", "Embed tag test 3.");
    test($rs, "What is my name?", "Your name is Bob, right?", "Embed tag test 4.");
    test($rs, "HTML Test", "This has some non-RS <em>tags</em> in it.", "Embed tag test 5.");
};

#-----------------------------------------------------------------------------#
# Object Macros                                                               #
#-----------------------------------------------------------------------------#

push @tests, sub {
    # Perl objects.
    my $rs = bot('
        > object nolang
            return "Test w/o language.";
        < object

        > object wlang perl
            return "Test w/ language.";
        < object

        > object reverse perl
            my ($rs, @args) = @_;
            my $msg = join " ", @args;
            my @char = split(//, $msg);
            return join "", reverse(@char);
        < object

        > object broken perl
            return "syntax error;
        < object

        > object foreign javascript
            return "JavaScript checking in!";
        < object

        + test nolang
        - Nolang: <call>nolang</call>

        + test wlang
        - Wlang: <call>wlang</call>

        + reverse *
        - <call>reverse <star></call>

        + test broken
        - Broken: <call>broken</call>

        + test fake
        - Fake: <call>fake</call>

        + test js
        - JS: <call>foreign</call>
    ');
    test($rs, 'Test nolang', 'Nolang: Test w/o language.',
        'Object macro with no language specified.');
    test($rs, 'Test wlang', 'Wlang: Test w/ language.',
        'Object macro with Perl language specified.');
    test($rs, 'Reverse hello world', 'dlrow olleh',
        'Test the reverse macro.');
    test($rs, 'Test broken', 'Broken: [ERR: Object Not Found]',
        'Test calling a broken object.');
    test($rs, 'Test JS', 'JS: [ERR: Object Not Found]',
        'Test calling a foreign language object.');
};

push @tests, sub {
    # Try Perl objects when it's been disabled.
    my $rs = RiveScript->new();
    $rs->setHandler(perl => undef);
    $rs->stream('
        > object test perl
            return "Perl here!";
        < object

        + test
        - Result: <call>test</call>
    ');
    $rs->sortReplies();

    test($rs, 'test', 'Result: [ERR: Object Not Found]',
        'Perl object macros disabled.');
};

push @tests, sub {
    # Try manually entered Perl objects.
    my $rs = RiveScript->new();
    $rs->setSubroutine("reverse", sub {
        my ($rs, @args) = @_;
        my $msg = join " ", @args;
        my @char = split("", $msg);
        return join "", reverse @char;
    });
    $rs->stream('
        + reverse *
        - <call>reverse <star></call>
    ');
    $rs->sortReplies();

    test($rs, "reverse hello world", "dlrow olleh", "Objects via setSubroutine");
};

#-----------------------------------------------------------------------------#
# Topics                                                                      #
#-----------------------------------------------------------------------------#

push @tests, sub {
    # Punishment topic.
    my $rs = bot("
        + hello
        - Hi there!

        + swear word
        - How rude! Apologize or I won't talk to you again.{topic=sorry}

        + *
        - Catch-all.

        > topic sorry
            + sorry
            - It's ok!{topic=random}

            + *
            - Say you're sorry!
        < topic
    ");
    test($rs, 'hello', 'Hi there!', 'Default topic 1.');
    test($rs, 'How are you?', 'Catch-all.', 'Default topic catch-all 1.');
    test($rs, 'Swear word!',
        "How rude! Apologize or I won't talk to you again.",
        'Entering a topic trap.');
    test($rs, 'hello', "Say you're sorry!", 'In-topic catch-all 1.');
    test($rs, 'how are you?', "Say you're sorry!", 'In-topic catch-all 2.');
    test($rs, 'Sorry!', "It's ok!", 'Escape the topic.');
    test($rs, 'hello', 'Hi there!', 'Default topic 2.');
    test($rs, 'How are you?', 'Catch-all.', 'Default topic catch-all 2.');
};

push @tests, sub {
    # Topic inheritence.
    my $rs = bot('
        > topic colors
            + what color is the sky
            - Blue.

            + what color is the sun
            - Yellow.
        < topic

        > topic linux
            + name a red hat distro
            - Fedora.

            + name a debian distro
            - Ubuntu.
        < topic

        > topic stuff includes colors linux
            + say stuff
            - "Stuff."
        < topic

        > topic override inherits colors
            + what color is the sun
            - Purple.
        < topic

        > topic morecolors includes colors
            + what color is grass
            - Green.
        < topic

        > topic evenmore inherits morecolors
            + what color is grass
            - Blue, sometimes.
        < topic
    ');

    $rs->setUservar('user', 'topic' => 'colors');
    test($rs, 'What color is the sky?', 'Blue.', 'Topic=colors 1.');
    test($rs, 'What color is the sun?', 'Yellow.', 'Topic=colors 2.');
    test($rs, 'What color is grass?', $MATCH, 'Topic=colors 3.');
    test($rs, 'Name a Red Hat distro.', $MATCH, 'Topic=colors 4.');
    test($rs, 'Name a Debian distro.', $MATCH, 'Topic=colors 5.');
    test($rs, 'Say stuff.', $MATCH, 'Topic=colors 6.');

    $rs->setUservar('user', 'topic' => 'linux');
    test($rs, 'Name a Red Hat distro.', 'Fedora.', 'Topic=linux 1.');
    test($rs, 'Name a Debian distro.', 'Ubuntu.', 'Topic=linux 2.');
    test($rs, 'What color is the sky?', $MATCH, 'Topic=linux 3.');
    test($rs, 'What color is the sun?', $MATCH, 'Topic=linux 4.');
    test($rs, 'What color is grass?', $MATCH, 'Topic=linux 5.');
    test($rs, 'Say stuff.', $MATCH, 'Topic=linux 6.');

    $rs->setUservar('user', 'topic' => 'stuff');
    test($rs, 'What color is the sky?', 'Blue.', 'Topic=stuff 1.');
    test($rs, 'What color is the sun?', 'Yellow.', 'Topic=stuff 2.');
    test($rs, 'What color is grass?', $MATCH, 'Topic=stuff 3.');
    test($rs, 'Name a Red Hat distro.', 'Fedora.', 'Topic=stuff 4.');
    test($rs, 'Name a Debian distro.', 'Ubuntu.', 'Topic=stuff 5.');
    test($rs, 'Say stuff.', '"Stuff."', 'Topic=stuff 6.');

    $rs->setUservar('user', 'topic' => 'override');
    test($rs, 'What color is the sky?', 'Blue.', 'Topic=override 1.');
    test($rs, 'What color is the sun?', 'Purple.', 'Topic=override 2.');

    $rs->setUservar('user', 'topic' => 'morecolors');
    test($rs, 'What color is the sky?', 'Blue.', 'Topic=morecolors 1.');
    test($rs, 'What color is the sun?', 'Yellow.', 'Topic=morecolors 2.');
    test($rs, 'What color is grass?', 'Green.', 'Topic=morecolors 3.');

    $rs->setUservar('user', 'topic' => 'evenmore');
    test($rs, 'What color is the sky?', 'Blue.', 'Topic=evenmore 1.');
    test($rs, 'What color is the sun?', 'Yellow.', 'Topic=evenmore 2.');
    test($rs, 'What color is grass?', 'Blue, sometimes.', 'Topic=evenmore 3.');

};

#-----------------------------------------------------------------------------#
# Local file scoped parser options                                            #
#-----------------------------------------------------------------------------#

push @tests, sub {
    my $rs = RiveScript->new();
    extend($rs, "
        // Default concat mode = none
        + test concat default
        - Hello
        ^ world!

        ! local concat = space
        + test concat space
        - Hello
        ^ world!

        ! local concat = none
        + test concat none
        - Hello
        ^ world!

        ! local concat = newline
        + test concat newline
        - Hello
        ^ world!

        // invalid concat setting is equivalent to `none`
        ! local concat = foobar
        + test concat foobar
        - Hello
        ^ world!

        // the option is file scoped so it can be left at
        // any setting and won't affect subsequent parses
        ! local concat = newline
    ");
    extend($rs, "
        // concat mode should be restored to the default in a
        // separate file/stream parse
        + test concat second file
        - Hello
        ^ world!
    ");

    test($rs, "test concat default", "Helloworld!", "Test concat default");
    test($rs, "test concat space", "Hello world!", "Test concat space");
    test($rs, "test concat none", "Helloworld!", "Test concat none");
    test($rs, "test concat newline", "Hello\nworld!", "Test concat newline");
    test($rs, "test concat foobar", "Helloworld!", "Test concat foobar");
    test($rs, "test concat second file", "Helloworld!", "Test concat second file");
};

#-----------------------------------------------------------------------------#
# UTF-8 Support                                                               #
#-----------------------------------------------------------------------------#

push @tests, sub {
    # Unicode
    my $rs = RiveScript->new(utf8=>1);
    extend($rs, "
        ! sub who's = who is

        + äh
        - What's the matter?

        + ブラッキー
        - エーフィ

        // Make sure %Previous continues working in UTF-8 mode.
        + knock knock
        - Who's there?

        + *
        % who is there
        - <sentence> who?

        + *
        % * who
        - Haha! <sentence>!

        // And with UTF-8.
        + tëll më ä pöëm
        - Thërë öncë wäs ä män nämëd Tïm

        + more
        % thërë öncë wäs ä män nämëd tïm
        - Whö nëvër qüïtë lëärnëd höw tö swïm

        + more
        % whö nëvër qüïtë lëärnëd höw tö swïm
        - Hë fëll öff ä döck, änd sänk lïkë ä röck

        + more
        % hë fëll öff ä döck änd sänk lïkë ä röck
        - Änd thät wäs thë ënd öf hïm.
    ");

    test($rs, "äh", "What's the matter?", "UTF-8 Umlaut test.");
    test($rs, "ブラッキー", "エーフィ", "UTF-8 Japanese test.");
    test($rs, "knock knock", "Who's there?", "UTF-8 %Previous test 1.");
    test($rs, "Orange", "Orange who?", "UTF-8 %Previous test 2.");
    test($rs, "banana", "Haha! Banana!", "UTF-8 %Previous test 3.");
    test($rs, "tëll më ä pöëm", "Thërë öncë wäs ä män nämëd Tïm", "UTF-8 Umlaut poem test 1.");
    test($rs, "more", "Whö nëvër qüïtë lëärnëd höw tö swïm", "UTF-8 Umlaut poem test 2.");
    test($rs, "more", "Hë fëll öff ä döck, änd sänk lïkë ä röck", "UTF-8 Umlaut poem test 3.");
    test($rs, "more", "Änd thät wäs thë ënd öf hïm.", "UTF-8 Umlaut poem test 4.");
};

push @tests, sub {
    # Unicode punctuation
    my $rs = RiveScript->new(utf8=>1);
    extend($rs, "
        + hello bot
        - Hello human!
    ");

    test($rs, "Hello bot", "Hello human!", "UTF-8 punctuation test 1.");
    test($rs, "Hello, bot", "Hello human!", "UTF-8 punctuation test 2.");
    test($rs, "Hello: Bot", "Hello human!", "UTF-8 punctuation test 3.");
    test($rs, "Hello... bot?", "Hello human!", "UTF-8 punctuation test 4.");

    # Edit the punctuation regexp.
    $rs->{unicode_punctuation} = qr/xxx/;
    test($rs, "Hello bot", "Hello human!", "UTF-8 punctuation test 5.");
    test($rs, "Hello, bot!", $MATCH, "UTF-8 punctuation test 6.");
};

#-----------------------------------------------------------------------------#
# Error handling                                                              #
#-----------------------------------------------------------------------------#

push @tests, sub {
    # Deep recursion.
    my $rs = bot("
        + one
        @ two

        + two
        @ one
    ");
    testl($rs, 'one', qr/^ERR: Deep Recursion Detected/,
        'Deep recursion check.');
};

#-----------------------------------------------------------------------------#
# End Unit Tests                                                              #
#-----------------------------------------------------------------------------#

# Run all the tests.
for my $t (@tests) {
    $t->();
}

### Utility Functions ###

# Make a new bot
sub bot {
    my $code = shift;
    my $rs = RiveScript->new();
    return extend($rs, $code);
}

# Extend a bot.
sub extend {
    my ($rs, $code) = @_;
    $rs->stream($code);
    $rs->sortReplies();
    return $rs;
}

# Test message and response.
sub test {
    my ($rs, $in, $out, $note) = @_;
    my $reply = $rs->reply('user', $in);
    is($reply, $out, $note);
}
sub testl {
    my ($rs, $in, $out, $note) = @_;
    my $reply = $rs->reply('user', $in);
    like($reply, $out, $note);
}

# Test user variable.
sub tv {
    my ($rs, $var, $value, $note) = @_;
    is($rs->getUservar('user', $var), $value, $note);
}
