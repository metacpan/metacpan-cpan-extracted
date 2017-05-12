#!/usr/bin/perl -w
use strict;
package Foo;
use Devel::Declare;
sub after {};
sub method { $_[0]}; # fake method keyword
package main;

use Test::More;

our @foo;

sub foo {
    push @foo, \@_;
}
{
    $INC{'Devel/Cover.pm'} = 1;
    my $x = eval q{
package Foo;
        use MooseX::CoverableModifiers;
        after foo => sub {
          push @main::foo, 'foo_after';
        };
        after foo => method( sub{
          push @main::foo, 'foo_after_method';
        });
1;
    };
    ok($x);
    diag $@ if $@;
    no strict 'refs';
    ok( exists $Foo::{'__after_foo_0'});
    ok( exists $Foo::{'__after_foo_1'});

}

done_testing;
