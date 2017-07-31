package Pcore::API::GitHub;

use Pcore -class, -result;
use Pcore::Util::Scalar qw[is_plain_coderef];

has username => ( is => 'ro', isa => Str, required => 1 );
has token    => ( is => 'ro', isa => Str, required => 1 );

sub BUILDARGS ( $self, $args = undef ) {
    $args->{username} ||= $ENV->user_cfg->{GITHUB}->{username} if $ENV->user_cfg->{GITHUB}->{username};

    $args->{token} ||= $ENV->user_cfg->{GITHUB}->{token} if $ENV->user_cfg->{GITHUB}->{token};

    return $args;
}

sub _req ( $self, $method, $endpoint, $data, $cb ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    P->http->$method(
        'https://api.github.com' . $endpoint,
        headers => {
            AUTHORIZATION => "token $self->{token}",
            CONTENT_TYPE  => 'application/json',
        },
        body => $data ? P->data->to_json($data) : undef,
        on_finish => sub ($res) {
            my $data = $res->body && $res->body->$* ? P->data->from_json( $res->body ) : undef;

            my $api_res;

            if ( !$res ) {
                $api_res = result [ $res->status, $data->{message} // $res->reason ];
            }
            else {
                $api_res = result $res->status, $data;
            }

            $cb->($api_res) if $cb;

            $blocking_cv->send($api_res) if $blocking_cv;

            return;
        }
    );

    return $blocking_cv ? $blocking_cv->recv : ();
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
## |    1 | 54                   | CodeLayout::RequireTrailingCommas - List declaration without trailing comma                                    |
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
