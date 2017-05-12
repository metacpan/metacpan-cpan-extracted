use strict;
use warnings;
use Test::Base;
BEGIN {
    eval q[use Sledge::TestPages;];
    plan skip_all => "Sledge::TestPages required for testing base" if $@;
};
use t::TestPages;

plan tests => 1*blocks;

run {
    my $block = shift;

    $ENV{$block->input} = $block->expected;

    no strict 'refs';
    local *{"t::TestPages::dispatch_test"} = sub { ## no critic
        my $self = shift;

        is($self->session->session_id, $block->expected);
        $self->finished(1);
    };

    my $pages = t::TestPages->new;
    $pages->dispatch('test');
    delete $ENV{$block->input}; # clear env
};

__END__
=== agent is kddi
--- input chomp
HTTP_X_UP_SUBNO
--- expected chomp
SID_EZ_MOBILE_ID
=== agent is softbank
--- input chomp
HTTP_X_JPHONE_UID
--- expected chomp
SID_SB_MOBILE_ID
