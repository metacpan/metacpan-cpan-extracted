# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN {
   $^W = 0;
}

use strict;
use warnings;
no  warnings 'syntax';

my $loaded;
BEGIN { $| = 1; print "1..68\n"; }
END {print "not ok 1\n" unless $loaded;}
use RFC::RFC822::Address qw /valid/;
$loaded = 1;
print "ok   1\n";

# my $DEBUG = 1 if grep {$_ eq '--debug'} @ARGV;

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):


my @valids = split /\n/ => <<'VALIDS';
abigail@example.com
abigail@example.com 
 abigail@example.com
abigail @example.com
*@example.net
"\""@foo.bar
fred&barny@example.com
---@example.com
foo-bar@example.net
"127.0.0.1"@[127.0.0.1]
Abigail <abigail@example.com>
Abigail<abigail@example.com>
Abigail<@a,@b,@c:abigail@example.com>
"This is a phrase"<abigail@example.com>
"Abigail "<abigail@example.com>
"Joe & J. Harvey" <example @Org>
Abigail <abigail @ example.com>
Abigail made this <  abigail   @   example  .    com    >
Abigail(the bitch)@example.com
Abigail <abigail @ example . (bar) com >
Abigail < (one)  abigail (two) @(three)example . (bar) com (quz) >
Abigail (foo) (((baz)(nested) (comment)) ! ) < (one)  abigail (two) @(three)example . (bar) com (quz) >
Abigail <abigail(fo\(o)@example.com>
Abigail <abigail(fo\)o)@example.com>
(foo) abigail@example.com
abigail@example.com (foo)
"Abi\"gail" <abigail@example.com>
abigail@[example.com]
abigail@[exa\[ple.com]
abigail@[exa\]ple.com]
":sysmail"@  Some-Group. Some-Org
Muhammed.(I am  the greatest) Ali @(the)Vegas.WBA
mailbox.sub1.sub2@this-domain
sub-net.mailbox@sub-domain.domain
name:;
':;
name:   ;
Alfred Neuman <Neuman@BBN-TENEXA>
Neuman@BBN-TENEXA
"George, Ted" <Shared@Group.Arpanet>
Wilt . (the  Stilt) Chamberlain@NBA.US
Cruisers:  Port@Portugal, Jones@SEA;
$@[]
*()@[]
VALIDS

push @valids =>
    qq {"Joe & J. Harvey"\x0D\x0A     <ddd\@ Org>},
    qq {"Joe &\x0D\x0A J. Harvey" <ddd \@ Org>},
    qq {Gourmets:  Pompous Person <WhoZiWhatZit\@Cordon-Bleu>,\x0D\x0A}   .
    qq {        Childs\@WGBH.Boston, "Galloping Gourmet"\@\x0D\x0A}       .
    qq {        ANT.Down-Under (Australian National Television),\x0D\x0A} .
    qq {        Cheapie\@Discount-Liquors;},
;

my @invalids = split /\n/ => <<'INVALIDS';
Just a string
string
(comment)
()@example.com
fred(&)barny@example.com
fred\ barny@example.com
Abigail <abi gail @ example.com>
Abigail <abigail(fo(o)@example.com>
Abigail <abigail(fo)o)@example.com>
"Abi"gail" <abigail@example.com>
abigail@[exa]ple.com]
abigail@[exa[ple.com]
abigail@[exaple].com]
abigail@
@example.com
phrase: abigail@example.com abigail@example.com ;
INVALIDS

push @invalids =>
    # Invalid, only a LF, no CR.
    qq {"Joe & J. Harvey"\x0A <ddd\@ Org>},
    # Invalid, CR LF not followed by a space.
    qq {"Joe &\x0D\x0AJ. Harvey" <ddd \@ Org>},
    # This appears in RFC 822, but ``Galloping Gourmet'' should be quoted.
    qq {Gourmets:  Pompous Person <WhoZiWhatZit\@Cordon-Bleu>,\x0D\x0A}   .
    qq {        Childs\@WGBH.Boston, Galloping Gourmet\@\x0D\x0A}         .
    qq {        ANT.Down-Under (Australian National Television),\x0D\x0A} .
    qq {        Cheapie\@Discount-Liquors;},
    # Invalid, only a CR, no LF.
    qq {"Joe & J. Harvey"\x0D <ddd\@ Org>},
;

my $c = 1;
foreach my $test (@valids) {
    my $d = sprintf "%3d" => ++ $c;
    my $valid = valid ($test);
    print $valid ? "ok $d" : "not ok $d";
    print "#  [VALID: $test] " unless $valid;
    print "\n";
}

foreach my $test (@invalids) {
    my $d = sprintf "%3d" => ++ $c;
    my $valid = valid ($test);
    print $valid ? "not ok $d" : "ok $d";
    print "#  [INVALID: $test] " if $valid;
    print "\n";
}


