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
            ok $str !~ m/\A \s* (?&PerlDocument) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
        else {
            ok $str =~ m/\A \s* (?&PerlDocument) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
DESTROY {}
sub BEGIN {}
sub   foo   {}
sub foo{}

sub FOO {}

sub _foo {}

sub _0foo {}

sub _foo0 {}

sub ___ {}

sub bar() {}

sub baz : method{}

sub baz : method lvalue{}

sub baz : method:lvalue{}

sub baz (*) : method : lvalue{}

sub x64 {}

sub AUTOLOAD;

sub AUTOLOAD {}

sub DESTROY;

sub DESTROY {}

AUTOLOAD;

AUTOLOAD {}

DESTROY;

sub CHECK {}

sub UNITCHECK {}

sub INIT {}

sub END {}

sub AUTOLOAD {}

sub CLONE_SKIP {}

sub __SUB__ {}

sub _FOO {}

sub FOO9 {}

sub FO9O {}

sub FOo {}
####
