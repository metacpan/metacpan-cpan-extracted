use FindBin;
use lib "$FindBin::Bin/../lib";

use strict;
use warnings;
use Test::More tests => 5; # done testing doesn't work on Perl v5.8?

BEGIN { use_ok 'Perl::Builtins' }

# Perl v5.16 and higher have more functions
my $expected_functions = substr( $], 3, 2) >= 16 ? 224 : 215;

# list context
ok my @list = Perl::Builtins::list, 'list() in list context';
is @list, $expected_functions, 'list() returns the right number of functions';

# scalar context
ok my $list_ref = Perl::Builtins::list, 'list() in scalar context';
is @$list_ref, $expected_functions, 'list() in scalar context returns the right number of functions';

