use strict;
use warnings;

use Test::More tests => 5;
use Pod::ROBODoc;

#-------------------------------------------------------------------------------
# Setup variables
#-------------------------------------------------------------------------------
my $pr;

#-------------------------------------------------------------------------------
# Test instantiation and API
#-------------------------------------------------------------------------------
eval { $pr = Pod::ROBODoc->new() };
is( $@, q{}, 'new without options succeeds' );
isa_ok( $pr, 'Pod::ROBODoc' );
can_ok( $pr, qw( convert filter ));

eval { 
    $pr = Pod::ROBODoc->new(
        skipblanks => 1,
        keepsource => 1,
        customtags => [ 'VERSION', 'TODO' ],
    ) 
};
is( $@, q{}, 'new with all options succeeds' );
isa_ok( $pr, 'Pod::ROBODoc' );
