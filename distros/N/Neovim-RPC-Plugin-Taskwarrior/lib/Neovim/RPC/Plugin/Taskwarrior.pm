package Neovim::RPC::Plugin::Taskwarrior;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: UI for taskwarrior
$Neovim::RPC::Plugin::Taskwarrior::VERSION = '0.0.1';

use 5.20.0;

use Neovim::RPC::Plugin;
use DateTime;
use DateTime::Format::ISO8601;
use Promises qw/ collect deferred /;

use Taskwarrior::Kusarigama::Wrapper;

use experimental 'signatures', 'postderef';

has task => (
    is => 'ro',
    lazy => 1,
    default => sub {
        Taskwarrior::Kusarigama::Wrapper->new
    },
);

sub BUILD {
    my $self = shift;

    $self->api->ready->then(sub{
        $self->api->nvim_command( 'set filetype=task' )
    })
    ->then(sub{ 
        $self->api->nvim_command( "call TW_show('+PENDING')")
    });
    
}

before register => sub($self) {
    push @$_, {
        catch => sub($self,$warn,@) { 
            $warn = @$warn if ref $warn eq 'ARRAY';
            $warn =~ s/\n.*//s;
            $self->rpc->api->vim_command(  qq{echo "perl error: $warn"} );
            warn $warn;
        }
    } for values $self->subscriptions->%*;
};

subscribe tw_done => 
    sub($self,$event) { 
        $self->extract_uuids($event->params->[0]->@*) 
    }
    => sub($self,@uuids) {
        warn "here", time;
        #$self->rpc->api->vim_command( "g/$_/d" ) for @uuids;
        $self->rpc->send_notification( 'vim_command', [ "g/$_/d" ] ) for @uuids;
        warn "there", time;
        deferred(sub {
            $self->task->done( [ "confirmation:no" ], $_ ) for @uuids;
        });
    };

subscribe tw_mod => rpcrequest
    sub( $self, $event ) {
        my( $mod, $from, $to, $lines ) = $event->all_params;
        my @uuids = $self->extract_uuids($lines->@*);
        my(undef, @condition) = map { ( 'or', "uuid:$_" ) } @uuids;

        $self->task->mod( [ @condition ], $mod );

         $self->rpc->api->vim_get_current_buffer
            ->then(sub{ ord $_[0]->data })
            ->then(sub($buffer_id) { 
                $self->rpc->api->nvim_buf_set_lines( $buffer_id, $from-1, $to, 0, [
                 map { $self->task_line($_) } $self->task->export( [ @condition ] ) 
             ])        
         })
    }
;

subscribe tw_append => rpcrequest
    sub( $self, $event ) {
        my( $mod, $from, $to, $lines ) = $event->all_params;
        my @uuids = $self->extract_uuids($lines->@*);
        my(undef, @condition) = map { ( 'or', "uuid:$_" ) } @uuids;

        $self->task->append( [ @condition ], $mod );

         $self->rpc->api->vim_get_current_buffer
            ->then(sub{ ord $_[0]->data })
            ->then(sub($buffer_id) { 
                $self->rpc->api->nvim_buf_set_lines( $buffer_id, $from-1, $to, 0, [
                 map { $self->task_line($_) } $self->task->export( [ @condition ] ) 
             ])        
         })
    }
;

subscribe tw_wait => rpcrequest(
    sub( $self, $event ) {
        my( $wait, $from, $to, $lines ) = $event->all_params;
        ( $wait, $self->extract_uuids($lines->@*) );
    },
    sub( $self, $wait, @uuids ) {
        $self->rpc->send_notification( 'vim_command', [ "g/$_/d" ] ) for @uuids;
        ( $wait, @uuids );
    } ),
    sub ( $self, $wait, @uuids ) {
        my $condition = join ' or ', map { "uuid:$_" } @uuids;

        $self->task->wait( [ 'confirmation:no', $condition ], $wait );

    }
;

subscribe tw_delete => rpcrequest
    sub($self,$event) { $self->extract_uuids($event->params->[0]->@*) }
    => sub($self,@uuids) {
        my @promises;
        for my $uuid ( @uuids ) {
            # TODO make this promisable?
            $self->task->delete( [ "rc.confirmation:no" ], $uuid );
            push @promises, $self->rpc->api->vim_command( "g/$uuid/d" )->then(sub{
                $self->rpc->api->vim_command( "echo 'deleted $uuid'" );
            } );
        }
        return collect @promises;
    };

subscribe tw_info => rpcrequest
    sub($self,$event) { $self->extract_uuids($event->params->[0]->@*) }
    => sub($self,@uuids) {
        my $promise = deferred;
        $promise->resolve;

        for my $uuid ( @uuids ) {
            my @info = map { length $_ ? $_ : ' ' } $self->task->info($uuid);
            $promise = $promise->then(sub{
                $self->api->vim_command('new');
            })
         ->then(sub{ $self->rpc->api->vim_get_current_buffer })
         ->then(sub{ ord $_[0]->data })
         ->then(sub($buffer_id) { 
             $self->rpc->api->buffer_insert( $buffer_id, 0, [
                 @info
             ])        
         })
         ->then(sub { $self->rpc->api->vim_input( '1G' ) });

        }

        return $promise;
    };


