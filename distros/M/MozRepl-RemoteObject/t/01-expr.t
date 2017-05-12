#!perl -w
use strict;
use Test::More;
use Encode qw(decode encode);

use MozRepl::RemoteObject;

my $repl;
my $ok = eval {
    $repl = MozRepl::RemoteObject->install_bridge(
        #log => [qw[debug]],
    );
    1;
};
if (! $ok) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
} else {
    plan tests => 9;
};

my $four = $repl->expr(<<JS);
    2+2
JS

is $four, 4, "Addition in Javascript works";

my $wrapped_repl = $repl->expr(<<JS);
    repl
JS

my $repl_id = $wrapped_repl->__id;
my $identity = $repl->expr(<<JS);
    repl === repl.getLink($repl_id)
JS

ok $identity, "Object identity in Javascript works";

my $adder = $repl->expr(<<JS);
    f=function(a,b) { 
        // alert(a+b);
        return a+b
    };f
JS
isa_ok $adder, 'MozRepl::RemoteObject::Instance';

my $five = $adder->(2,3);
is $five, 5, "Anonymous functions in Javascript work as well";

# Now check whether we can pass in and out high-bit content

use charnames ':full';
my $unicode = "\N{WHITE SMILING FACE}";
my $result = $adder->("[$unicode","$unicode]");
is $result, "[$unicode$unicode]", "Passing unicode in and out works"
    or do { diag sprintf "%02x", ord($_) for split //, $result};

my $ae = "\N{LATIN CAPITAL LETTER A WITH DIAERESIS}";
my $latin1 = encode('Latin-1',$ae);
my $utf8_ae = decode('Latin-1',$latin1);
is $ae, $utf8_ae, "My assumptions about Latin-1/utf8 hold";
$result = undef;
my $lives = eval {
    $result = $adder->("[$latin1","$latin1]");
    1;
};
my $err = $@;
ok $lives, "We can pass in Latin-1";
is $err, '', "We get no error";
is $result, "[$utf8_ae$utf8_ae]", "We get a unicode result";
