package Pcore::API::Dynadot v0.5.1;

use Pcore -dist, -class, -result;

has api_key => ( is => 'ro', isa => Str, required => 1 );
has bind_ip => ( is => 'ro', isa => Maybe [Str] );

has _threads => ( is => 'ro', isa => PositiveOrZeroInt, default => 0, init_arg => undef );
has _pool => ( is => 'ro', isa => ArrayRef, default => sub { [] }, init_arg => undef );

sub check ( $self, $cb = undef ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    $self->search(
        [ 'google.com', 'yahoo.com' ],
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

# NOTE max 100 domains are allowed, 30 is recommneded
sub search ( $self, $domains = undef, $cb = undef ) {
    if ($domains) {
        die q[Max. 100 domains are allowed per search] if $domains->@* > 100;

        die q[Callback is required] if !$cb;

        push $self->{_pool}->@*, [ $domains, $cb ];
    }

    return if $self->{_threads} > 0;

    my $args = shift $self->{_pool}->@*;

    return if !$args;

    ( $domains, $cb ) = $args->@*;

    $self->{_threads}++;

    my $url_params = [
        key     => $self->api_key,
        command => 'search',
    ];

    my $i = 0;

    my $domains_index = {};

    my $query_index;

    for my $domain ( map { P->host($_) } $domains->@* ) {
        my $domain_name = $domain->name;

        next if exists $domains_index->{$domain_name};

        $domains_index->{$domain_name} = undef;

        if ( my $root_domain = $domain->root_domain ) {
            my $dots = $root_domain =~ tr/././;

            if ( !$dots ) {

                # domain is TLD, is not available by default
                $domains_index->{$domain_name} = 0;
            }
            elsif ( $dots > 2 ) {

                # root domain contains > 3 labels, not available
                $domains_index->{$domain_name} = 0;
            }
            else {

                # root domain contains 2 (domain.TLD) or 3 (domain.pub_suffix.TLD) labels, can be checked
                push $query_index->{$root_domain}->@*, $domain_name;

                next if $query_index->{$root_domain}->@* > 1;

                push $url_params->@*, 'domain' . $i++, $root_domain;
            }
        }

        # no root domain, domain is pub. suffix, is not available by default
        else {
            $domains_index->{$domain_name} = 0;
        }
    }

    # nothing to search
    if ( !$query_index ) {
        $cb->( result 200, $domains_index );

        $self->{_threads}--;

        $self->search;

        return;
    }

    my $url = 'https://api.dynadot.com/api2.html?' . P->data->to_uri($url_params);

    P->http->get(
        $url,
        persistent => 0,
        timeout    => 180,
        recurse    => 0,
        bind_ip    => $self->bind_ip,
        on_finish  => sub ($res) {
            my $api_res;

            if ( $res->status != 200 ) {
                $api_res = result [ $res->status, $res->reason ];
            }
            else {

                # parse response
                my @lines = split /\x0A/sm, $res->body->$*;

                my ( $status, $error ) = split /,/sm, shift @lines;

                if ( $status ne 'ok' ) {
                    chomp $error;

                    $api_res = result [ 999, $error ];
                }
                else {
                    shift @lines;

                    for my $line (@lines) {
                        chomp $line;

                        my @fields = split /,/sm, $line;

                        if ( $fields[3] eq 'yes' ) {
                            $domains_index->@{ $query_index->{ $fields[1] }->@* } = (1) x $query_index->{ $fields[1] }->@*;
                        }
                        elsif ( $fields[3] eq 'no' ) {
                            $domains_index->@{ $query_index->{ $fields[1] }->@* } = (0) x $query_index->{ $fields[1] }->@*;
                        }
                    }

                    $api_res = result 200, $domains_index;
                }
            }

            $cb->($api_res);

            $self->{_threads}--;

            $self->search;

            return;
        }
    );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 32                   | Subroutines::ProhibitExcessComplexity - Subroutine "search" with high complexity score (22)                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Dynadot

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
