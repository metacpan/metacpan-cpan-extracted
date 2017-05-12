#!/usr/bin/perl 

=pod

In your ~/.config/nvim/init.vim, have something like

    function! TW_done(channel)
        call rpcrequest( a:channel, 'tw_done' )
    endfunction

    function! TW_show(...)
        if a:0
            call rpcrequest( g:nvimx_channel, 'tw_show', a:1 )
        else
            let filter = input( "filter: ", " " )
            call rpcrequest( g:nvimx_channel, 'tw_show', filter )
        endif

    endfunction

    function! TW_toggle_focus(channel)
        call rpcrequest( a:channel, 'tw_toggle_focus' )
    endfunction

    function! TW_mod(channel)
        call rpcrequest( a:channel, 'tw_mod' )
    endfunction

    au FileType task map <leader>d :call TW_done(nvimx_channel)<CR>
    au FileType task map <leader>ll :call TW_show('+PENDING -WAITING -BLOCKED')<CR>
    au FileType task map <leader>lq :call TW_show()<CR>
    au FileType task map <leader>m :call TW_mod(nvimx_channel)<CR>
    au FileType task map <leader>f :call TW_toggle_focus(nvimx_channel)<CR>
    au FileType task map <buffer> <leader>ph :call TW_mod(nvimx_channel)<CR>

    au FileType task set nowrap

    " requires the plugin dhruvasagar/vim-table-mode
    au FileType task TableModeEnable

then set the env variable NVIM_LISTEN_ADDRESS to, say,
C<127.0.0.1:6543> and start nvim in one shell, and
this script in another, and enjoy your new nvim-powered taskwarrior UI!

=cut

use 5.10.0;

use strict;
use warnings;

use IPC::Run3;
use Neovim::RPC;
use Taskwarrior::Hooks;
use List::SomeUtils qw/ nsort_by /;
use Promises qw/  deferred /;
use List::Util qw/ reduce /;
use DateTime;
use DateTime::Format::ISO8601;


use experimental 'postderef', 'signatures';

my $tw = Taskwarrior::Hooks->new;

my $rpc = Neovim::RPC->new(
    log_to_stderr => 0,
    debug => 0,
);


sub task_line {
    my $task = shift;
    $task->{urgency} = sprintf "%03d", $task->{urgency};
    $task->{tags} &&= join ' ', $task->{tags}->@*;

    if ( length $task->{description} > 30 ) {
        $task->{description} = ( substr $task->{description}, 0, 27 ) . '...';
    }

    if ( length $task->{project} > 15 ) {
        $task->{project} = ( substr $task->{description}, 0, 12 ) . '...';
    }

    $task->{$_} = relative_time($task->{$_}) for qw/ due /; 
    $task->{$_} = relative_time($task->{$_},-1) for qw/ modified /; 

    no warnings;
    return join '|', undef, 
            $task->@{qw/ urgency priority due description project tags modified uuid /},
            undef;
}

$rpc->subscribe( 'tw_show' => sub {
    my $event = shift;

    then_chain(
        sub { $event->resp('ok') },
        $rpc->api->vim_input( "1GdG" ),
        sub{ $rpc->api->vim_get_current_buffer },
        sub{ ord $_[0]->data },
        sub($buffer_id) { 
            
            my @things = 
                grep { $_ }
                map { task_line($_) } $tw->export_tasks(  '+PENDING', $event->all_args );

            s/\n/ /g for @things;

            $rpc->api->buffer_insert( $buffer_id, 0, [
                @things
            ])        
        },
        sub { $rpc->api->vim_input( '1G' ); },
        sub { $rpc->api->vim_command( ':TableModeRealign' ); }
    )
});

