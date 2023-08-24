#!/usr/bin/env perl

=head1 DESCRIPTION

Check that literal values work as expected.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

use Resource::Silo;

resource life => literal => 42;

lives_and {
    silo->ctl->lock;
    is silo->life, 42, "value made it through despite lock";
};

done_testing;

