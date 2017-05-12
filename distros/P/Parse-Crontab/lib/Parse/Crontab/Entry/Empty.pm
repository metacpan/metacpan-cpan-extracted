package Parse::Crontab::Entry::Empty;
use 5.008_001;
use strict;
use warnings;

use Mouse;
extends 'Parse::Crontab::Entry';


no Mouse;

__PACKAGE__->meta->make_immutable;
