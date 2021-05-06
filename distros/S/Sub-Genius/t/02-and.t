use strict;
use warnings;
use Test::More;

use_ok q{Sub::Genius::Util};

my $sq = Sub::Genius::Util->new( preplan => q{A&B&C} );

isa_ok $sq, q{Sub::Genius::Util};
can_ok( $sq, qw/subs2perl plan2nodeps/ );

# sub class of Sub::Genius, aktually
isa_ok $sq, q{Sub::Genius};
can_ok( $sq, qw/new preplan pregex init_plan plan plan_nein next dfa run_any run_once/ );

done_testing();
exit;

__END__
