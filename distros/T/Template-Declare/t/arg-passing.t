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
use Test::More tests => 9;
use Template::Declare;
use Template::Declare::Tags;
Template::Declare->init(dispatch_to => ['MyApp::Templates']);

my $out = Template::Declare->show('inner', 'inside');
like($out, qr/inner: inside/);
is(show('inner', 'inside'), $out, 'show and TD->show are the same');

$out = Template::Declare->show('outer', 'xyzzy');
like($out, qr/outer: xyzzy/);
like($out, qr/inner: XYZZY/);
is(show('outer', 'xyzzy'), $out, 'show and TD->show are the same');

$out = Template::Declare->show('add', '32', '56');
is($out, '32 + 56');
is(show('add', '32', '56'), $out, 'show and TD->show are the same');

$out = Template::Declare->show('host');
is($out, '3 + 7');
is(show('host'), $out, 'show and TD->show are the same');
