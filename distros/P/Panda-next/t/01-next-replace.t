use 5.012;
use warnings;
use lib 't';
use mro;
use Test::More;

my $orig_can   = \&next::can;
my $orig_next  = \&next::method;
my $orig_maybe = \&maybe::next::method;

require Panda::next;

isnt(\&next::can, $orig_can);
isnt(\&next::method, $orig_next);
isnt(\&maybe::next::method, $orig_maybe);

done_testing();