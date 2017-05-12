#!perl

BEGIN { chdir 't' if -d 't' }

use strict;
use warnings;

use Test::More tests => 23;

my $index;

#--- compiles?
use_ok('Pod::PseudoPod::CrossReference');

#--- makes sure constructor works.
use Pod::PseudoPod::CrossReference;
my $ref = Pod::PseudoPod::CrossReference->new;
ok(ref($ref) eq 'Pod::PseudoPod::CrossReference','constructor');

#--- test single handler set works.
my $z = sub { $index->{$_[1]} = $_[0]->{'title'} };
ok($ref->set_handlers('Z',$z),'make set_handlers call, single handler');
ok( $ref->{Handlers}->{Z} eq $z,'Z handler check');

#--- test multiple handler set.
my @handlers = keys %{$ref->{_HNDL_TYPES}};
my $handler = sub { $_[1] };
my @temp;
foreach (@handlers) { # create array of handlers for assignment.
    next if $_ eq 'Z';
    push @temp, $_, $handler
}
ok($ref->set_handlers(@temp),'make set_handlers call, multiple handlers');
foreach (sort @handlers) {
    next if $_ eq 'Z'; # test seperately.
    ok($ref->{Handlers}->{$_} eq $handler,$_.' handler check');
}

#--- make sure Z was not overwritten during previous test.
ok($ref->{Handlers}->{Z} eq $z,'Z handler not overwritten');

#--- parse psuedo pod doc
ok($ref->parse_file('test.pod'),'can parse');

#--- is index not empty?
ok(keys %$index,'index is not empty');

#--- test data table values.
foreach (sort @handlers) {
    next if $_ eq 'Z'; # handler has no output.
    $index->{uc($_)} = '' unless $index->{uc($_)}; # knock out warnings noise.
    ok($index->{uc($_)} eq "this is $_","$_ output");
    delete $index->{uc $_}; # clear to help next test.
}

#--- check for extraneous info that shouldn't be there.
ok(! keys %$index,'no leftovers in index');
