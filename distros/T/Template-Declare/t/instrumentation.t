#!/usr/bin/perl
package MyApp::Templates;
use strict;
use warnings;
use Template::Declare::Tags;
use base 'Template::Declare';

template inner => sub {
   my ($self, $arg) = @_;

   div { "inner: $arg" }
};

template outer => sub {
   my ($self, $arg) = @_;

   show('inner', uc $arg);
   div { "outer: $arg" }
};

template add  => sub {
    my ($self, $a, $b) = @_;
    outs "$a + $b";
};

template host => sub {
    my $self = shift;
    show('add', 3, 7);
};

package main;
use strict;
use warnings;
use Test::More tests => 32;
use Template::Declare;

my @args;

Template::Declare->init(
    dispatch_to => ['MyApp::Templates'],
    around_template => sub { push @args, [@_]; shift->() },
);

my $out = Template::Declare->show('inner', 'inside');
like($out, qr/inner: inside/);

is(@args, 1, "one template called");
is(ref($args[0][0]), 'CODE', "first argument is \$orig");
is($args[0][1], 'inner', "second argument is template path");
is_deeply($args[0][2], ['inside'], "third argument is the list of arguments");
is(ref($args[0][3]), 'CODE', "fourth argument is template coderef");
@args = ();

$out = Template::Declare->show('outer', 'xyzzy');
like($out, qr/outer: xyzzy/);
like($out, qr/inner: XYZZY/);

is(@args, 2, "one pre_template called");
is(ref($args[0][0]), 'CODE', "first argument is \$orig");
is($args[0][1], 'outer', "nested templates");
is($args[1][1], 'inner', "nested templates)");
is_deeply($args[0][2], ['xyzzy'], "nested templates");
is_deeply($args[1][2], ['XYZZY'], "nested templates");
is(ref($args[0][3]), 'CODE', "fourth argument is template coderef");
is(ref($args[1][3]), 'CODE', "fourth argument is template coderef");
@args = ();

$out = Template::Declare->show('add', '32', '56');
is($out, '32 + 56');

is(@args, 1, "one template called");
is(ref($args[0][0]), 'CODE', "first argument is \$orig");
is($args[0][1], 'add', "second argument is template path");
is_deeply($args[0][2], [32, 56], "third argument is the list of arguments");
is(ref($args[0][3]), 'CODE', "fourth argument is template coderef");
@args = ();

$out = Template::Declare->show('host');
is($out, '3 + 7');

is(@args, 2, "one template called");
is(ref($args[0][0]), 'CODE', "first argument is \$orig");
is(ref($args[1][0]), 'CODE', "first argument is \$orig");
is($args[0][1], 'host', "second argument is template path");
is($args[1][1], 'add', "second argument is template path");
is_deeply($args[0][2], [], "third argument is the list of arguments");
is_deeply($args[1][2], [3, 7], "third argument is the list of arguments");
is(ref($args[0][3]), 'CODE', "fourth argument is template coderef");
is(ref($args[1][3]), 'CODE', "fourth argument is template coderef");
@args = ();

