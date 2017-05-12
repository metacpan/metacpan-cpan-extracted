use strict;
use warnings;

use Test::More;

use FindBin qw( $Bin );
use lib "$Bin/lib";

my $out;
open(my $out_fh, '>', \$out);

select($out_fh);
require 'Synopsis.pm';
select(STDOUT);

close($out_fh);

chomp($out);
is($out, "Foo applied to Bar");

done_testing();
