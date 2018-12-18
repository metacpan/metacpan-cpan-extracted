package Pcore::API::SCM::Hg;

use Pcore -class, -res;
use Pcore::API::SCM::Const qw[:SCM_TYPE];
use Pcore::Util::Text qw[decode_utf8];
use Pcore::Util::Scalar qw[weaken is_plain_arrayref];

with qw[Pcore::API::SCM];

has capabilities => ( init_arg => undef );
has _server_proc => ( init_arg => undef );

our $SERVER_PROC;

sub _build_upstream ($self) {
    if ( -f "$self->{root}/.hg/hgrc" ) {
        my $hgrc = P->file->read_text("$self->{root}/.hg/hgrc");

        return Pcore::API::SCM::Upstream->new( { uri => $1, local_scm_type => $SCM_TYPE_HG } ) if $hgrc->$* =~ /default\s*=\s*(.+?)$/sm;
    }

    return;
}

# https://www.mercurial-scm.org/wiki/CommandServer
sub _server ( $self ) {
    if ( exists $self->{_server_proc} ) {
        return $self->{_server_proc};
    }
    elsif ( defined $SERVER_PROC ) {
        return $self->{_server_proc} = $SERVER_PROC;
    }
    else {
        local $ENV{HGENCODING} = 'UTF-8';

        $self->{_server_proc} = $SERVER_PROC = P->sys->run_proc(
            [qw[hg serve --config ui.interactive=True --cmdserver pipe]],
            stdin  => 1,
            stdout => 1,
            stderr => 1,
        );

        undef $SERVER_PROC->{client_stdout};
        undef $SERVER_PROC->{client_stderr};

        weaken $SERVER_PROC;

        # read capabilities
        $self->{capabilities} = $self->_read->[1];

        return $SERVER_PROC;
    }
}

sub _read ( $self ) {
    my $hg = $self->_server;

    my $header = $hg->{stdout}->read_chunk( 5, timeout => undef );

    if ( !defined $header ) {
        delete $self->{_server};

        return [ 'er', $hg->{stdout} ? 'Unknown error' : "$hg->{stdout}" ];
    }

    my $channel = substr $header->$*, 0, 1, $EMPTY;

    my $data = $hg->{stdout}->read_chunk( unpack 'L>', $header->$* );

    if ( !defined $data ) {
        delete $self->{_server};

        return [ 'er', $hg->{stdout} ? 'Unknown error' : "$hg->{stdout}" ];
    }

    return [ $channel, $data->$* ];
}

# NOTE status + pattern (status *.txt) not works under linux - http://bz.selenic.com/show_bug.cgi?id=4526
sub _scm_cmd ( $self, $cmd, $root = undef, $cb = undef ) {
    my $buf = join "\N{NULL}", $cmd->@*;

    $buf .= "\N{NULL}--repository\N{NULL}$root" if $root;

    $buf = Encode::encode( $Pcore::WIN_ENC, $buf, Encode::FB_CROAK );

    my $hg = $self->_server;

    $hg->{stdin}->write( "runcommand$LF" . pack( 'L>', length $buf ) . $buf );

    my $res = {};

    while () {
        my $data = $self->_read;

        # "er" channel - error + return
        if ( $data->[0] eq 'er' ) {
            push $res->{'e'}->@*, $data->[1];

            last;
        }

        # "r" channel - request is finished
        elsif ( $data->[0] eq 'r' ) {
            last;
        }
        else {
            chomp $data->[1];

            decode_utf8( $data->[1], encoding => $Pcore::WIN_ENC );

            push $res->{ $data->[0] }->@*, $data->[1];
        }
    }

    my $result;

    if ( exists $res->{e} ) {
        $result = res [ 500, join $SPACE, $res->{e}->@* ];
    }
    else {
        $result = res 200, $res->{o};
    }

    return $cb ? $cb->($result) : $result;
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

sub scm_update ( $self, $rev, $cb = undef ) {
    return $self->scm_cmd( [ 'update', '--clean', '--rev', $rev ], $cb );
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
                    date             => undef,
                    release          => undef,
                    release_distance => undef,
                );

                ( $res{node}, $res{phase}, $res{tags}, $res{bookmark}, $res{branch}, my $desc, $res{date}, $res{release} ) = split /\n/sm, $res->{data}->[0];

                $res{tags} = $res{tags} ? [ split /\x00/sm, $res{tags} ] : undef;

                if ( $res{release} ) {
                    ( $res{release}, $res{release_distance} ) = split /\x00/sm, $res{release};

                    $res{release} = undef if $res{release} eq 'null';
                }

                # fix release distance
                if ( $res{release} && defined $res{release_distance} && $res{release_distance} == 1 ) {
                    $res{release_distance} = 0 if $desc =~ /added tag.+$res{release}/smi;
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
## |    1 | 146                  | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
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
