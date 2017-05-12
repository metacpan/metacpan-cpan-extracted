package Morpheus::Bootstrap::_Extra;
use strict;
use warnings;

use Morpheus::Plugin::Simple;

sub new {
    return Morpheus::Plugin::Simple->new({
        "morpheus/plugins/Bootstrap::Extra" => {
            priority => 0,
            object => 0,
        }
    });
}

1;

