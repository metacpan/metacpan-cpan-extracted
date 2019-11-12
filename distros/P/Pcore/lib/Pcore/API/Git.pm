package Pcore::API::Git;

use Pcore -class, -res, -const, -export;
use Pcore::Lib::Scalar qw[is_plain_arrayref];

has root => ( required => 1 );

has upstream => ( is => 'lazy', init_arg => undef );    # InstanceOf ['Pcore::API::Git::Upstream'] ]

our $EXPORT = {
    GIT_UPSTREAM_URL => [qw[$GIT_UPSTREAM_URL_LOCAL $GIT_UPSTREAM_URL_HTTPS $GIT_UPSTREAM_URL_SSH]],
    GIT_UPSTREAM     => [qw[$GIT_UPSTREAM_HOST $GIT_UPSTREAM_NAME $GIT_UPSTREAM_BITBUCKET $GIT_UPSTREAM_GITHUB $GIT_UPSTREAM_GITLAB]],
};

const our $GIT_UPSTREAM_URL_LOCAL => 1;
const our $GIT_UPSTREAM_URL_HTTPS => 2;
const our $GIT_UPSTREAM_URL_SSH   => 3;

const our $GIT_UPSTREAM_BITBUCKET => 'bitbucket';
const our $GIT_UPSTREAM_GITHUB    => 'github';
const our $GIT_UPSTREAM_GITLAB    => 'gitlab';

const our $GIT_UPSTREAM_HOST => {
    $GIT_UPSTREAM_BITBUCKET => 'bitbucket.org',
    $GIT_UPSTREAM_GITHUB    => 'github.com',
    $GIT_UPSTREAM_GITLAB    => 'gitlab.com',
};

const our $GIT_UPSTREAM_NAME => { map { $GIT_UPSTREAM_HOST->{$_} => $_ } keys $GIT_UPSTREAM_HOST->%* };

around new => sub ( $orig, $self, $path, $search = undef ) {
    $path = P->path($path)->to_abs;

    my $found;

    if ( -d "$path/.git" ) {
        $found = 1;
    }
    elsif ($search) {
        $path = $path->parent;

        while ($path) {
            if ( -d "$path/.git" ) {
                $found = 1;

                last;
            }

            $path = $path->parent;
        }
    }

    return $self->$orig( { root => $path } ) if $found;

    return;
};

sub _build_upstream ($self) {
    require Pcore::API::Git::Upstream;

    my $url = $self->git_run('ls-remote --get-url');

    chomp $url->{data};

    return Pcore::API::Git::Upstream->new( { url => $url->{data} } ) if $url && $url->{data};

    return;
}

sub git_run ( $self, $cmd, $cb = undef ) {
    state $run = sub ( $self, $cmd, $cb ) {
        my $proc = P->sys->run_proc(
            [ is_plain_arrayref $cmd ? ( 'git', $cmd->@* ) : 'git ' . $cmd ],
            chdir  => $self->{root},
            stdout => 1,
            stderr => 1,
        );

        if ($MSWIN) {
            $proc->wait->capture;
        }
        else {
            $proc->capture->wait;
        }

        my $res;

        if ( $proc->is_success ) {
            $res = res 200, $proc->{stdout} ? $proc->{stdout}->$* : undef;
        }
        else {
            $res = res [ 500, $proc->{stderr} ? $proc->{stderr}->$* : $EMPTY ];
        }

        return $cb ? $cb->($res) : $res;
    };

    if ( defined wantarray ) {
        return $run->( $self, $cmd, $cb );
    }
    else {
        Coro::async {
            $run->( $self, $cmd, $cb );

            return;
        };
    }

    return;
}

sub git_run_no_root ( $self, $cmd, $cb = undef ) {
    $self = bless {}, __PACKAGE__;

    return $self->git_run( $cmd, $cb );
}

