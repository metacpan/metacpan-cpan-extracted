use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use parent 'Plack::Test::AnyEvent::Test';

sub impl_name {
    return 'AnyEvent';
}

__PACKAGE__->runtests;
