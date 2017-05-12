# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 5 };
use Parse::RecDescent::Deparse;
ok(1); # If we made it this far, we're ok.

undef $/;
my $g = new Parse::RecDescent(scalar <DATA>);
my $t = $g->deparse;
ok($t);
my $x;
ok(eval {$x = new Parse::RecDescent($t); $x});
my $y = $x->deparse;
ok($y);
ok($y eq $t); 

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

__DATA__

 grammar    : component(s)

 component  : rule | comment

 rule       : "\n" identifier ":" production(s?)

 production : item(s) 

 item       : lookahead(?) simpleitem
            | directive
            | comment

 lookahead  : '...' | '...!'                   # +'ve or -'ve lookahead
 
 simpleitem : subrule args(?)                  # match another rule
            | repetition                       # match repeated subrules
            | terminal                         # match the next input
            | bracket args(?)                  # match alternative items
            | action                           # do something

 subrule    : identifier                       # the name of the rule

 args       : {extract_codeblock($text,'[]')}  # just like a [...] array ref

 repetition : subrule args(?) howoften

 howoften   : '(?)'                            # 0 or 1 times
            | '(s?)'                           # 0 or more times
            | '(s)'                            # 1 or more times
            | /(\d+)[.][.](\d+)/               # $1 to $2 times
            | /[.][.](\d*)/                    # at most $1 times
            | /(\d*)[.][.]/                    # at least $1 times

 terminal   : /[\/]([\][\/]|[^\/])*[\/]/       # interpolated pattern
            | /"([\]"|[^"])*"/                 # interpolated literal
            | /'([\]'|[^'])*'/                 # uninterpolated literal

 action     : { extract_codeblock($text) }     # embedded Perl code

 bracket    : '(' item(s) production(s?) ')'   # alternative subrules

 directive  : '<commit>'                       # commit to production
            | '<uncommit>'                     # cancel commitment
            | '<resync>'                       # skip to newline
            | '<resync:' pattern '>'           # skip <pattern>
            | '<reject>'                       # fail this production
            | '<reject:' condition '>'         # fail if <condition>
            | '<error>'                        # report an error
            | '<error:' string '>'             # report error as "<string>"
            | '<error?>'                       # error only if committed
            | '<error?:' string '>'            #   "    "    "    "
            | '<rulevar:' /[^>]+/ '>'          # define rule-local variable
            | '<matchrule:' string '>'         # invoke rule named in string

 identifier : /[a-z]\w*/i                      # must start with alpha

 comment    : /#[^\n]*/                        # same as Perl

 pattern    : {extract_bracketed($text,'<')}   # allow embedded "<..>"

 condition  : {extract_codeblock($text,'{<')}  # full Perl expression

 string     : {extract_variable($text)}        # any Perl variable
            | {extract_quotelike($text)}       #   or quotelike string
            | {extract_bracketed($text,'<')}   #   or balanced brackets


