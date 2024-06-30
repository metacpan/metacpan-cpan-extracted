use v5.36;
use warnings;

use Switch::Right;

use Test2::V0;

# Catch and check warnings...
my $expect;
BEGIN {
    $SIG{__WARN__} = sub (@msg) {
        like "@msg", $expect => "Expected error message found: @msg";
    }
}

BEGIN { $expect = qr{^\Q"when (true) {...}" better written as "default {...}"}}
given ('whatever') {
    when (true)  { pass 'when (true)' }
    default      { fail 'when (true)' }
}

given ('whatever') {
    when (true)  { pass 'when (true)' }
    default      { fail 'when (true)' }
    break;
}

BEGIN { $expect = qr{^\QUseless use of "when (false)"}}
given ('whatever') {
    when (false)  { fail 'when (false)' }
    default       { pass 'when (false)' }
}

given ('whatever') {
    when (false)  { fail 'when (false)' }
    default       { pass 'when (false)' }
    break;
}

BEGIN { $expect = undef }
given ('whatever') {
    when (true())  { pass 'when (true())' }
    default        { fail 'when (true())' }
}

given ('whatever') {
    when (false())  { fail 'when (false())' }
    default         { pass 'when (false())' }
}


given ('whatever') {
    when ((true))  { pass 'when ((true))' }
    default        { fail 'when ((true))' }
}

given ('whatever') {
    when ((false))  { fail 'when ((false))' }
    default         { pass 'when ((false))' }
}



done_testing();

