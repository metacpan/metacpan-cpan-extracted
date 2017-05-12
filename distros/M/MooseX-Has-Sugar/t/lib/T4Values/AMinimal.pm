package  T4Values::AMinimal;

# $Id:$
use strict;
use warnings;

use MooseX::Has::Sugar::Minimal;
use namespace::clean -except => 'meta';

sub ro_generated { { isa => 'Str', is => ro, } }

sub ro_manual { { isa => 'Str', is => 'ro', } }

sub rw_generated { { isa => 'Str', is => rw, } }

sub rw_manual { { isa => 'Str', is => 'rw', } }

sub bare_generated { { isa => 'Str', is => bare, } }

sub bare_manual { { isa => 'Str', is => 'bare', } }

1;

