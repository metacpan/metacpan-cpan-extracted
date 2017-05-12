#!/usr/bin/perl -wT
use strict;
use warnings;

use Test::MockObject;
use Test::More tests => 17;

BEGIN { use_ok('POE::Component::IRC::Plugin::Infobot') };

no warnings 'redefine';
sub POE::Component::IRC::Plugin::Infobot::getstr {
	my $rstrings = shift;
	sprintf @{$rstrings}[0], @_
}
use warnings 'redefine';

my $last_msg;
my $last_ctcp;

sub yield {
	$last_msg = $_[3] if $_[1] eq 'privmsg';
	$last_ctcp = $_[3] if $_[1] eq 'ctcp';
}

my $mockirc = Test::MockObject->new;
$mockirc->mock(yield => \&yield)->set_always(nick_name => 'bot');

my $self = POE::Component::IRC::Plugin::Infobot->new(filename => undef);

sub runtest{
	my ($message, $expect, $comment, $private) = @_;
	undef $last_msg;
	undef $last_ctcp;
	$self->S_public($mockirc, \'mgv!marius@ieval.ro', \([ '#chan' ]), \$message) unless $private;
	$self->S_msg($mockirc, \'mgv!marius@ieval.ro', undef, \$message) if $private;
	is($last_msg // $last_ctcp, $expect, $comment)
}

runtest 'bot: a is b', 'sure, mgv', 'add';
runtest 'bot: a is b', 'I already had it that way, mgv', 'add same factoid twice';
runtest 'bot: a is c', '... but a is b!', 'redefine factoid';
runtest 'a?', 'a is b', 'query';
runtest 'bot: forget a', 'mgv: I forgot a', 'forget';
runtest 'bot: forget a', 'I didn\'t have anything matching a, mgv', 'forget inexistent factoid';
runtest '!forget a', 'I didn\'t have anything matching a, mgv', '!forget';
runtest 'a?', undef, 'query for inexistent factoid';
runtest 'bot: a?', 'I don\'t know, mgv', 'addressed query for inexistent factoid';

runtest 'bot: b is <reply> c', 'sure, mgv', 'add with reply';
runtest 'b?', 'c', 'check reply';
runtest 'bot: c is <action> d', 'sure, mgv', 'add with action';
runtest 'c?', 'ACTION d', 'check action';

runtest 'x is y', 'sure, mgv', 'private add', 1;
runtest 'x?', 'x is y', 'private query', 1;
runtest 'forget x', 'mgv: I forgot x', 'private forget', 1;
