package TestsFor::Neovim::RPC;

use strict;
use warnings;

use Test::Class::Moose;

use Neovim::RPC;
use Promises qw/ deferred /;

use experimental 'signatures';

has rpc => (
    is => 'ro',
    lazy => 1,
    default => sub {
        #     exec 'nvim', '--headless' unless fork;

        #sleep 1;
        Neovim::RPC->new;
    },
    handles => [ 'api' ],
);

has _loop_end => (
    is => 'rw',
);

sub test_startup {
    $_[0]->test_skip('no nvim listening') unless $ENV{NVIM_LISTEN_ADDRESS};
}

sub test_setup($self,@) {
    $self->_loop_end( deferred );
}

sub end_loop {
    $_[0]->_loop_end->done;
}

sub loop($self) {
    $self->rpc->loop($self->_loop_end);
}

sub test_get_set_current_line($self,@) {
    $self->test_report->plan(2);

    my $string = 'hello world';

    $self->api->vim_set_current_line( line => $string )
        ->on_done(sub{
            pass 'line set';
            $self->api->vim_get_current_line->then(sub{
                is shift(@_) => $string, 'get it back';
                $self->end_loop;
            });;
        });

    $self->loop;
}

sub test_channel($self,@) {
    $self->test_report->plan(2);

    my $id =$self->api->channel_id;
    
    ok $id => 'we have a channel id';

    $self->api->vim_get_var( name => 'nvimx_channel' )->then(sub{
        is shift(@_) => $id, 'available nvim-side too';
        $self->end_loop;
    });

    $self->loop;
}

1;

