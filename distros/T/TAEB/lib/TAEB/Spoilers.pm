package TAEB::Spoilers;
use strict;
use warnings;

use Module::Pluggable (
    require     => 1,
    sub_name    => 'load_spoiler_classes',
    search_path => [__PACKAGE__],
);
__PACKAGE__->load_spoiler_classes;

1;

