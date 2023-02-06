use strict;
use warnings;

### Mock parent for @ISA
package Prima::Drawable;

#####################################
package Prima::Widget;  # mock class
#####################################

our @ISA = ('Prima::Drawable');

sub new { return bless {} }
sub height { 10 }
sub width { 20 }

package main;
use Test::More;

# A suite of tests to ensure that the size-spec module works as advertised.

use PDL::Graphics::Prima::SizeSpec;

my $widget = Prima::Widget->new;
ok($widget->isa('Prima::Widget'), 'Mock class claims to be a Prima::Widget');

my $parser = PDL::Graphics::Prima::SizeSpec::Parser->new($widget);

my $size = $parser->parse('10%width - 4');
is($size->size, -2, 'Size spec works');

done_testing();
