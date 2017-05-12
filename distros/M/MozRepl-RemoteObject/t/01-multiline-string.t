#!perl -w
use strict;
use Test::More;

use MozRepl::RemoteObject 'as_list';

diag "--- Loading object functionality into repl\n";

my $repl;
my $ok = eval {
    $repl = MozRepl::RemoteObject->install_bridge(
        #log => [qw[debug]],
        use_queue => 1,
    );
    1;
};
if (! $ok) {
    my $err = $@;
    plan skip_all => "Couldn't connect to MozRepl: $@";
} else {
    plan tests => 5;
};

sub identity {
    my ($val) = @_;
    my $id = $repl->declare(<<JS);
function(val) {
    return val;
}
JS
    $id->($val);
}

# we define explicit newlines here!
for my $newline ("\r\n", "\x0d", "\x0a", "\x0d\x0a", "\x0a\x0d") {
    my $expected = "first line${newline}second line"; 
    my $got = identity($expected);
    (my $visual = $newline) =~ s!([\x00-\x1F])!sprintf "\\x%02x", ord $1!eg;
    is $got, $expected, "$visual survives roundtrip";
};
