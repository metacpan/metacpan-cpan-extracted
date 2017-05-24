package Pcore::API::Google::Search;

use Pcore -class, -const;
use Pcore::API::Google;
use Pcore::HTTP qw[http_get];

has max_threads => ( is => 'ro', isa => PositiveInt, default => 1 );
has anticaptcha_key => ( is => 'ro', isa => Str );
has cookies => ( is => 'ro', isa => HashRef, default => sub { {} } );

has _anticaptcha => ( is => 'lazy', isa => Maybe [ InstanceOf ['Pcore::API::AntiCaptcha'] ], init_arg => undef );
has _threads => ( is => 'ro', isa => PositiveOrZeroInt, default => 0, init_arg => undef );
has _req_pool => ( is => 'ro', isa => ArrayRef, default => sub { [] }, init_arg => undef );
has _captcha_in_progress => ( is => 'ro', isa => Bool, default => 0, init_arg => undef );

const our $HTTP_USERAGENT => 'Links (2.1; Linux 2.6.18-gentoo-r6 x86_64; 80x24)';
const our $HTTP_TIMEOUT   => 15;

sub _build__anticaptcha ($self) {
    if ( $self->anticaptcha_key ) {
        require Pcore::API::AntiCaptcha;

        return Pcore::API::AntiCaptcha->new( { api_key => $self->anticaptcha_key } );
    }

    return;
}

sub search ( $self, $query, $cb ) {
    my $url = 'https://www.google.com/search?gws_rd=cr&num=100&q=' . P->data->to_uri($query);

    $self->_request(
        $url,
        sub ($res) {
            $cb->($res);

            return;
        }
    );

    return;
}

sub _request ( $self, $url, $cb ) {
    if ( $self->{_threads} >= $self->max_threads ) {
        push $self->{_req_pool}->@*, [ $url, $cb ];

        return;
    }

    $self->{_threads}++;

    my $on_finish = sub ($res) {
        $self->{_threads}--;

        $cb->($res);

        while (1) {
            last if $self->{_threads} >= $self->max_threads;

            if ( my $next_req = shift $self->{_req_pool}->@* ) {
                $self->_request( $next_req->@* );
            }
            else {
                last;
            }
        }

        return;
    };

    P->log->sendlog( 'Pcore-API-Google-Search', 'start request' );

    http_get(
        $url,
        timeout   => $HTTP_TIMEOUT,
        useragent => $HTTP_USERAGENT,
        cookies   => $self->{cookies},
        on_finish => sub ($res) {
            if ( $res->status == 503 ) {    # captcha
                if ( !$self->_anticaptcha ) {
                    $on_finish->($res);
                }
                else {

                    # store request in the pool if captcha is solved now
                    if ( $self->{_captcha_in_progress} ) {
                        P->log->sendlog( 'Pcore-API-Google-Search', 'waiting until captcha resolved' );

                        $self->{_threads}--;

                        unshift $self->{_req_pool}->@*, [ $url, $cb ];
                    }
                    else {
                        $self->{_captcha_in_progress} = 1;

                        $self->_resolve_captcha(
                            $url, $res,
                            sub ($res) {
                                $self->{_captcha_in_progress} = 0;

                                $on_finish->($res);

                                return;
                            }
                        );
                    }
                }
            }
            elsif ( $res->status == 403 ) {    # IP banned
                P->log->sendlog( 'Pcore-API-Google-Search', 'IP addr. banned' );

                $on_finish->($res);
            }
            else {
                $on_finish->($res);
            }

            return;
        }
    );

    return;
}

sub _resolve_captcha ( $self, $url, $res, $cb ) {
    P->log->sendlog( 'Pcore-API-Google-Search', 'resolving captcha' );

    my $base_url = $res->url;

    my ($id) = $res->body->$* =~ m[name="id" value="(\d+)"]sm;

    my ($image_url) = $res->body->$* =~ m[<img src="(/sorry/image.+?)"]sm;

    $image_url =~ s/&amp;/&/smg;

    $image_url = P->uri( $image_url, base => $base_url );

    my $q = P->data->from_uri_query( $image_url->query )->{'q'};

    # get captcha image
    http_get(
        $image_url,
        timeout   => $HTTP_TIMEOUT,
        useragent => $HTTP_USERAGENT,
        cookies   => $self->{cookies},
        on_finish => sub ($img_res) {

            # resolve captcha
          RESOLVE_CAPTCHA:
            $self->_anticaptcha->resolve(
                image => $img_res->body,
                sub ($captcha) {
                    if ( !$captcha ) {
                        $self->_resolve_captcha( $url, $res, $cb );

                        return;
                    }

                    # enter captcha
                    my $query = P->data->to_uri(
                        {   continue => $url,
                            id       => $id,
                            q        => $q,
                            submit   => 'Submit',
                            captcha  => $captcha->{result}
                        }
                    );

                    http_get(
                        P->uri( '/sorry/CaptchaRedirect?' . $query, base => $base_url ),
                        timeout   => $HTTP_TIMEOUT,
                        useragent => $HTTP_USERAGENT,
                        cookies   => $self->{cookies},
                        on_finish => sub ($res) {

                            # captcha recognized incorrectly
                            if ( $res->status == 503 ) {
                                P->log->sendlog( 'Pcore-API-Google-Search', 'captcha resolving error' );

                                # TODO report failure to AntiCaptcha

                                $self->_resolve_captcha( $url, $res, $cb );
                            }

                            # captcha is valid
                            else {
                                P->log->sendlog( 'Pcore-API-Google-Search', 'captcha OK' );

                                $cb->($res);
                            }

                            return;
                        }
                    );

                    return;
                }
            );

            return;
        },
    );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Google::Search

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
