# -*- perl -*-

use strict;
use Set::IntSpan 1.17;

@Foo::Bar::ISA = qw(Set::IntSpan);

my $N = 1;
sub Not { print "not " }
sub OK  { print "ok ", $N++, "\n" }

print "1..20\n";

my $intspan = new Set::IntSpan '15-25';
my $foobar  = new Foo::Bar     '1-10, 20-30';

ref $intspan eq 'Set::IntSpan' or Not; OK;
ref $foobar  eq 'Foo::Bar'     or Not; OK;

for my $op (qw(union intersect diff xor))
{
    my $result;

    $result = $intspan->$op($intspan);
    ref $result eq 'Set::IntSpan' or Not; OK;

    $result = $intspan->$op($foobar);
    ref $result eq 'Set::IntSpan' or Not; OK;

    $result = $foobar->$op($intspan);
    ref $result eq 'Foo::Bar'     or Not; OK;

    $result = $foobar->$op($foobar);
    ref $result eq 'Foo::Bar'     or Not; OK;
}

for my $op (qw(complement))
{
    my $result;

    $result = $intspan->$op();
    ref $result eq 'Set::IntSpan' or Not; OK;

    $result = $foobar->$op();
    ref $result eq 'Foo::Bar'     or Not; OK;
}


