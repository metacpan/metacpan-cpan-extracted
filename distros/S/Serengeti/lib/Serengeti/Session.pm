package Serengeti::Session;

use strict;
use warnings;

use Serengeti::Session::Persistent;

use accessors::ro qw(stash);

sub new {
    my ($pkg, $args) = @_;
    
    if (exists $args->{name}) {
        return Serengeti::Session::Persistent->new($args);
    }

    my $self = bless { stash => {}, }, $pkg;

    return $self;
}

1;