package Pcore::Core::Log;

use Pcore -class;
use Pcore::Core::Log::Channel;

has channel => ( is => 'lazy', isa => HashRef, default => sub { {} }, init_arg => undef );

our $PIPE = {};    # weak refs, pipes are global

sub add ( $self, $name, @ ) {
    my $ch;

    my $args = { name => $name };

    my @pipe;

    if ( ref $_[2] eq 'HASH' ) {
        $args->@{ keys $_[2]->%* } = values $_[2]->%*;

        @pipe = splice @_, 3;
    }
    else {
        @pipe = splice @_, 2;
    }

    if ( $self->channel->{$name} ) {
        $ch = $self->channel->{$name};
    }
    else {
        $ch = Pcore::Core::Log::Channel->new($args);

        $self->channel->{$name} = $ch;

        P->scalar->weaken( $self->channel->{$name} ) if defined wantarray;
    }

    for (@pipe) {
        my $uri = P->uri($_);

        if ( my $pipe = P->class->load( $uri->scheme, ns => 'Pcore::Core::Log::Pipe' )->new( { uri => $uri } ) ) {
            if ( $PIPE->{ $pipe->id } ) {
                $pipe = $PIPE->{ $pipe->id };
            }
            else {
                $PIPE->{ $pipe->id } = $pipe;

                P->scalar->weaken( $PIPE->{ $pipe->id } );
            }

            $ch->add_pipe($pipe);
        }
    }

    # remove channel without pipes
    if ( !$ch->pipe->%* ) {
        delete $self->channel->{$name};

        return;
    }

    return $ch;
}

sub remove_pipe ( $self, $pipe_id ) {

    # remove pipe
    return if !delete $PIPE->{$pipe_id};

    for my $ch ( values $self->channel->%* ) {
        if ( delete $ch->pipe->{$pipe_id} ) {

            # remove channel without pipes
            delete $self->channel->{ $ch->name } if !$ch->pipe->%*;
        }
    }

    return;
}

sub canlog ( $self, $channel ) {
    return $self->{channel}->{$channel} ? 1 : 0;
}

sub sendlog ( $self, $channel, @ ) {
    if ( my $ch = $self->{channel}->{$channel} ) {
        $ch->sendlog( splice @_, 2 );
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::Log

=head1 SYNOPSIS

    P->log->add( $channel_name, $pipe_uri, ... );

    P->log->sendlog( $channel_name, $data, %tags ) if P->log->canlog($channel_name);

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
