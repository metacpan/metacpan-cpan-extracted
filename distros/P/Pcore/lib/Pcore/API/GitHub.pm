package Pcore::API::GitHub;

use Pcore -class, -res;
use Pcore::Util::Scalar qw[is_plain_coderef];

has username => ( required => 1 );
has token    => ( required => 1 );

sub BUILDARGS ( $self, $args = undef ) {
    $args->{username} ||= $ENV->user_cfg->{GITHUB}->{username} if $ENV->user_cfg->{GITHUB}->{username};

    $args->{token} ||= $ENV->user_cfg->{GITHUB}->{token} if $ENV->user_cfg->{GITHUB}->{token};

    return $args;
}

sub _req ( $self, $method, $endpoint, $data, $cb = undef ) {
    return P->http->$method(
        'https://api.github.com' . $endpoint,
        headers => [
            Authorization  => "token $self->{token}",
            'Content-Type' => 'application/json',
        ],
        data => $data ? P->data->to_json($data) : undef,
        sub ($res) {
            my $data = $res->{data} && $res->{data}->$* ? P->data->from_json( $res->{data} ) : undef;

            my $api_res;

            if ( !$res ) {
                $api_res = res [ $res->{status}, $data->{message} // $res->{reason} ];
            }
            else {
                $api_res = res $res->{status}, $data;
            }

            return $cb ? $cb->($api_res) : $api_res;
        }
    );
}

# https://developer.github.com/v3/repos/#create
sub create_repo ( $self, $repo_id, @args ) {
    my $cb = is_plain_coderef $args[-1] ? pop @args : undef;

    my %args = (

        # common attrs
        description => undef,
        has_issues  => 1,
        has_wiki    => 1,
        is_private  => 0,

        # github attrs
        homepage      => undef,
        has_downloads => 1,
        @args
    );

    $args{private}       = delete $args{is_private} ? \1 : \0;
    $args{has_issues}    = $args{has_issues}        ? \1 : \0;
    $args{has_wiki}      = $args{has_wiki}          ? \1 : \0;
    $args{has_downloads} = $args{has_downloads}     ? \1 : \0;

    ( my $repo_namespace, $args{name} ) = split m[/]sm, $repo_id;

    my $endpoint;

    if ( $repo_namespace eq $self->{username} ) {
        $endpoint = '/user/repos';
    }
    else {
        $endpoint = "/orgs/$repo_namespace/repos";
    }

    return $self->_req( 'post', $endpoint, \%args, $cb );
}

# https://developer.github.com/v3/repos/#delete-a-repository
sub delete_repo ( $self, $repo_id, $cb = undef ) {
    return $self->_req( 'delete', "/repos/$repo_id", undef, $cb );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    1 | 46                   | CodeLayout::RequireTrailingCommas - List declaration without trailing comma                                    |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::GitHub

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
