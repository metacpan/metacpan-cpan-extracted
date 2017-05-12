use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use parent 'Plack::Test::AnyEvent::Test';

sub impl_name {
    return 'AnyEvent';
}

require AnyEvent::Impl::Perl;

__PACKAGE__->runtests;
