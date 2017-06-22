use warnings;
use strict;

use Test::More;

use Perl6::Controls;

is do{try { die }}, undef() => 'Raw try';

try {
    die 42;
    CATCH { ok $_ =~ /^42\b/ => 'post CATCH'; }
}

try {
    CATCH { ok $_ =~ /^42\b/ => 'pre CATCH'; }
    die 42;
}

try {
    my $var = 86;
    die 42;
    CATCH {
        ok   $_ =~ /^42\b/ => 'closure CATCH error';
        ok $var == 86      => 'closure CATCH var';
    }
}

try {
    die 42;
    CATCH ($e) { ok $e =~ /^42\b/ => 'post CATCH with param'; }
}

try {
    CATCH ($what) { ok $what =~ /^42\b/ => 'pre CATCH with param'; }
    die 42;
}

try {
    my $var = 86;
    die 42;
    CATCH ($error_message) {
        ok $error_message =~ /^42\b/ => 'closure CATCH with param error';
        ok $          var == 86      => 'closure CATCH with param var';
    }
}

try {
     CATCH ($err) { ok $err = 'outer' => 'Outer CATCH' }
     try {
        CATCH ($err) { ok $err = 'middle' => 'Middle CATCH'; }
        try {
            CATCH ($err) { ok $err = 'inner' => 'Inner CATCH'; }
            die 'inner';
        }
        die 'middle'
     }
     die 'outer';
}

done_testing();

