#!/usr/bin/env perl -w

use 5.10.0;
use utf8;
use Test::More tests => 34;
#use Test::More 'no_plan';
my $CLASS;

BEGIN {
    $CLASS = 'PGXN::Site::Locale';
    use_ok $CLASS or die;
}

isa_ok my $l = $CLASS->get_handle('en'), $CLASS, 'English handle';
isa_ok $l, "$CLASS\::en", 'It also';
is $l->maketext('in'), 'in', 'It should translate "in"';

# Try get_handle() with bogus language.
isa_ok $l = $CLASS->get_handle('nonesuch'), $CLASS, 'Nonesuch get_handle handle';
isa_ok $l, "$CLASS\::en", 'It also';
is $l->maketext('in'), 'in', 'It should translate "in"';

# Try french.
isa_ok $l = $CLASS->get_handle('fr'), $CLASS, 'French handle';
isa_ok $l, "$CLASS\::fr", 'It also';
is $l->maketext('in'), 'dans', 'It should translate "in"';

# Try pass-through.
local $@;
eval { $l->maketext('whatever') };
like $@, qr{maketext doesn't know how to say:\nwhatever},
    'It should die on an unknown phrase';

# Try accept.
isa_ok $l = $CLASS->accept('en;q=1,fr;q=.5'), $CLASS, 'Accept handle';
isa_ok $l, "$CLASS\::en", 'It also';

isa_ok $l = $CLASS->accept('en;q=1,fr;q=2'), $CLASS, 'French accept handle';
isa_ok $l, "$CLASS\::fr", 'It also';

# Try en list().
$PGXN::Site::Locale::Lexicon{'[list,_1]'} = '[list,_1]';
ok my $lh = $CLASS->get_handle('en'), 'Get English handle';
is $lh->maketext('[list,_1]', ['foo', 'bar']),
    'foo and bar', 'en list() should work';
is $lh->maketext('[list,_1]', ['foo']),
    'foo', 'single-item en list() should work';
is $lh->maketext('[list,_1]', ['foo', 'bar', 'baz']),
    'foo, bar, and baz', 'triple-item en list() should work';

# Try en qlist()
$PGXN::Site::Locale::Lexicon{'[qlist,_1]'} = '[qlist,_1]';
is $lh->maketext('[qlist,_1]', ['foo', 'bar']),
    '“foo” and “bar”', 'en qlist() should work';
is $lh->maketext('[qlist,_1]', ['foo']),
    '“foo”', 'single-item en qlist() should work';
is $lh->maketext('[qlist,_1]', ['foo', 'bar', 'baz']),
    '“foo”, “bar”, and “baz”', 'triple-item en qlist() should work';

# Try fr list().
ok $lh = $CLASS->get_handle('fr'), 'Get Frglish hetle';
is $lh->maketext('[list,_1]', ['foo', 'bar']),
    'foo et bar', 'fr list() should work';
is $lh->maketext('[list,_1]', ['foo']),
    'foo', 'single-item fr list() should work';
is $lh->maketext('[list,_1]', ['foo', 'bar', 'baz']),
    'foo, bar, et baz', 'triple-item fr list() should work';

# Try fr qlist()
is $lh->maketext('[qlist,_1]', ['foo', 'bar']),
    '«foo» et «bar»', 'fr qlist() should work';
is $lh->maketext('[qlist,_1]', ['foo']),
    '«foo»', 'single-item fr qlist() should work';
is $lh->maketext('[qlist,_1]', ['foo', 'bar', 'baz']),
    '«foo», «bar», et «baz»', 'triple-item fr qlist() should work';

# Try load_file.
ok $lh = $CLASS->get_handle('en'), 'Get English handle again';
like $lh->from_file('faq.html'), qr{Open-source PostgreSQL extension release packages},
    'from_file should work';
ok $lh = $CLASS->get_handle('fr'), 'Get French handle again';
like $lh->from_file('faq.html'), qr{Open-source PostgreSQL extension release packages},
    'from_file should work for french, too';

# Make sure it does substitution.
like $lh->from_file('feedback.html', 'foo@bar.com'), qr{foo\@bar\.com},
    'From file should support [_1] type stuff';
