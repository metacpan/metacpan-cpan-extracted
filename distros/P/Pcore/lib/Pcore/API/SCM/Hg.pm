package Pcore::API::SCM::Hg;

use Pcore -class, -res;
use Pcore::API::SCM::Const qw[:SCM_TYPE];
use Pcore::Util::Text qw[decode_utf8];
use Pcore::Util::Scalar qw[weaken is_plain_arrayref];

with qw[Pcore::API::SCM];

has capabilities => ( is => 'ro', isa => Str, init_arg => undef );
has _server_proc => ( is => 'ro', isa => InstanceOf ['Pcore::Util::Sys::Proc'], init_arg => undef );

our $SERVER_PROC;

sub _build_upstream ($self) {
    if ( -f "$self->{root}/.hg/hgrc" ) {
        my $hgrc = P->file->read_text("$self->{root}/.hg/hgrc");

        return Pcore::API::SCM::Upstream->new( { uri => $1, local_scm_type => $SCM_TYPE_HG } ) if $hgrc->$* =~ /default\s*=\s*(.+?)$/sm;
    }

    return;
}

# https://www.mercurial-scm.org/wiki/CommandServer
sub _server ( $self, $cb ) {
    if ( exists $self->{_server_proc} ) {
        $cb->( $self->{_server_proc} );

        return;
    }
    elsif ($SERVER_PROC) {
        $self->{_server_proc} = $SERVER_PROC;

        $cb->( $self->{_server_proc} );

        return;
    }
    else {
        local $ENV{HGENCODING} = 'UTF-8';

        P->sys->run_proc(
            [qw[hg serve --config ui.interactive=True --cmdserver pipe]],
            stdin    => 1,
            stdout   => 1,
            stderr   => 1,
            on_ready => sub ($proc) {
                $self->{_server_proc} = $proc;

                $SERVER_PROC = $proc;

                weaken $SERVER_PROC;

                # read capabilities
                $self->{capabilities} = $self->_read(
                    sub ( $channel, $data ) {
                        $self->{capabilities} = $data;

                        $cb->( $self->{_server_proc} );

                        return;
                    }
                );

                return;
            }
        );

        return;
    }
}

sub _read ( $self, $cb ) {
    $self->_server( sub($hg) {
        $hg->stdout->push_read(
            chunk => 5,
            sub ( $h, $data ) {
                my $channel = substr $data, 0, 1, q[];

                $h->push_read(
                    chunk => unpack( 'L>', $data ),
                    sub ( $h, $data ) {
                        $cb->( $channel, $data );

                        return;
                    }
                );

                return;
            }
        );

        return;
    } );

    return;
}

# NOTE status + pattern (status *.txt) not works under linux - http://bz.selenic.com/show_bug.cgi?id=4526
sub _scm_cmd ( $self, $cmd, $root = undef, $cb = undef ) {
    my $rouse_cb = defined wantarray ? Coro::rouse_cb : ();

    my $buf = join "\x00", $cmd->@*;

    $buf .= "\x00--repository\x00$root" if $root;

    $buf = Encode::encode( $Pcore::WIN_ENC, $buf, Encode::FB_CROAK );

    $self->_server( sub ($hg) {
        $hg->stdin->push_write( qq[runcommand\x0A] . pack( 'L>', length $buf ) . $buf );

        my $res = {};

        my $read = sub ( $channel, $data ) {
            if ( $channel ne 'r' ) {
                chomp $data;

                decode_utf8( $data, encoding => $Pcore::WIN_ENC );

                push $res->{$channel}->@*, $data;

                $self->_read(__SUB__);
            }

            # "r" channel - request is finished
            else {
                my $result;

                if ( exists $res->{e} ) {
                    $result = res [ 500, join q[ ], $res->{e}->@* ];
                }
                else {
                    $result = res 200, $res->{o};
                }

                $rouse_cb ? $cb ? $rouse_cb->( $cb->($result) ) : $rouse_cb->($result) : $cb ? $cb->($result) : ();
            }

            return;
        };

        $self->_read($read);

        return;
    } );

    return $rouse_cb ? Coro::rouse_wait $rouse_cb : ();
}

