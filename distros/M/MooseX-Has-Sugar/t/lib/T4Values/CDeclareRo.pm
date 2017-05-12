package  T4Values::CDeclareRo;

# $Id:$
use strict;
use warnings;
use MooseX::Has::Sugar;
use namespace::clean -except => 'meta';

sub generated { { isa => 'Str', ro, } }

sub manual { { isa => 'Str', is => 'ro', } }

1;

