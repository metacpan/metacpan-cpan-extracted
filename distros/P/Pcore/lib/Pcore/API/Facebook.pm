package Pcore::API::Facebook;

use Pcore -const, -class, -res;
use Pcore::Lib::Data qw[to_uri];
use Pcore::Lib::Scalar qw[is_plain_arrayref weaken];

with qw[Pcore::API::Facebook::User Pcore::API::Facebook::Marketing];

has token       => ( required => 1 );
has max_threads => 1;

has _threads => ( 0, init_arg => undef );
has _signal => ( sub { Coro::Signal->new }, init_arg => undef );
has _queue => ( init_arg => undef );

const our $DEFAULT_LIMIT => 500;

const our $REQ_METHOD => 0;
const our $REQ_URL    => 1;
const our $REQ_DATA   => 2;
const our $REQ_LIMIT  => 3;
const our $REQ_CB     => 4;

sub DESTROY ($self) {
    if ( ${^GLOBAL_PHASE} ne 'DESTRUCT' ) {

        # finish threads
        $self->{_signal}->broadcast;

        # finish pending requests
        while ( my $req = shift $self->{_queue}->@* ) {
            $req->[$REQ_CB]->( res 500 );
        }
    }

    return;
}

sub _req ( $self, $method, $path, $params, $data, $cb = undef ) {
    my $cv = P->cv;

    my $on_finish = sub ($res) { $cv->( $cb ? $cb->($res) : $res ) };

    my $url = "https://graph.facebook.com/$path?access_token=$self->{token}";

    my $limit = $params ? delete $params->{limit} : undef;

    if ($limit) {
        $url .= "&limit=$limit";
    }
    else {
        $url .= "&limit=$DEFAULT_LIMIT";
    }

    if ($params) {
        $params->{fields} = join ',', $params->{fields}->@* if is_plain_arrayref $params->{fields};

        $url .= '&' . to_uri $params;
    }

    push $self->{_queue}->@*, [ $method, $url, $data, $limit, $on_finish ];

    if ( $self->{_signal}->awaited ) {
        $self->{_signal}->send;
    }
    elsif ( $self->{_threads} < $self->{max_threads} ) {
        $self->_run_thread;
    }

    return defined wantarray ? $cv->recv : ();
}

sub _run_thread ($self) {
    weaken $self;

    $self->{_threads}++;

    Coro::async {
        while () {
            return if !defined $self;

            if ( my $req = shift $self->{_queue}->@* ) {
                my $data;

              GET_NEXT_PAGE:
                my $res = P->http->request(
                    method => $req->[$REQ_METHOD],
                    url    => $req->[$REQ_URL],
                    data   => $req->[$REQ_DATA],
                );

                if ($res) {
                    if ( $res->{data} ) {
                        my $res_data = P->data->from_json( $res->{data} );

                        if ( $res_data->{paging} || is_plain_arrayref $res_data->{data} ) {
                            push $data->@*, $res_data->{data}->@*;

                            # get all records
                            if ( !$req->[$REQ_LIMIT] && ( $req->[$REQ_URL] = $res_data->{paging}->{next} ) ) {
                                goto GET_NEXT_PAGE;
                            }
                        }
                        else {
                            $data = $res_data;
                        }
                    }

                    $req->[$REQ_CB]->( res 200, $data );
                }

                # request error
                else {
                    if ( $res->{data} ) {
                        my $res_data = P->data->from_json( $res->{data} );

                        $req->[$REQ_CB]->( res [ $res->{status}, $res_data->{error}->{message} ] );
                    }
                    else {
                        $req->[$REQ_CB]->( res $res);
                    }
                }

                next;
            }

            $self->{_signal}->wait;
        }

        return;
    };

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 39                   | Subroutines::ProhibitManyArgs - Too many arguments                                                             |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 39                   | Subroutines::ProhibitUnusedPrivateSubroutines - Private subroutine/method '_req' declared but not used         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 100                  | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Facebook

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
