package main;

use 5.006;

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Test;
use My::Module::Test qw{ __quote };

note <<'EOD';
Obviously this is not a true fuzz test, just a collection of
pathological strings discovered via fuzz testing. Because the parse of
an invalid string may change, we just see if the code survived the test.
EOD

survival( 'x//' );

survival( ' ' );

done_testing;

sub survival {
    my ( $expr ) = @_;
    my $title = join ' ', 'Parse', __quote( $expr );
    eval {
	PPIx::Regexp->new( $expr );
	1;
    } and do {
	@_ = ( $title );
	goto &pass;
    } or do {
	@_ = ( "$title failed: $@" );
	goto &fail;
    };
}

1;

# ex: set textwidth=72 :
