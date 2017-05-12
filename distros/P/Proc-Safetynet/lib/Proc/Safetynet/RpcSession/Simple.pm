package Proc::Safetynet::RpcSession::Simple;
use strict;
use warnings;

use Proc::Safetynet::POEWorker;
use base qw/Proc::Safetynet::POEWorker/;

use Carp;
use Data::Dumper;
use POE::Kernel;
use POE::Session;

use Proc::Safetynet::Event;
use Proc::Safetynet::Program;
use Proc::Safetynet::ProgramStatus;

use JSON::XS 2.21;
use POE::Filter::JSON::Incr;

my $RPC_METHOD = {
    'start_program'                     => 1,
    'stop_program'                      => 1,
    'list_status'                       => 1,
    'info_status'                       => 1,
    'list_programs'                     => 1,
    'info_program'                      => 1,
    'add_program'                       => 1,
    'remove_program'                    => 1,
    'update_program'                    => 1,
    'commit_programs'                   => 1,
};


sub initialize {
    my $self        = $_[OBJECT];
    $_[KERNEL]->state( 'got_client_input'           => $self );
    $_[KERNEL]->state( 'got_client_error'           => $self );
    $_[KERNEL]->state( 'interpret'                  => $self );
    $_[KERNEL]->state( 'interpret_result'           => $self );
    { # setup wheel
        my $socket = $self->options->{'socket'};
        $self->{client} = POE::Wheel::ReadWrite->new( 
            Handle      => $socket,
            Filter      => POE::Filter::JSON::Incr->new(
                errors      => 1,
                json        => JSON::XS->new->utf8->pretty->allow_blessed->convert_blessed,
            ),
            InputEvent  => 'got_client_input',
            ErrorEvent  => 'got_client_error',
        );
    }
    { # check supervisor
        my $supervisor = $self->options->{'supervisor'};
        if (not defined $supervisor) {
            confess "supervisor not defined";
        }
        $self->{supervisor} = $supervisor;
    }
    $self->{client}->put( { 'method' => 'connected', params => [ ], id => undef } );
}


sub got_client_input {
    my ( $self, $input ) = @_[ OBJECT, ARG0 ];
    my $result = undef;
    #print STDERR Dumper( "$self", $_[STATE], $input );
    if (ref($input) eq 'POE::Filter::JSON::Incr::Error') {
        $result = { result => undef, error => { message => $input->{error}, chunk => $input->{chunk} }, id => undef };
        $self->{client}->put($result);
    }
    else {
        $self->yield( 'interpret' => $input );
    }
}


sub got_client_error {
    my ( $self, $syscall, $errno, $error ) = @_[ OBJECT, ARG0 .. ARG2 ];
    $error = "Normal disconnection." unless $errno;
    $_[KERNEL]->post( 
        $self->{supervisor},
        'bcast_system_info', 
        "Server session encountered $syscall error $errno: $error\n",
    );
    delete $self->{client};
    $self->yield( 'shutdown' );
}


sub interpret {
    my $self        = $_[OBJECT];
    my $input       = $_[ARG0];
    if (ref($input) eq 'HASH') {
        my $result = undef;
        INTERP: {
            if (not defined $input->{method}) {
                $result = {
                    result      => undef,
                    error       => { 'message' => 'method not specified' },
                    id          => $input->{id},
                };
                last INTERP;
            }
            if (not(defined $input->{params}) or (ref($input->{params}) ne 'ARRAY')) {
                $result = {
                    result      => undef,
                    error       => { 'message' => 'invalid params, expected ARRAY' },
                    id          => $input->{id},
                };
                last INTERP;
            }
            if (not $RPC_METHOD->{$input->{method}}) {
                $result = {
                    result      => undef,
                    error       => { 'message' => 'method unsupported' },
                    id          => $input->{id},
                };
                last INTERP;
            }
            # map rpc method into POE events
            my $method      = $input->{method};
            my @params      = @{ $input->{params} };
            my $postback    = [ $self->alias, 'interpret_result' ];
            my $stack       = [ $input ];
            #print Dumper( $self->{supervisor}, $method, $postback, $stack, @params );
            $_[KERNEL]->post( $self->{supervisor}, $method, $postback, $stack, @params )
                or carp "Unable to post: $!\n";
        }
        if (defined $result) {
            $self->{client}->put( $result );
        }
    }
    else {
        $self->{client}->put({
            method  => 'handle_error',
            error   => { "message" => "invalid method call, expected JSON Object (HASH)" },
            id      => undef,
        });
    }
}


sub interpret_result {
    my $self        = $_[OBJECT];
    my $stack       = $_[ARG0];
    my $result      = $_[ARG1];
    my $input       = pop @$stack;
    $result->{id}   = $input->{id};
    $self->{client}->put( $result );
    #print Dumper( [ $_[STATE], $stack, $result ] );
}



1;

__END__
