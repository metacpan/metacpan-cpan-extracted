package MyApp::Mail;

use strict;
use warnings;

sub new {
    bless ({}, shift());
}

sub send {
    my $self = shift;
    my $body = shift;

    return 1;
}

1;
