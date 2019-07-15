package Pcore::API::Cloudflare;

use Pcore -const, -class, -res;
use Pcore::Lib::Scalar qw[weaken];

has email => ( required => 1 );
has key   => ( required => 1 );

has max_threads => 10;

has _headers => ( init_arg => undef );
has _queue   => ( init_arg => undef );
has _threads => 0, init_arg => undef;
has _signal => sub { Coro::Signal->new }, init_arg => undef;

const our $API_VER => 4;

const our $TASK_METHOD => 0;
const our $TASK_PATH   => 1;
const our $TASK_QUERY  => 2;
const our $TASK_DATA   => 3;
const our $TASK_CB     => 4;

sub DESTROY ($self) {
    if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) {

        # finish tasks
        while ( my $task = shift $self->{_queue}->@* ) {
            $task->[$TASK_CB]->( res 500 ) if $task->[$TASK_CB];
        }

        # finish threads
        $self->{_signal}->broadcast;
    }

    return;
}

sub _req ( $self, $args ) {
    my $cv;

    if ( defined wantarray ) {
        $cv = P->cv;

        my $cb = delete $args->[$TASK_CB];

        $args->[$TASK_CB] = sub ($res) { $cv->( $cb ? $cb->($res) : $res ) };
    }

    push $self->{_queue}->@*, $args;

    if ( $self->{_signal}->awaited ) {
        $self->{_signal}->send;
    }
    elsif ( $self->{_threads} < $self->{max_threads} ) {
        $self->_run_thread;
    }

    return $cv ? $cv->recv : ();
}

sub _run_thread ($self) {
    weaken $self;

    $self->{_threads}++;

    my $coro = Coro::async_pool {
        while () {
            last if !defined $self;

            if ( my $task = shift $self->{_queue}->@* ) {
                my $url = qq[https://api.cloudflare.com/client/v$API_VER/$task->[$TASK_PATH]];

                $url .= '?' . P->data->to_uri( $task->[$TASK_QUERY] ) if defined $task->[$TASK_QUERY];

                my $res = P->http->request(
                    method  => $task->[$TASK_METHOD],
                    url     => $url,
                    headers => $self->{_headers} //= [
                        'X-Auth-Email' => $self->{email},
                        'X-Auth-Key'   => $self->{key},
                        'Content-Type' => 'application/json',
                    ],
                    data => defined $task->[$TASK_DATA] ? P->data->to_json( $task->[$TASK_DATA] ) : undef,
                );

                if ( $task->[$TASK_CB] ) {
                    my $api_res;

                    if ($res) {
                        $api_res = res $res, P->data->from_json( $res->{data} );
                    }
                    else {
                        $api_res = res $res;

                        $api_res->{data} = P->data->from_json( $res->{data} ) if $res->{data};
                    }

                    $task->[$TASK_CB]->($api_res);
                }

                next;
            }

            $self->{_signal}->wait;
        }

        $self->{_threads}--;

        return;
    };

    $coro->cede_to;

    return;
}

# https://api.cloudflare.com/#zone-list-zones
sub zones ( $self, $cb = undef ) {
    return $self->_req( [
        'GET', '/zones', undef, undef,
        sub ($res) {
            $res->{data} = { map { $_->{name} => $_ } $res->{data}->{result}->@* } if $res;

            return $cb ? $cb->($res) : $res;
        }
    ] );
}

# https://api.cloudflare.com/#zone-create-zone
sub zone_create ( $self, $domain, $account_id, $cb = undef ) {
    return $self->_req( [
        'POST', '/zones', undef,
        {   name       => $domain,
            account    => { id => $account_id, },
            jump_start => \1,
            type       => 'full',
        },
        $cb
    ] );
}

# https://api.cloudflare.com/#zone-delete-zone
sub zone_remove ( $self, $id, $cb = undef ) {
    return $self->_do_req( [ 'DELETE', "/zones/$id", undef, undef, $cb ] );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Cloudflare

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
