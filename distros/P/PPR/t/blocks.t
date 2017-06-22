use strict;
use warnings;

use Test::More;

use PPR;

my $neg = 0;
while (my $str = <DATA>) {
           if ($str =~ /\A# TH[EI]SE? SHOULD MATCH/) { $neg = 0;       next; }
        elsif ($str =~ /\A# TH[EI]SE? SHOULD FAIL/)  { $neg = 1;       next; }
        elsif ($str !~ /^####\h*\Z/m)                { $str .= <DATA>; redo; }

        $str =~ s/\s*^####\h*\Z//m;

        if ($neg) {
            ok $str !~ m/\A (?&PerlOWS) (?&PerlBlock) (?&PerlOWS) \Z $PPR::GRAMMAR/xo => "FAIL: $str";
        }
        else {
            ok $str =~ m/\A (?&PerlOWS) (?&PerlBlock) (?&PerlOWS) \Z $PPR::GRAMMAR/xo => "MATCH: $str";
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
    {
        func1 / regex /;
        func1 / regex ;
    }
####
    {
        time / regex;
        func1 / regex /;
    }
####
    {
        func1 / regex;
    }
####
    {
        func1 / regex /;
    }
####
    {
        func1 / regex /;
        func1 / regex;
    }
####
    { sub { $_[0] /= $_[1] } } # / here
####
    {$obj->method}
####
    { %x = () }
####
    {
        $a = $b;
        $x = $a / $b;
        $a =~ /$b/;
        /$c/;
        @a = map /\s/, @b;
        @a = map {/\s/} @b;
        $not_pod
=head1 ();
    }
####
    {
        $a = $b;
        $x  = $a / $b;

=head1 This is pod

...until the next

=cut

        $a =~ /$b/;
        /$c/;

=pod

more pod

=cut
        @a = map /\s/, @b;
        @a = map {/\s/} @b
    }
####
    { %x = ( try => "this") }
####
    {Foo(')')}
####
    { $data[4] =~ /['"]/; }
####
    { %x = ( $try->{this}, "too") }
####
    { %'x = ( $try->{this}, "too") }
####
    { %'x'y = ( $try->{this}, "too") }
####
    { %::x::y = ( $try->{this}, "too") }
####
    { $a = /\}/; }
####
    { 1; }
####
    { $a = 1; }
####
    {$a=1}
####
    { $a = $b; # what's this doing here?
    }
####
# THESE SHOULD FAIL...
    < %x = do { $try > 10 } >;
####
    { $a = $b; # what's this doing here? }
####
    { $a = $b; # what's this doing here?
####
