#!perl

use 5.010;

use strict;
use warnings;

use blib;
use blib 't/Sub-Op-LexicalSub';

my $code = $ARGV[0];
die "Usage: $0 'code involving f() and g()'" unless defined $code;

my $cb = eval <<"CODE";
 use Sub::Op::LexicalSub f => sub { say 'f(' . join(', ', \@_) . ')'; \@_ };
 use Sub::Op::LexicalSub g => sub { say 'g(' . join(', ', \@_) . ')'; \@_ };
 sub { $code }
CODE
die $@ if $@;

print "--- run ---\n";
eval { $cb->() };
warn "exception: $@" if $@;

print "--- deparse ---\n";
use B::Deparse;
print B::Deparse->new->coderef2text($cb), "\n";

print "--- concise ---\n";
use B::Concise;
B::Concise::compile($cb)->();

print "--- concise(exec) ---\n";
B::Concise::compile('-exec', $cb)->();