sub git_id ( $self, $cb = undef ) {

    # get all tags - git tag --points-at HEAD
    # get current branch git branch --show-current
    # git rev-parse --short HEAD
    # git rev-parse HEAD
    # git branch --no-color --contains HEAD

    my $res1 = res 200,
      { branch           => undef,
        date             => undef,
        hash             => undef,
        hash_short       => undef,
        is_dirty         => undef,
        release          => undef,
        release_distance => undef,
        tags             => undef,
      };

    my $cv = P->cv->begin( sub ($cv) {
        $cv->( $cb ? $cb->($res1) : $res1 );

        return;
    } );

    $cv->begin;
    $self->git_run(
        'log -1 --pretty=format:%H%n%h%n%cI%n%D',
        sub ($res) {
            $cv->end;

            return if !$res1;

            if ( !$res ) {
                $res1 = $res;
            }
            else {
                ( my $data->@{qw[hash hash_short date]}, my $ref ) = split /\n/sm, $res->{data};

                my @ref = split /,/sm, $ref;

                # parse current branch
                if ( ( shift @ref ) =~ /->\s(.+)/sm ) {
                    $data->{branch} = $1;
                }

                # parse tags
                for my $token (@ref) {
                    if ( $token =~ /tag:\s(.+)/sm ) {
                        push $data->{tags}->@*, $1;
                    }
                }

                $res1->{data}->@{ keys $data->%* } = values $data->%*;
            }

            return;
        },
    );

    $cv->begin;
    $self->git_run(
        'describe --tags --always --match "v[0-9]*.[0-9]*.[0-9]*"',
        sub ($res) {
            $cv->end;

            return if !$res1;

            if ( !$res ) {
                $res1 = $res;
            }
            else {

                # remove trailing "\n"
                chomp $res->{data};

                my @data = split /-/sm, $res->{data};

                if ( $data[0] =~ /\Av\d+[.]\d+[.]\d+\z/sm ) {
                    $res1->{data}->{release} = $data[0];

                    $res1->{data}->{release_distance} = $data[1] || 0;
                }
            }

            return;
        },
    );

    $cv->begin;
    $self->git_run(
        'status --porcelain',
        sub ($res) {
            $cv->end;

            return if !$res1;

            if ( !$res ) {
                $res1 = $res;
            }
            else {
                $res1->{data}->{is_dirty} = 0+ !!$res->{data};
            }

            return;
        },
    );

    if ( defined wantarray ) {
        return $cv->end->recv;
    }
    else {
        return;
    }
}

sub git_get_releases ( $self, $cb = undef ) {
    return $self->git_run(
        'tag --merged master',
        sub ($res) {
            if ($res) {
                my @releases = sort { version->parse($a) <=> version->parse($b) } grep {/\Av\d+[.]\d+[.]\d+\z/sm} split /\n/sm, $res->{data};

                $res->{data} = \@releases if @releases;
            }

            return $cb ? $cb->($res) : $res;
        },
    );
}

sub git_get_log ( $self, $tag = undef, $cb = undef ) {
    my $cmd = 'log --pretty=format:%s';

    $cmd .= " $tag..HEAD" if $tag;

    return $self->git_run(
        $cmd,
        sub ($res) {
            if ($res) {
                my ( $data, $idx );

                for my $log ( split /\n/sm, $res->{data} ) {
                    if ( !exists $idx->{$log} ) {
                        $idx->{$log} = 1;

                        push $data->@*, $log;
                    }
                }

                $res->{data} = $data;
            }

            return $cb ? $cb->($res) : $res;
        },
    );
}

sub git_is_pushed ( $self, $cb = undef ) {
    return $self->git_run(
        'branch -v --no-color',
        sub ($res) {
            if ($res) {
                my $data;

                for my $br ( split /\n/sm, $res->{data} ) {
                    if ( $br =~ /\A[*]?\s+(.+?)\s+(?:.+?)\s+(?:\[ahead\s(\d+)\])?/sm ) {
                        $data->{$1} = $2 || 0;
                    }
                    else {
                        die qq[Can't parse branch: $br];
                    }

                    $res->{data} = $data;
                }
            }

            return $cb ? $cb->($res) : $res;
        },
    );
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::Git

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
