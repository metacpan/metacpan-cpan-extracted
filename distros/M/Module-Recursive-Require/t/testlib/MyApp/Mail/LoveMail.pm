package MyApp::Mail::LoveMail;

use strict;
use warnings;
use base qw/MyApp::Mail/;

sub send {
    my $self = shift;

    my $body = "I Love You!\n";

    $self->SUPER::send($body);

    return "1";
}

1;