$rpc->subscribe( 'tw_toggle_focus' => sub {
    my $event = shift;

    my $buffer_id;
    my $task;
    my $mod;
    my $has_focus;

    (reduce { $a->then($b) } 
        $rpc->api->vim_get_current_line,
        sub { 
            my $an = qr/[a-f0-9]/;
            my $re =  "(${an}{8}-(${an}{4}-){3}${an}{12})";
            $_[0] =~ $re or die "no task uuid found";
            $task = $1;
            warn $task;
            $has_focus = $_[0] =~ /focus/;
        },
        sub { 
            $mod = shift;
            use IPC::Run3;
            my $output;
            warn $task;
            run3 [ 'task', "uuid:$task", 'mod',  ( $has_focus ? '-' : '+' ) .'focus'  ], undef, \$output, \$output; 
            $output =~ s/^Configuration override.*?$//mg;
            $output =~ s/"/''/g;
            $rpc->api->vim_command( qq{echo "mod $task\n$output"} ); 
            $task;
        },
        sub{ $rpc->api->vim_set_current_line( 
            task_line( $tw->export_tasks( 'uuid:'.$task ) )
        )},
        sub { $rpc->api->vim_command( ':TableModeRealign' ); }
    )->catch(sub{ warn @_ });

    $event->resp('ok');
});

$rpc->subscribe( 'tw_mod' => sub {
    my $event = shift;

    my $buffer_id;
    use List::Util qw/ reduce /;
    my $task;
    my $mod;
    (reduce { $a->then($b) } 
        $rpc->api->vim_get_current_buffer,
        sub{ $buffer_id = ord $_[0]->data },
        sub{ $rpc->api->vim_get_current_line },
        sub { 
            my $an = qr/[a-f0-9]/;
            my $re =  "(${an}{8}-(${an}{4}-){3}${an}{12})";
            shift =~ $re or die "no task uuid found";
            $task = $1;
        },
        sub { $rpc->api->vim_command("let i = input( 'mod: ' )") },
        sub { $rpc->api->vim_get_var("i"); },
        sub { 
            $mod = shift;
            use IPC::Run3;
            my $output;
            run3 [ 'task', "uuid:$task", 'mod', $mod ], undef, \$output, \$output; 
            $output =~ s/^Configuration override.*?$//mg;
            $output =~ s/"/''/g;
            $rpc->api->vim_command( qq{echomsg "mod $task\n$output"} ); 
            $task;
        },
        sub{ $rpc->api->vim_set_current_line( 
            task_line( $tw->export_tasks( 'uuid:'.$task ) )
        )},
        sub { $rpc->api->vim_command( ':TableModeRealign' ); }
    )->catch(sub{ warn @_ });

    $event->resp('ok');
});

$rpc->subscribe( 'tw_done' => sub {
    my $event = shift;
    say $event->all_args;

    my $buffer_id;
    my $task;

    then_chain(
        $event->resp('ok'),
        sub { $rpc->api->vim_get_current_buffer },
        sub{ $buffer_id = ord $_[0]->data },
        sub{ $rpc->api->vim_get_current_line },
        sub { 
            my $an = qr/[a-f0-9]/;
            my $re =  "(${an}{8}-(${an}{4}-){3}${an}{12})";
            warn $re;
            shift =~ $re or die "no task uuid found";
            $task = $1;
        },
        sub{ $rpc->api->vim_del_current_line },
        sub { 
            my $output;
            run3 [ 'task', "uuid:$task", 'done' ], undef, \$output, \$output; 
            $output =~ s/^Configuration override.*?$//mg;
            $output =~ s/"/''/g;
            $rpc->api->vim_command( qq{echo "$task done: $output"} ); 
        },
    )->catch(sub{ warn @_ });

});

$rpc->loop;

sub then_chain {
    my $d = deferred;
    $d->resolve;

    return reduce { $a->then($b) } $d, @_;
}

sub relative_time($date,$mult=1) {
    state $now = DateTime->now;

    return unless $date;

    # fine, I'll calculate it like a savage

    $date = DateTime::Format::ISO8601->parse_datetime($date)->epoch;

    my $delta = int( $mult * ( $date - time ) / 60 / 60 / 24 );

    return int($delta/365) . 'y' if abs($delta) > 365;
    return int($delta/30) . 'm' if abs($delta) > 30;
    return int($delta/7) . 'm' if abs($delta) > 7;
    return $delta . 'd';
}
