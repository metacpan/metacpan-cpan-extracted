package Pcore::API::GitHub;

use Pcore -class, -result;

has api_username => ( is => 'ro', isa => Str, required => 1 );
has api_token    => ( is => 'ro', isa => Str, required => 1 );
has repo_name    => ( is => 'ro', isa => Str, required => 1 );
has namespace => ( is => 'lazy', isa => Str );

has id => ( is => 'lazy', isa => Str, init_arg => undef );

has clone_uri_https            => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_https_hggit      => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_ssh              => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_ssh_hggit        => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_wiki_https       => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_wiki_https_hggit => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_wiki_ssh         => ( is => 'lazy', isa => Str, init_arg => undef );
has clone_uri_wiki_ssh_hggit   => ( is => 'lazy', isa => Str, init_arg => undef );

has cpan_meta => ( is => 'lazy', isa => HashRef, init_arg => undef );

sub BUILDARGS ( $self, $args = undef ) {
    $args->{api_username} ||= $ENV->user_cfg->{GITHUB}->{username} if $ENV->user_cfg->{GITHUB}->{username};

    $args->{api_token} ||= $ENV->user_cfg->{GITHUB}->{token} if $ENV->user_cfg->{GITHUB}->{token};

    $args->{namespace} ||= $ENV->user_cfg->{GITHUB}->{namespace} if $ENV->user_cfg->{GITHUB}->{namespace};

    return $args;
}

sub _build_namespace ($self) {
    return $self->api_username;
}

sub _build_id ($self) {
    return $self->namespace . q[/] . $self->repo_name;
}

# CLONE URL BUILDERS
sub _build_clone_uri_https ($self) {
    return "https://github.com/@{[$self->id]}.git";
}

sub _build_clone_uri_https_hggit ($self) {
    return 'git+' . $self->clone_uri_https;
}

sub _build_clone_uri_ssh ($self) {
    return "ssh://git\@github.com/@{[$self->id]}.git";
}

sub _build_clone_uri_ssh_hggit ($self) {
    return 'git+' . $self->clone_uri_ssh;
}

sub _build_clone_uri_wiki_https ($self) {
    return "https://github.com/@{[$self->id]}.wiki.git";
}

sub _build_clone_uri_wiki_https_hggit ($self) {
    return 'git+' . $self->clone_uri_wiki_https;
}

sub _build_clone_uri_wiki_ssh ($self) {
    return "ssh://git\@github.com/@{[$self->id]}.wiki.git";
}

sub _build_clone_uri_wiki_ssh_hggit ($self) {
    return 'git+' . $self->clone_uri_wiki_ssh;
}

# CPAN META
sub _build_cpan_meta ($self) {
    return {
        homepage   => "https://github.com/@{[$self->id]}",
        bugtracker => {                                      #
            web => "https://github.com/@{[$self->id]}/issues?q=is%3Aopen+is%3Aissue",
        },
        repository => {
            type => 'git',
            url  => $self->clone_uri_https,
            web  => "https://github.com/@{[$self->id]}",
        },
    };
}

sub create_repo ( $self, @ ) {
    my $blocking_cv = defined wantarray ? AE::cv : undef;

    my %args = (
        cb            => undef,
        name          => $self->repo_name,
        description   => undef,
        homepage      => undef,
        private       => $FALSE,
        has_issues    => $TRUE,
        has_wiki      => $TRUE,
        has_downloads => $TRUE,
        splice @_, 1
    );

    my $cb = delete $args{cb};

    my $url = "https://api.github.com/user/repos";

    P->http->post(    #
        $url,
        headers => {
            AUTHORIZATION => 'token ' . $self->api_token,
            CONTENT_TYPE  => 'application/json',
        },
        body      => P->data->to_json( \%args ),
        on_finish => sub ($res) {
            my $api_res;

            if ( $res->status != 200 ) {
                $api_res = result [ $res->status, $res->reason ];
            }
            else {
                my $json = P->data->from_json( $res->body );

                if ( $json->{error} ) {
                    $api_res = result [ 200, $json->{message} ];
                }
                else {
                    $api_res = result 200;
                }
            }

            $cb->($api_res) if $cb;

            $blocking_cv->send($api_res) if $blocking_cv;

            return;
        },
    );

    return $blocking_cv ? $blocking_cv->recv : ();
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 106                  | ValuesAndExpressions::ProhibitInterpolationOfLiterals - Useless interpolation of literal string                |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 92                   | CodeLayout::RequireTrailingCommas - List declaration without trailing comma                                    |
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
