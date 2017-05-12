#!/usr/bin/perl
# '$Id: 90prototypes.t,v 1.1 2004/12/05 21:19:33 ovid Exp $';
use warnings;
use strict;
use Test::More tests => 3;
#use Test::More qw/no_plan/;

BEGIN
{
#    $ENV{DEBUG} = 1;
    chdir 't' if -d 't';
    unshift @INC => '../lib';
}
use Sub::Signatures;

sub foo($bar) {
    $bar;
}

sub foo($bar, $baz) {
    return [$bar, $baz];
}

ok defined &foo,
    '"signature" subroutines should exist';

is_deeply foo({this => 'one'}), {this => 'one'},    
    '... and we should be able to call them';

is_deeply foo(1,2), [1,2],
    '... and have them dispatch correctly';

__END__

# see comments in module code.  Prototypes cause an infinite
# while loop :(

sub bar($$) {
    my ($foo, $bar) = @_;
    return [$foo, $bar];
}

ok defined &bar,
    'Prototyped subs work';

is_deeply bar(1,2), [1,2],
    '... and are ignored by Sub::Signatures';
