package ToDo::Controller::Home;
use strict;
use warnings;
use HTTP::Status qw( is_error is_info );

sub foo { is_info(100) }

sub bar { is_error(500) }

1;
