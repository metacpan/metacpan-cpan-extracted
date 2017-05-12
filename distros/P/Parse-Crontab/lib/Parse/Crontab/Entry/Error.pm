package Parse::Crontab::Entry::Error;
use 5.008_001;
use strict;
use warnings;
use Mouse;
extends 'Parse::Crontab::Entry';

has '+is_error' => (
    default => 1,
);

no Mouse;

__PACKAGE__->meta->make_immutable;