sub scm_cmd ( $self, $cmd, $cb = undef ) {
    return $self->_scm_cmd( $cmd, $self->{root}, $cb );
}

sub scm_init ( $self, $root, $cb = undef ) {
    return $self->_scm_cmd( [ 'init', $root ], undef, $cb );
}

sub scm_clone ( $self, $root, $uri, $cb = undef ) {
    return $self->_scm_cmd( [ 'clone', $uri, $root ], undef, $cb );
}

sub scm_id ( $self, $cb = undef ) {
    return $self->scm_cmd(
        [ qw[log -r . --template], q[{node|short}\n{phase}\n{join(tags,'\x00')}\n{activebookmark}\n{branch}\n{desc}\n{date|rfc3339date}\n{latesttag('re:^v\d+[.]\d+[.]\d+$') % '{tag}\x00{distance}'}] ],
        sub ($res) {
            if ($res) {
                my %res = (
                    node             => undef,
                    phase            => undef,
                    tags             => undef,
                    bookmark         => undef,
                    branch           => undef,
                    desc             => undef,
                    date             => undef,
                    release          => undef,
                    release_distance => undef,
                );

                ( $res{node}, $res{phase}, $res{tags}, $res{bookmark}, $res{branch}, $res{desc}, $res{date}, $res{release} ) = split /\n/sm, $res->{data}->[0];

                $res{tags} = $res{tags} ? [ split /\x00/sm, $res{tags} ] : undef;

                if ( $res{release} ) {
                    ( $res{release}, $res{release_distance} ) = split /\x00/sm, $res{release};

                    $res{release} = undef if $res{release} eq 'null';
                }

                $res->{data} = \%res;
            }

            return $cb ? $cb->($res) : $res;
        },
    );
}

sub scm_releases ( $self, $cb = undef ) {
    return $self->scm_cmd(
        [qw[tags --template {tag}]],
        sub ($res) {
            if ($res) {
                $res->{data} = [ sort grep {/\Av\d+[.]\d+[.]\d+\z/sm} $res->{data}->@* ];
            }

            return $cb ? $cb->($res) : $res;
        },
    );
}

sub scm_is_commited ( $self, $cb = undef ) {
    return $self->scm_cmd(
        [qw[status -mardu --subrepos]],
        sub ($res) {
            if ($res) {
                $res->{data} = defined $res->{data} ? 0 : 1;
            }

            return $cb ? $cb->($res) : $res;
        },
    );
}

sub scm_addremove ( $self, $cb = undef ) {
    return $self->scm_cmd( [qw[addremove --subrepos]], $cb );
}

sub scm_commit ( $self, $msg, $args = undef, $cb = undef ) {
    return $self->scm_cmd( [ qw[commit --subrepos -m], $msg, $args ? $args->@* : () ], $cb );
}

sub scm_push ( $self, $cb = undef ) {
    return $self->scm_cmd( ['push'], $cb );
}

sub scm_set_tag ( $self, $tags, $force = undef, $cb = undef ) {
    return $self->scm_cmd( [ 'tag', $force ? '--force' : (), is_plain_arrayref $tags ? $tags->@* : $tags, ], $cb );
}

sub scm_get_changesets ( $self, $tag = undef, $cb = undef ) {
    return $self->scm_cmd(
        [ $tag ? ( 'log', '-r', "$tag:" ) : 'log' ],
        sub ($res) {
            if ($res) {
                my $data;

                for my $line ( $res->{data}->@* ) {
                    my $changeset = {};

                    for my $field ( split /\n/sm, $line ) {
                        my ( $k, $v ) = split /:\s+/sm, $field, 2;

                        if ( exists $changeset->{$k} ) {
                            if ( is_plain_arrayref $changeset->{$k} ) {
                                push $changeset->{$k}->@*, $v;
                            }
                            else {
                                $changeset->{$k} = [ $changeset->{$k}, $v ];
                            }
                        }
                        else {
                            $changeset->{$k} = $v;
                        }
                    }

                    push $data->@*, $changeset;
                }

                $res->{data} = $data;
            }

            return $cb ? $cb->($res) : $res;
        },
    );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 103, 105, 110        | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 164                  | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::SCM::Hg

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
