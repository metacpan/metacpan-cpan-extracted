#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

# Test that role, requires, with, before, after, around are exported
# into caller's namespace by 'use Object::Proto'

use Object::Proto;

# ---- Verify all keywords are available as bare functions ----

ok(defined &main::object,   'object exported');
ok(defined &main::role,     'role exported');
ok(defined &main::requires, 'requires exported');
ok(defined &main::with,     'with exported');
ok(defined &main::before,   'before exported');
ok(defined &main::after,    'after exported');
ok(defined &main::around,   'around exported');

# ---- Use exported role() to define a role ----

role('Greetable', 'greeting:Str:default(hello)');
requires('Greetable', 'name');

# Role method
package Greetable;
sub greet { $_[0]->greeting . ', ' . $_[0]->name }
package main;

# ---- Use exported object() to define a class ----

object 'Person', 'name:Str:required', 'age:Int';

# Person has the required 'name' method — consume the role
with('Person', 'Greetable');

# ---- Verify role composition worked ----

my $p = Person->new(name => 'Alice', age => 30);
is($p->name, 'Alice', 'Person name accessor works');
is($p->greeting, 'hello', 'Role default slot works');
is($p->greet, 'hello, Alice', 'Role method works');
ok(Object::Proto::does($p, 'Greetable'), 'Person does Greetable');

# ---- requires() catches missing methods ----

object 'EmptyClass', 'x:Int';
eval { with('EmptyClass', 'Greetable') };
ok($@, 'with() croaks when required method missing');
like($@, qr/name/, 'Error mentions the missing method');

# ---- Multiple roles via exported with() ----

role('Timestamped', 'created_at:Str', 'updated_at:Str');

object 'Article', 'title:Str:required';

package Article;
sub name { $_[0]->title }
package main;

with('Article', 'Greetable', 'Timestamped');

my $a = Article->new(title => 'News');
ok($a->can('greeting'),   'Article has Greetable slot');
ok($a->can('created_at'), 'Article has Timestamped slot');
ok(Object::Proto::does($a, 'Greetable'),   'Article does Greetable');
ok(Object::Proto::does($a, 'Timestamped'), 'Article does Timestamped');

# ---- Exported before/after/around still work ----

our @log;

package Worker;
sub work {
    push @main::log, 'work';
    return 'done';
}
package main;

object 'Worker', 'task:Str';

before 'Worker::work' => sub { push @log, 'before' };
after  'Worker::work' => sub { push @log, 'after' };

my $w = Worker->new(task => 'build');
@log = ();
my $result = $w->work;
is($result, 'done', 'Method returns correctly');
is_deeply(\@log, ['before', 'work', 'after'], 'before/after order correct');

# ---- around via exported keyword ----

around 'Worker::work' => sub {
    my ($orig, $self, @args) = @_;
    push @log, 'around-pre';
    my $ret = $self->$orig(@args);
    push @log, 'around-post';
    return uc $ret;
};

@log = ();
$result = $w->work;
is($result, 'DONE', 'around modifies return value');
is_deeply(\@log, ['before', 'around-pre', 'work', 'around-post', 'after'],
          'before -> around -> original -> around-post -> after order')
    || diag("got: @log");

# ---- Exports in a different package ----

{
    package Other;
    use Test::More;
    use Object::Proto;

    ok(defined &Other::object,   'object exported to Other');
    ok(defined &Other::role,     'role exported to Other');
    ok(defined &Other::requires, 'requires exported to Other');
    ok(defined &Other::with,     'with exported to Other');
    ok(defined &Other::before,   'before exported to Other');
    ok(defined &Other::after,    'after exported to Other');
    ok(defined &Other::around,   'around exported to Other');
}

done_testing();
