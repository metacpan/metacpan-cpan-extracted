package GitHub::WebHook::Acme;
use strict;
use warnings;
use v5.10;

sub new {
    my ($class, %args) = @_;
    $args{status} //= 1;
    bless \%args, $class;
}

sub call {    
    $_[0]->{status}
}

1;
