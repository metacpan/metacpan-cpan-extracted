#!/usr/bin/perl -w

=head1 NAME

bench_operator_storage.pl - Look at different ways of storing operators and how to call them

=cut

use strict;
use Benchmark qw(cmpthese timethese);
use CGI::Ex::Dump qw(debug);
use constant skip_execute => 1;

my $total_size = eval { require Devel::Size } ? sub { Devel::Size::total_size($_[0]) } : sub { "Skip Devel::Size check" };

###----------------------------------------------------------------###
### check basic setting speed - almost irrelvant as we are in the 300_000's

my $set_w_ref = sub { my $s = [ \ [      '+', 4, 5],  0] };
my $set_undef = sub { my $s = [ [undef, '+', 4, 5],  0] };
my $set_array = sub { my $s = [ [[      '+', 4, 5]], 0] };
my $set_arra2 = sub { my $s = [ [[],    '+', 4, 5],  0] };
my $set_bless = sub { my $s = [ bless([ '+', 4, 5],'CGI::Ex::Template::Op::foo'),  0] };

print "Set_w_ref size: ". $total_size->($set_w_ref->()) ."\n";
print "Set_undef size: ". $total_size->($set_undef->()) ."\n";
print "Set_array size: ". $total_size->($set_array->()) ."\n";
print "Set_arra2 size: ". $total_size->($set_arra2->()) ."\n";
print "Set_bless size: ". $total_size->($set_bless->()) ."\n";

cmpthese timethese -1, {
    set_w_ref => $set_w_ref,
    set_undef => $set_undef,
    set_array => $set_array,
    set_arra2 => $set_arra2,
    set_bless => $set_bless,
};

###----------------------------------------------------------------###
### time basic variable checking

my $check_w_ref = sub {
    my $s = shift;
    if (ref $s eq 'REF') {
        $s = $$s->[0] eq '..' ? 1 : 2;
    } else {
        $s = 0;
    }
};

my $check_undef = sub {
    my $s = shift;
    if (! defined $s->[0]) {
        $s = $s->[1] eq '..' ? 1 : 2;
    } else {
        $s = 0;
    }
};

cmpthese timethese -1, {
    w_ref_pos  => sub { $check_w_ref->(\ ['+', 4, 5]) },
    w_ref_dots => sub { $check_w_ref->(\ ['..', 4, 5]) },
    w_ref_neg  => sub { $check_w_ref->(['a', 0]) },
    undef_pos  => sub { $check_undef->([undef, '+', 4, 5]) },
    undef_dots => sub { $check_undef->([undef, '..', 4, 5]) },
    undef_neg  => sub { $check_undef->(['a', 0]) },
};

###----------------------------------------------------------------###
### check for calling speed

my $play_w_ref = sub {
    my $tree = shift;
    my $op   = $tree->[0];
    my @args = ($tree->[1], $tree->[2]);
};

my $play_undef = sub {
    my $tree = shift;
    my $op   = $tree->[1];
    my @args = ($tree->[2], $tree->[3]);
};

my $play_undef2 = sub {
    my $op   = shift;
    my @args = @_;
};

my $call_w_ref = sub {
    my $s = shift;
    return $play_w_ref->($$s);
};

my $call_undef = sub {
    my $s = shift;
    return $play_undef->($s);
};

my $call_undef2 = sub {
    my $s = shift;
    return $play_undef2->(@$s[1..$#$s]);
};


cmpthese timethese -1, {
    small_w_ref => sub { $call_w_ref->(\ ['~', 1 .. 2]) },
    med___w_ref => sub { $call_w_ref->(\ ['~', 1 .. 200]) },
    large_w_ref => sub { $call_w_ref->(\ ['~', 1 .. 2000]) },
    small_undef => sub { $call_undef->([undef, '~', 1 .. 2]) },
    med___undef => sub { $call_undef->([undef, '~', 1 .. 200]) },
    large_undef => sub { $call_undef->([undef, '~', 1 .. 2000]) },
    small_undef2 => sub { $call_undef2->([undef, '~', 1 .. 2]) },
    med___undef2 => sub { $call_undef2->([undef, '~', 1 .. 200]) },
    large_undef2 => sub { $call_undef2->([undef, '~', 1 .. 2000]) },
};
