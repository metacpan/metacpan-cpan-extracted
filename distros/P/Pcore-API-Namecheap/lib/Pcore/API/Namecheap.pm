package Pcore::API::Namecheap v0.5.2;

use Pcore -dist, -class, -result;

has api_user => ( is => 'ro', isa => Str, required => 1 );
has api_key  => ( is => 'ro', isa => Str, required => 1 );
has api_ip   => ( is => 'ro', isa => Str, required => 1 );

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
        ApiUser  => $self->api_user,
        ApiKey   => $self->api_key,
        ClientIp => $self->api_ip,
        UserName => $self->api_user,
        Command  => 'namecheap.domains.check',
    ];

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

    push $url_params->@*, DomainList => join q[,], keys $query_index->%*;

    my $url = 'https://api.namecheap.com/xml.response?' . P->data->to_uri($url_params);

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
                my $hash = P->data->from_xml( $res->body );

                if ( $hash->{ApiResponse}->{Errors}->[0]->{Error} ) {
                    for my $error ( $hash->{ApiResponse}->{Errors}->[0]->{Error}->@* ) {

                        # provider for tld was not found
                        if ( $error->{Number}->[0]->{content} != 2_030_280 ) {
                            $api_res = result [ $error->{Number}->[0]->{content}, $error->{content} ];

                            last;
                        }
                    }
                }

                if ( !defined $api_res ) {
                    for my $domain ( $hash->{ApiResponse}->{CommandResponse}->[0]->{DomainCheckResult}->@* ) {
                        my $domain_name = $domain->{Domain}->[0]->{content};

                        next if !exists $query_index->{$domain_name};

                        if ( $domain->{Available}->[0]->{content} eq 'true' ) {
                            $domains_index->@{ $query_index->{$domain_name}->@* } = (1) x $query_index->{$domain_name}->@*;
                        }
                        else {
                            $domains_index->@{ $query_index->{$domain_name}->@* } = (0) x $query_index->{$domain_name}->@*;
                        }
                    }

                    $api_res = result 200, $domains_index;
                }
            }

            $cb->($api_res);

            $self->{_threads}--;

            $self->search;

            return;
        },
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
## |    3 | 35                   | Subroutines::ProhibitExcessComplexity - Subroutine "search" with high complexity score (24)                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Namecheap

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
