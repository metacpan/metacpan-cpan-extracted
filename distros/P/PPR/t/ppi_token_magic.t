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
            ok $str !~ m/\A \s* (?&PerlDocument) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
        else {
            ok $str =~ m/\A \s* (?&PerlDocument) \s* \Z   $PPR::GRAMMAR/xo => $str;
        }
}

done_testing();

__DATA__
# THESE SHOULD MATCH...
$[;                     # Magic  $[
####
$$;                     # Magic  $$
####
%-;                     # Magic  %-
####
$#-;                    # Magic  $#-
####
$$foo;                  # Symbol $foo   Dereference of $foo
####
$^W;                    # Magic  $^W
####
${^WIDE_SYSTEM_CALLS};  # Magic  ${^WIDE_SYSTEM_CALLS}
####
${^MATCH};              # Magic  ${^MATCH}
####
@{^_Bar};               # Magic  @{^_Bar}
####
${^_Bar}[0];            # Magic  @{^_Bar}
####
%{^_Baz};               # Magic  %{^_Baz}
####
${^_Baz}{burfle};       # Magic  %{^_Baz}
####
$${^MATCH};             # Magic  ${^MATCH}  Dereference of ${^MATCH}
####
\${^MATCH};             # Magic  ${^MATCH}
####
$0;                     # Magic  $0  -- program being executed
####
$0x2;                   # Magic  $0  -- program being executed
####
$10;                    # Magic  $10 -- capture variable
####
$1100;                  # Magic  $1100 -- capture variable
####
