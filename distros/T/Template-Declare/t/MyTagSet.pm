package t::MyTagSet;

use strict;
use warnings;
use base 'Template::Declare::TagSet';

sub get_tag_list {
    [qw/ foo bar baz boz /];
}

1;