subscribe tw_show => rpcrequest 
    sub( $self, $event ) {
        my $buffer_id;

        $self->rpc->api->vim_get_current_buffer
        ->then(sub{ $buffer_id = ord $_[0]->data })
        ->then(sub{
            my @tasks = $self->task->export( '+READY', $event->all_params );

            my @things = 
                map { $self->task_line($_) } 
                sort { $b->{urgency}  - $a->{urgency} } 
                @tasks;

            s/\n/ /g for @things;

            return @things;
        })
        ->then( sub{
            $self->rpc->api->nvim_buf_set_lines( $buffer_id, 0, 1E6, 0, [ @_ ] );
        })
},
        sub { $_[0]->rpc->api->vim_input( '1G' ); },
        sub { $_[0]->rpc->api->vim_command( ':TableModeRealign' ); };
        
sub tw_output($self,@lines) {
    $self->tw_output_window
        ->then( sub { 
            $self->rpc->api->nvim_buf_set_lines( $_[0], -1, -1, 0, [ '', @lines, '' ] ) 
        });
}

sub extract_uuids($self,@lines) {
    my $o = '[a-f0-9]';
    map { /($o{8}(?:-$o{4}){3}-$o{12})/g } @lines;
}

sub task_line($self,$task) {
    $task->{urgency} = sprintf "%03d", $task->{urgency};
    $task->{tags} &&= join ' ', $task->{tags}->@*;

    # if ( length $task->{description} > 30 ) {
    #     $task->{description} = ( substr $task->{description}, 0, 27 ) . '...';
    # }

    no warnings 'uninitialized';
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

sub relative_time($date,$mult=1) {
    state $now = DateTime->now;

    return unless $date;

    # fine, I'll calculate it like a savage

    $date = DateTime::Format::ISO8601->parse_datetime($date)->epoch;

    my $delta = int( $mult * ( $date - time ) / 60 / 60 / 24 );

    return int($delta/365) . 'y' if abs($delta) > 365;
    return int($delta/30) . 'm' if abs($delta) > 30;
    return int($delta/7) . 'w' if abs($delta) > 7;
    return $delta . 'd';
}

sub tw_output_window ($self) {
    $self->_tw_find_output_window()
        ->catch(sub{ $self->_tw_create_output_window()
                ->then(sub{ $self->_tw_find_output_window() })
    })
}

sub _tw_create_output_window($self) {
    $self->rpc->api->vim_command( ':pedit ~/.task/nvim_task.log');
}

sub _tw_find_output_window($self) {
    $self->rpc->api->nvim_list_bufs->then(sub($list){
            my $promise = deferred;
            $promise->reject;

            for my $id ( map { ord $_->data } @$list ) {
                $promise = $promise->catch(sub{
                    $self->rpc->api->nvim_buf_get_name($id)
                        ->then(sub { 
                                $_[0] =~ /nvim_task\.log/ ? $id : die } );
                });
            }


            return $promise;
    })
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neovim::RPC::Plugin::Taskwarrior - UI for taskwarrior

=head1 VERSION

version 0.0.1

=head1 DESCRIPTION

This plugin needs a few things to work.

First, C<nvim> must be configured to use L<Neovim::RPC> (duh).

Then configure nvim to use the vim side of this plugin as well as
TableMode. I use C<Plugged>, and  my configuration looks like:

    Plug 'yanick/Neovim-RPC-Plugin-Taskwarrior'
    Plug 'dhruvasagar/vim-table-mode', {
        \ 'on': [ 'TableModeEnable' ]
    \ }

Once all of that is done, you can invoke the taskwarrior UI via
C<:Task>. Or straight from the command-line as 

    $ nvim -c 'call Task()'

The plugin has a slew of commands built-in. Right now,
if you want to change the aliases, just go and dive in
F<taskwarrior.vim>.

    | command    | mode           | description                                |
    | ----       | ---            | ---                                        |
    | <leader>d  | normal, visual | mark task(s) as done                       |
    | <leader>D  | normal, visual | delete task(s)                             |
    | <leader>ll | normal         | show all +PENDING tasks                    |
    | <leader>lf | normal         | show all +focus tasks                      |
    | <leader>lq | normal         | show tasks, prompt for filter              |
    | <leader>m  | normal, visual | mod task(s), prompt for modification       |
    | <leader>m  | normal, visual | append to task(s), prompt for modification |
    | <leader>i  | normal, visual | show info for task(s)                      |
    | <leader>ph | normal, visual | set priority of task(s) to be high         |
    | <leader>pm | normal, visual | set priority of task(s) to be medium       |
    | <leader>pl | normal, visual | set priority of task(s) to be low          |
    | <leader>W  | normal, visual | set 'wait' for task(s)                     |

The plugin will set the buffer listing the tasks as  a file of type C<task>.

=head1 AUTHOR

Yanick Champoux <yanick@babyl.dyndns.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Yanick Champoux.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
