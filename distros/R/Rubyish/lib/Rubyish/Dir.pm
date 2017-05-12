=head1 NAME

Rubyish::Dir - Dir (class)

=cut

package Rubyish::Dir;
use strict;
use 5.010;

use base "Rubyish::Object";
use Rubyish::Syntax::def;


def pwd {
    use Cwd;
    cwd();
};

1;
