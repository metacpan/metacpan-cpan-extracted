package Mock::Api::User;
use strict;
use warnings;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub name { 'nekokak' }

1;

