#!/usr/bin/env perl
#*
#* Name: Params.pm.t
#* Info: Test for Params.pm.t
#* Author: Pawel Guspiel (neo77) <neo@cpan.org>
#*

use strict;
use warnings;

use Test::Most;    # last test to print

use lib "lib";

package ParamsTest;

use Params::Dry::Declare;
use Params::Dry qw(:short);

typedef 'name', 'String[20]';

#>>>
## Please see file perltidy.ERR
sub new (
            ! name:;                                    --- name of the user
            ? second_name   : name      = 'unknown';    --- second name
            ? details       : String    = 'yakusa';     --- details
        ) {

return bless {
                name        => $p_name,
                second_name => $p_second_name,
                details     => $p_details,
            }, 'ParamsTest';
}

sub get_name (
            ! first : Bool = 1; --- this is using default type for required parameter name without default value
    ) {

    return +($p_first) ? $self->{'name'} : $self->{'second_name'};
}



sub print_message (
            ! name: = $self->get_name;      --- name of the user
            ! text: String = 1;             --- message text

    ) {
    return "For: $p_name; Text: $p_text";
}

sub gret(;)  {
    return "all ok";
}

sub print_messages (
            ! name: = $self->get_name;      --- name of the user
            ! text: String = 1;             --- message text

    ) {
    print "For: $p_name\n\nText:\n$p_text\n\n";
}

sub multi (
            ! multi: String[2]|Int[3];             --- multi parameter

    ) {
    return "Value: $p_multi";
}

#<<<
#=------------------------------------------------------------------------( main )

package main;



my $pawel = new ParamsTest(name => 'Pawel', details => 'bzebeze');
ok(ref($pawel), 'you can compile code and it is runing');

my $lucja = new ParamsTest(name => 'Lucja', second_name => 'Marta');

ok($pawel->print_message( name => 'Gabriela', text => 'Some message for you has arrived') eq "For: Gabriela; Text: Some message for you has arrived", 'object is working well');

ok($pawel->print_message( text => 'Some message for you has arrived') eq 'For: Pawel; Text: Some message for you has arrived', 'no more is added automaticly');

    # no parameters
ok($pawel->gret eq 'all ok', 'no params test');

SKIP: {
    skip "Multi types feature requires Params::Dry 1.20 or higher version. Skipping tests",4 if Params::Dry->VERSION < 1.20;
        ok($pawel->multi(multi => 'aa') eq 'Value: aa', 'positive test (multi String)');
        ok($pawel->multi(multi => '555') eq 'Value: 555', 'positive test (multi Int)');
        dies_ok (sub { $pawel->multi(multi => 'aaa') }, 'out of range test (multi String)');
        dies_ok (sub { $pawel->multi(multi => '4444') }, 'out of range test (multi Int)');
}
ok($pawel->gret eq 'all ok', 'no params test');



ok('yes','yes');
done_testing();
