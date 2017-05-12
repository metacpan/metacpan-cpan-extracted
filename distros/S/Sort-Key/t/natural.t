#!/usr/bin/perl

use strict;
use warnings;

# BEGIN {$Sort::Key::DEBUG=10};

use Test::More tests => 9;

use Sort::Key 'keysort';
use Sort::Key::Natural qw(natkeysort natsort rnatsort rnatkeysort mkkey_natural
			  natsort_inplace natkeysort_inplace rnatsort_inplace
			  rnatkeysort_inplace);

my @data = qw(foo1 foo23 foo foo foo fo2 foo6 bar12
	      bar1 bar2 bar-45 b-a-r-45 bar);

my $sorted = 'b-a-r-45 bar bar1 bar2 bar12 bar-45 fo2 foo foo foo foo1 foo6 foo23';
my $rsorted = 'foo23 foo6 foo1 foo foo foo fo2 bar-45 bar12 bar2 bar1 bar b-a-r-45';
my @sorted;

@sorted = keysort { mkkey_natural } @data;
is("@sorted", $sorted, 'mkkey_natural');

@sorted = natkeysort { $_ } @data;
is("@sorted", $sorted, 'natkeysort');

@sorted = natsort @data;
is("@sorted", $sorted, 'natsort');

@sorted = @data;
natsort_inplace @sorted;
is("@sorted", $sorted, 'notsort_inplace');

@sorted = @data;
natkeysort_inplace { $_ } @sorted;
is("@sorted", $sorted, 'natkeysort_inplace');

@sorted = rnatkeysort { $_ } @data;
is("@sorted", $rsorted, 'rnatkeysort');

@sorted = rnatsort @data;
is("@sorted", $rsorted, 'rnatsort');

@sorted = @data;
rnatsort_inplace @sorted;
is("@sorted", $rsorted, 'rnotsort_inplace');

@sorted = @data;
rnatkeysort_inplace { $_ } @sorted;
is("@sorted", $rsorted, 'rnatkeysort_inplace');

