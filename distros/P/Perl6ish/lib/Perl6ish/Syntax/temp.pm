package Perl6ish::Syntax::temp;
use strict;
use warnings;
use Devel::BeginLift qw(temp);

use B::Hooks::Parser;

my $temp;
my %temp;
my @temp;

sub temp {
    my $line = B::Hooks::Parser::get_linestr;
    my $offset = B::Hooks::Parser::get_linestr_offset;

    if ($line =~ /\btemp\s+([\$\@\%\*])(.+)\s*\;\s*$/) {
        my $sigil = $1;
        my $varname = $2;
        my $temp = $sigil . 'Perl6ish::Syntax::temp::temp';

        B::Hooks::Parser::inject(";$temp = $sigil$varname; my $sigil$varname = $temp;");
    } 
}

sub import {
    my $caller = caller;
    no strict;
    *{"$caller\::temp"} = \&temp;

    B::Hooks::Parser::setup();
}

1;
