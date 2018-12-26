#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use MySQL::Workbench::DBIC::FakeDBIC;

my @subs = qw(load_components table add_columns set_primary_key belongs_to has_many);
for my $sub ( @subs ) {
    my $sub_ref = DBIx::Class->can($sub);
    ok !$sub_ref->();
}




done_testing();
