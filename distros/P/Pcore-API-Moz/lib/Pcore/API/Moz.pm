package Pcore::API::Moz v0.9.3;

use Pcore -dist, -class, -result;
use Pcore::API::Moz::Account;

has api_expires => ( is => 'ro', isa => PositiveInt, default => 172_800 );    # in seconds, 2 days
has proxy_pool => ( is => 'ro', isa => Maybe [ InstanceOf ['Pcore::API::ProxyPool'] ] );

has has_valid_accounts => ( is => 'ro', isa => PositiveOrZeroInt, default => 0, init_arg => undef );
has valid_accounts   => ( is => 'ro', isa => ArrayRef, init_arg => undef );
has invalid_accounts => ( is => 'ro', isa => ArrayRef, init_arg => undef );

has _accs_ids => ( is => 'ro', isa => HashRef, init_arg => undef );

# free API limitations:
# https://moz.com/help/guides/moz-api/mozscape/overview/free-vs-paid-access
# - regular members: 1 call per 10 seconds;
# - 10 URLs per batch;

sub BUILD ( $self, $args ) {
    $self->add_accounts( $args->{accounts} ) if $args->{accounts};

    return;
}

sub add_accounts ( $self, $accounts ) {
    for my $id ( keys $accounts->%* ) {
        my $acc_id = "$id-$accounts->{$id}";

        next if exists $self->{_accs_ids}->{$acc_id};

        $self->{_accs_ids}->{$acc_id} = undef;

        unshift $self->{valid_accounts}->@*, Pcore::API::Moz::Account->new( { moz => $self, id => $id, key => $accounts->{$id} } );

        $self->{has_valid_accounts}++;
    }

    return;
}

sub is_ready ($self) {
    if ( !$self->{valid_accounts}->@* || !$self->{valid_accounts}->[0]->is_ready ) {
        return 0;
    }

    return 1;
}

sub get_url_metrics ( $self, $domains, $metric, $cb ) {
    if ( $domains->@* > 10 ) {
        $cb->( result [ 400, q[Max. 10 domains are allowed per search request] ] );

        return;
    }

    if ( !$self->{has_valid_accounts} ) {
        $cb->( result [ 600, q[No moz accounts] ] );

        return;
    }

    if ( !$self->{valid_accounts}->@* || !$self->{valid_accounts}->[0]->is_ready ) {
        $cb->( result [ 601, q[API is busy] ] );

        return;
    }

    my $acc = shift $self->{valid_accounts}->@*;

    $acc->get_url_metrics(
        $domains, $metric,
        sub($res) {
            if ( !$res ) {

                # account is banned:
                # 401 - invalid credentials
                # 403 - account banned
                # 429 - too many requests
                if ( $res->status == 401 || $res->status == 403 || $res->status == 429 ) {
                    $self->{has_valid_accounts}--;

                    push $self->{invalid_accounts}->@*, $acc;
                }

                # not fatal error
                else {
                    push $self->{valid_accounts}->@*, $acc;
                }
            }

            # ok
            else {
                push $self->{valid_accounts}->@*, $acc;
            }

            $cb->($res);

            return;
        }
    );

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Moz

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
