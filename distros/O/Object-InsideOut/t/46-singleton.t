use strict;
use warnings;

use Config;
BEGIN {
    if (! $Config{useithreads} || $] < 5.008) {
        print("1..0 # Skip Threads not supported\n");
        exit(0);
    }
}


use threads;
use threads::shared;

if ($threads::shared::VERSION lt '1.33') {
    print("1..0 # Skip Need threads::shared v1.33 or later\n");
    exit(0);
}

if ($] == 5.008) {
    require 't/test.pl';   # Test::More work-alike for Perl 5.8.0
} else {
    require Test::More;
}
Test::More->import();
plan('tests' => 1);

package Single; {
    use Object::InsideOut qw(:SHARED);

    my $singleton;
    my %field1 :Field :All(f1);
    my %field2 :Field;

    sub new
    {
        my $thing = shift;

        if (!$singleton) {
            $singleton = $thing->Object::InsideOut::new(@_);
        }

        return $singleton;
    }
}

package main;

my $obj = Single->new(f1 => 'bork');

is($obj->f1(), 'bork', 'Singleton fetch');

# The real test is that no segfault occurs when this test exits

# EOF
