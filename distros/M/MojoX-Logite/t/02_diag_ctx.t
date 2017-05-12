#!/usr/bin/env perl

use strict;
use warnings;

use Cwd;

use Test::More tests => 9;

use MojoX::Logite;

my $testlog = Cwd::cwd . '/test_diag_ctx_log.db';

my $logite = MojoX::Logite->new(
  'path' => $testlog,
  'prune' => 1
);

$logite->context_map->{key} = 'context key';

my $msg_text = "Why isn't this working?";
$logite->debug("[%X{key}] ".$msg_text);

my $message = $logite->package_table->select();

is ($message->[0]->l_what eq '['.$logite->context_map->{key}.'] '.$msg_text , 1, "context key matched");

$logite->clear(0);

$logite->debug("%x - message 1");

push @{$logite->context_stack}, "context";
is ( $logite->context_stack->[-1] eq "context", 1, "NDC context registered" );

push @{$logite->context_stack}, "inner_context";
is ( $logite->context_stack->[-1] eq "inner_context", 1, "NDC inner context registered" );

$logite->debug("%x - message 2");

pop @{$logite->context_stack};
is ( $logite->context_stack->[-1] eq "context", 1, "NDC inner context removed" );

$logite->debug("%x - message 3");

pop @{$logite->context_stack};
is ( ! defined $logite->context_stack->[-1], 1, "NDC context removed" );

$logite->debug("%x - message 4");

my $messages = $logite->package_table->select();

is ($messages->[0]->l_what eq "[undef] - message 1" , 1, "undef context matched");
is ($messages->[1]->l_what eq "context inner_context - message 2" , 1, "inner_context matched");
is ($messages->[2]->l_what eq "context - message 3" , 1, "context matched");
is ($messages->[3]->l_what eq "[undef] - message 4" , 1, "undef context matched");
