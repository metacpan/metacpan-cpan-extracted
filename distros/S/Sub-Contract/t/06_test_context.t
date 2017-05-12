#-------------------------------------------------------------------
#
#   $Id: 06_test_context.t,v 1.7 2008/06/17 11:31:42 erwan_lemonnier Exp $
#

package main;

use strict;
use warnings;
use lib "../lib/", "t/", "lib/";
use Test::More;
use Data::Dumper;

BEGIN {

    use check_requirements;
    plan tests => 97;

    use_ok("Sub::Contract",'contract');
};

sub foo {
    my $arr = wantarray;
    return "no context" if (!defined $arr);
    return ('array','context') if ($arr);
    return 'scalar context';
}

sub invariant { return 1 }

my $pre_wantarray;
my @pre_args;
my @pre_result;

my $post_wantarray;
my @post_args;
my @post_result;

sub pre {
    is_deeply(\@_,\@Sub::Contract::args, "check \@_ before call");
    is($Sub::Contract::wantarray, $pre_wantarray, "check Sub::Contract::wantarray before call");
    is_deeply(\@Sub::Contract::args, \@pre_args, "check Sub::Contract::args before call");
    is_deeply(\@Sub::Contract::results, \@pre_result, "check Sub::Contract::results before call");
    return 1;
}

sub post {
    is_deeply(\@_,\@Sub::Contract::results, "check \@_ after call");
    is($Sub::Contract::wantarray, $post_wantarray, "check Sub::Contract::wantarray after call");
    is_deeply(\@Sub::Contract::args, \@post_args, "check Sub::Contract::args after call");
    is_deeply(\@Sub::Contract::results, \@post_result, "check Sub::Contract::results after call");
    return 1;
}

my $c = contract('foo')
    ->pre(\&pre)
    ->post(\&post)
    ->invariant(\&invariant)
    ->enable;

#----------------------------------------------
#
# no memoization
#
#----------------------------------------------

# no context with contract and no memoization
{
    $pre_wantarray = $post_wantarray = undef;
    @pre_args = @post_args = ();
    @pre_result = @post_result = ();

    foo();
    is($_,undef,"no context (without args)");
}

{
    $pre_wantarray = $post_wantarray = undef;
    @pre_args = @post_args = ('bob',1,['a',4]);
    @pre_result = @post_result = ();


    foo('bob',1,['a',4]);
    is($_,undef,"no context (with args)");
}

# scalar context with contract and no memoization
{
    $pre_wantarray = $post_wantarray = '';
    @pre_args = @post_args = ();
    @pre_result = ();
    @post_result = ('scalar context');

    my $res = foo();
    is($res,"scalar context","scalar context (without args)");
}

{
    $pre_wantarray = $post_wantarray = '';
    @pre_args = @post_args = (34);
    @pre_result = ();
    @post_result = ('scalar context');

    my $res = foo(34);
    is($res,"scalar context","scalar context (with args)");
}

# array context with contract and no memoization
{
    $pre_wantarray = $post_wantarray = 1;
    @pre_args = @post_args = ();
    @pre_result = ();
    @post_result = ('array','context');

    my @res = foo();
    is_deeply(\@res,["array","context"],"array context (without args)");
}

{
    $pre_wantarray = $post_wantarray = 1;
    @pre_args = @post_args = (ab => 2, cd => 3);
    @pre_result = ();
    @post_result = ('array','context');

    my @res = foo(ab => 2, cd => 3);
    is_deeply(\@res,["array","context"],"array context (with args)");
}

#----------------------------------------------
#
# with memoization
#
#----------------------------------------------

$c->cache->enable;
my $res;

# no context with contract and memoization
{
    $pre_wantarray = $post_wantarray = undef;
    @pre_args = @post_args = ();
    @pre_result = @post_result = ();

    eval { foo(); };
    ok($@ =~ /calling memoized subroutine main::foo in void context/, "die if memoized sub called in void context");

    # die even on second call with same (no) arguments
    eval { foo(); };
    ok($@ =~ /calling memoized subroutine main::foo in void context/, "die even on second call");
}

# scalar context with contract and memoization
{
    $pre_wantarray = $post_wantarray = '';
    @pre_args = @post_args = ();
    @pre_result = ();
    @post_result = ('scalar context');

    $res = foo();
    is($res,"scalar context","scalar context (without args) (memoized on)");
    $res = foo();
    is($res,"scalar context","scalar context (without args) (from cache)");
}

{
    $pre_wantarray = $post_wantarray = '';
    @pre_args = @post_args = (34);
    @pre_result = ();
    @post_result = ('scalar context');

    $res = foo(34);
    is($res,"scalar context","scalar context (with args) (memoized on)");
    $res = foo(34);
    is($res,"scalar context","scalar context (with args) (from cache)");
}

# array context with contract and memoization
{
    $pre_wantarray = $post_wantarray = 1;
    @pre_args = @post_args = ();
    @pre_result = ();
    @post_result = ('array','context');

    my @res = foo();
    is_deeply(\@res,["array","context"],"array context (without args) (memoized on)");
    @res = foo();
    is_deeply(\@res,["array","context"],"array context (without args) (from cache)");
}

{
    $pre_wantarray = $post_wantarray = 1;
    @pre_args = @post_args = (ab => 2, cd => 3);
    @pre_result = ();
    @post_result = ('array','context');

    my @res = foo(ab => 2, cd => 3);
    is_deeply(\@res,["array","context"],"array context (with args) (memoized on)");
    @res = foo(ab => 2, cd => 3);
    is_deeply(\@res,["array","context"],"array context (with args) (from cache)");
}


