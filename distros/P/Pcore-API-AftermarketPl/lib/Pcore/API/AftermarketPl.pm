package Pcore::API::AftermarketPl v0.4.1;

use Pcore -dist, -class, -result;

has email       => ( is => 'ro', isa => Str,         required => 1 );
has password    => ( is => 'ro', isa => Str,         required => 1 );
has max_threads => ( is => 'ro', isa => PositiveInt, default  => 1 );

has _threads => ( is => 'ro', isa => PositiveOrZeroInt, default => 0, init_arg => undef );
has _request_queue => ( is => 'ro', isa => ArrayRef, default => sub { [] }, init_arg => undef );

sub check ( $self, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->domain_check(
        ['google.pl'],
        sub ($res) {
            if ($blocking_cv) {
                $blocking_cv->send($res);
            }
            else {
                $cb->($res) if $cb;
            }

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

# NOTE only .pl domains are supported
sub domain_check ( $self, $domains, @ ) {
    my $cb = $_[-1];

    my %args = (
        cv      => undef,
        retries => 3,
        splice @_, 2, -1,
    );

    $args{cv}->begin if $args{cv};

    my $index = {};

    # index domains
    for my $domain ( $domains->@* ) {
        push $index->{ P->host($domain)->canon }->@*, $domain;
    }

    $self->_request(
        'domain/check',
        {   domains => join( q[,], keys $index->%* ),
            taste   => 0,
        },
        $args{retries},
        sub ($res) {
            if ( !$res ) {
                $cb->($res);
            }
            else {
                my $result->@{ $domains->@* } = ();

                for my $domain ( $res->{data}->{data}->@* ) {
                    $result->@{ $index->{ $domain->{name} }->@* } = ($domain) x $index->{ $domain->{name} }->@*;
                }

                $res->{data} = $result;

                $cb->($res);
            }

            $args{cv}->end if $args{cv};

            return;
        }
    );

    return;
}

sub _request ( $self, $func, $data, $retries, $cb ) {

    # max. threads reached
    if ( $self->{_threads} >= $self->max_threads ) {
        push $self->{_request_queue}->@*, [ splice @_, 1 ];

        return;
    }

    $self->{_threads}++;

    P->http->post(
        'https://json.aftermarket.pl/' . $func,
        headers => { CONTENT_TYPE => 'application/x-www-form-urlencoded' },
        body    => P->data->to_uri(
            {   email    => $self->email,
                password => $self->password,
                $data->%*,
            }
        ),
        on_finish => sub ($res) {
            if ( $res->status != 200 ) {
                P->log->sendlog( 'Pcore-API-AftermarketPl', join q[ - ], $func, $res->status, $res->reason ) if P->log->canlog('Pcore-API-AftermarketPl');

                if ( --$retries ) {
                    $self->{_threads}--;

                    $self->_request( $func, $data, $retries, $cb );

                    return;
                }
                else {
                    $cb->( result [ $res->status, $res->reason ] );
                }
            }
            else {
                my $data = P->data->from_json( $res->body );

                if ( !$data->{ok} ) {
                    P->log->sendlog( 'Pcore-API-AftermarketPl', join q[ - ], $func, $data->{status}, $data->{error} ) if P->log->canlog('Pcore-API-AftermarketPl');

                    $cb->( result [ 550, $data->{error} ] );
                }
                else {
                    P->log->sendlog( 'Pcore-API-AftermarketPl', join q[ - ], $func, $res->status, $res->reason ) if P->log->canlog('Pcore-API-AftermarketPl');

                    $cb->( result 200, $data );
                }
            }

            $self->{_threads}--;

            # run next request
            while (1) {
                last if $self->{_threads} >= $self->max_threads;

                my $req = shift $self->{_request_queue}->@*;

                last if !$req;

                $self->_request( $req->@* );
            }

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

Pcore::API::AftermarketPl

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

zdm <zdm@softvisio.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by zdm.

=cut
