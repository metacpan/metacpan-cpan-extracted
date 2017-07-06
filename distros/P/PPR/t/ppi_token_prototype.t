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
# THESE SHOULD MATCH
sub (\ [ $ ]){;};
sub (\\\ [ $ ]){;}
####
sub foo(){;}
sub foo( ){;}

sub foo () {;}

sub foo(+@){;}

sub foo (+@) {;}

sub foo(\[$;$_@]){;}

sub foo(\ [ $ ]){;}

sub foo(\\\ [ $ ]){;}

sub foo($ _ %){;}

sub foo (){;}

sub foo ( ){;}

sub foo  () {;}

sub foo (+@){;}

sub foo  (+@) {;}

sub foo (\[$;$_@]){;}

sub foo (\ [ $ ]){;}

sub foo (\\\ [ $ ]){;}

sub foo ($ _ %){;}
####
sub(){;}
####
sub( ){;}
####
sub () {;}
####
sub(+@){;}
####
sub (+@) {;}
####
sub(\[$;$_@]){;}
####
sub(\ [ $ ]){;}
####
sub(\\\ [ $ ]){;}
####
sub($ _ %){;}
####
sub (){;}
####
sub ( ){;}
####
sub  () {;}
####
sub (+@){;}
####
sub  (+@) {;}
####
sub (\[$;$_@]){;}
####
sub ($ _ %){;}
####
sub DESTROY(){;}

sub DESTROY( ){;}

sub DESTROY () {;}

sub DESTROY(+@){;}

sub DESTROY (+@) {;}

sub DESTROY(\[$;$_@]){;}

sub DESTROY(\ [ $ ]){;}

sub DESTROY(\\\ [ $ ]){;}

sub DESTROY($ _ %){;}

sub DESTROY (){;}

sub DESTROY ( ){;}

sub DESTROY  () {;}

sub DESTROY (+@){;}

sub DESTROY  (+@) {;}

sub DESTROY (\[$;$_@]){;}

sub DESTROY (\ [ $ ]){;}

sub DESTROY (\\\ [ $ ]){;}

sub DESTROY ($ _ %){;}

sub AUTOLOAD(){;}

sub AUTOLOAD( ){;}

sub AUTOLOAD () {;}

sub AUTOLOAD(+@){;}

sub AUTOLOAD (+@) {;}

sub AUTOLOAD(\[$;$_@]){;}

sub AUTOLOAD(\ [ $ ]){;}

sub AUTOLOAD(\\\ [ $ ]){;}

sub AUTOLOAD($ _ %){;}

sub AUTOLOAD (){;}

sub AUTOLOAD ( ){;}

sub AUTOLOAD  () {;}

sub AUTOLOAD (+@){;}

sub AUTOLOAD  (+@) {;}

sub AUTOLOAD (\[$;$_@]){;}

sub AUTOLOAD (\ [ $ ]){;}

sub AUTOLOAD (\\\ [ $ ]){;}

sub AUTOLOAD ($ _ %){;}
####
