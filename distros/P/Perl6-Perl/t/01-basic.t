#
# $Id: 01-basic.t,v 0.1 2006/12/23 23:08:18 dankogai Exp dankogai $
#
use strict;
use warnings;
use Perl6::Perl qw/perl/;

#use Test::More tests => 1;
use Test::More qw/no_plan/;

{
    package S;
    sub new { my $pkg = shift; my $s = shift; bless \$s => $pkg };
}
{
    package A;
    sub new { my $pkg = shift; bless [ @_ ] => $pkg };
}
{
    package H;
    sub new { my $pkg = shift; bless { @_ }  => $pkg };
}
{
    package C;
    sub new { my $pkg = shift; my $c = shift; bless $c  => $pkg };
}

my $s = 42;
is $s, eval(perl $s), "scalar";
my @a = (1..42);
is_deeply \@a, eval(perl \@a), "array";
my %h = ("42" => "everything");
is_deeply \%h, eval(perl \%h), "hash";
my $os = S->new(42);
is_deeply $os, eval($os->perl), "scalar object";
my $oa = A->new(1..42);
is_deeply $oa, eval($oa->perl), "array object";
my $oh = H->new(one => 1, two => 2);
is_deeply $oh, eval($oh->perl), "hash object";
my $c = sub { $_[0] + $_[1] };
my $oc = C->new($c);
# test::more does not support that!
# is_deeply $oc, eval($oc->perl), "code object";
is $oc->(40, 2), eval($oc->perl)->(40, 2), "code object";

