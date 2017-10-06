use strict;
use warnings;

use Test::More;

BEGIN{
    BAIL_OUT "A bug in Perl 5.20 regex compilation prevents the use of PPR under that release"
        if $] > 5.020 && $] < 5.022;
}


use PPR;

my $neg = 0;
while (my $str = <DATA>) {
           if ($str =~ /\A# TH[EI]SE? SHOULD MATCH/) { $neg = 0;       next; }
        elsif ($str =~ /\A# TH[EI]SE? SHOULD FAIL/)  { $neg = 1;       next; }
        elsif ($str !~ /^####\h*\Z/m)                { $str .= <DATA>; redo; }

        $str =~ s/\s*^####\h*\Z//m;

        if ($neg) {
            ok $str !~ m/\A (?&PerlOWS) (?&PerlVariable) (?&PerlOWS) \Z $PPR::GRAMMAR/xo => "FAIL: $str";
        }
        else {
            ok $str =~ m/\A (?&PerlOWS) (?&PerlVariable) (?&PerlOWS) \Z $PPR::GRAMMAR/xo => "MATCH: $str";
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
    $#
####
    $#-
####
    @{$obj->nextval($cat ? $dog : $fish)}
####
    @{$obj->nextval($cat?$dog:$fish)->{new}}
####
    @{$obj->nextval(cat()?$dog:$fish)->{new}}
####
    @{$obj->nextval}
####
    @{$obj->nextval($cat,$dog)->{new}}
####
    $::obj
####
    %::obj::
####
    $a
####
    $ a
####
    $
    a
####
    ${a}
####
    $_
####
    $ _
####
    ${_}
####
    $a[1]
####
    @a[1]
####
    %a[1]
####
    @a[1,2,3]
####
    %a[1,2,3]
####
    @a[somefunc x 3]
####
    %a[somefunc x 3]
####
    $_[1]
####
    $a{cat}
####
    @a{cat}
####
    %a{cat}
####
    @a{qw<cat,dog>}
####
    %a{'cat',"dog"}
####
    @a{somefunc $x, $y}
####
    %a{somefunc($x, $y) x 3}
####
    $_{cat}
####
    $a->[1]
####
    $a->{"cat"}[1]
####
    @$listref
####
    @{$listref}
####
    @{ 'x' x $x }
####
    $ a {'cat'}
####
    $
    a
    {
    x
    }
####
    $a::b::c{d}->{$e->()}
####
    $a'b'c'd{e}->{$e->()}
####
    $a'b::c'd{e}->{$e->()}
####
    $#_
####
    $#array
####
    $#{array}
####
    $var[$#var]
####
    $1
####
    $11
####
    $&
####
    $`
####
    $'
####
    $+
####
    $*
####
    $.
####
    $/
####
    $|
####
    $,
####
    $"
####
    $;
####
    $%
####
    $=
####
    $-
####
    $~
####
    $^
####
    $:
####
    $^L
####
    $^A
####
    $?
####
    $!
####
    $^E
####
    $@
####
    $<
####
    $>
####
    $(
####
    $)
####
    $[
####
    $]
####
    $^C
####
    $^D
####
    $^F
####
    $^H
####
    $^I
####
    $^M
####
    $^O
####
    $^P
####
    $^R
####
    $^S
####
    $^T
####
    $^V
####
    $^W
####
    ${^WARNING_BITS}
####
    ${^WIDE_SYSTEM_CALLS}
####
    $^X
####
    $[
####
    $$
####
    %-
####
    $$foo
####
    $^W
####
    ${^MATCH}
####
    $${^MATCH}
####
    @{^_Bar}
####
    ${^_Bar}[0]
####
    %{^_Baz}
####
    ${^_Baz}{burfle}
####
# THESE SHOULD FAIL...
    $^WIDE_SYSTEM_CALLS
####
    $a->
####
    @{$
####
    $ a :: b :: c
####
    $ a ' b ' c
####
    \${^MATCH}
####
    $obj->nextval
####
    *var
####
    *$var
####
    *{var}
####
    *{$var}
####
    *var{cat}
####
    \&var
####
    \&mod::var
####
    \&mod'var
####
    $obj->_nextval
####
    $obj->next_val_
####
    $a->
####
    $a (1..3) { print $a }
####
    $obj->nextval
####
