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
            ok $str !~ m/\A \s* (?&PerlStatement) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
        else {
            ok $str =~ m/\A \s* (?&PerlStatement) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
    (Foo(')'));
####
    %x = ( try => "this");
####
    %x = ();
####
    %x = ( $try->{this}, "too");
####
    %'x = ( $try->{this}, "too");
####
    %'x'y = ( $try->{this}, "too");
####
    %::x::y = ( $try->{this}, "too");
####
    %x = do { $try > 10 };
####
# THESE SHOULD FAIL
    { $a = /\}/; };
####
    { $data[4] =~ /['"]/; };
####
    { sub { $_[0] /= $_[1] } };  # / here
####
    { 1; };
####
    { $a = 1; };
####
    { $a = $b; # what's this doing here?
    };'
####
    { $a = $b; 
        $a =~ /$b/; 
        @a = map /\s/ @b };
####
    { $a = $b; # what's this doing here? };'
####
    { $a = $b; # what's this doing here? ;'
####
