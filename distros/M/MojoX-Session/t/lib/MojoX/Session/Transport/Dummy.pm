package MojoX::Session::Transport::Dummy;

use strict;
use warnings;

use base 'MojoX::Session::Transport';

__PACKAGE__->attr([qw/ get set /]);

1;
