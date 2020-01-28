package Pegex::JSON::Data;
use Pegex::Base;
extends 'Pegex::Tree';

use boolean;

sub got_json { shift @{(pop)} }

sub got_object { +{map @$_, @{(pop)}} }

my %escapes = (
    '"' => '"',
    '/' => "/",
    "\\" => "\\",
    b => "\b",
    f => "\x12",
    n => "\n",
    r => "\r",
    t => "\t",
);

sub got_string {
    my $string = pop;
    $string =~ s/\\(["\/\\bfnrt])/$escapes{$1}/ge;
    # This handles JSON encoded Unicode surrogate pairs
    $string =~ s/\\u([0-9a-f]{4})\\u([0-9a-f]{4})/pack "U*", hex("$1$2")/ge;
    $string =~ s/\\u([0-9a-f]{4})/pack "U*", hex($1)/ge;
    return $string;
}

sub got_number { (pop) + 0 }
sub got_true { &boolean::true }
sub got_false { &boolean::false }
sub got_null { undef }

1;
