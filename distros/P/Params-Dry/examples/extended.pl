#!/usr/bin/env perl
#*
#* Name: standard.pl
#* Info: just an example of syntax
#* Author: Pawel Guspiel (neo77) <merlin@panth-net.com>
#*
package ParamsTest;

use strict;
use warnings;

our $VERSION = 1.0;

#=------------------------------------------------------------------------( use, constants )

# --- find bin ---
use FindBin qw/$Bin/;
use lib $Bin."/../lib";

use Params::Dry qw(:short);

#=------------------------------------------------------------------------( typedef definitions )

typedef 'name', 'Int[2]|Float[5,2]';
typedef 'bex', 'name|String[2]';
typedef 'rex', 'bex|Array|name|Int[2]|Int[5]';

#=------------------------------------------------------------------------( functions )


sub ab {
    my $self = __@_;

    my $p_ab = rq 'rex';

    print $p_ab;
}
ab(rex =>'dfdsfsfds 23.43');
print Params::Dry::__get_effective_type('rex');
