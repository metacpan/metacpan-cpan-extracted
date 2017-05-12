package Pcore::API::SCM::Server::Hg;

use Pcore -class, -result;
use Pcore::API::SCM qw[:CONST];
use Pcore::Util::Text qw[decode_utf8];
use Pcore::API::SCM::Upstream;
use Pcore::Util::Scalar qw[weaken];

with qw[Pcore::API::SCM::Server];

has capabilities => ( is => 'ro', isa => Str, init_arg => undef );

has _server_proc => ( is => 'ro', isa => InstanceOf ['Pcore::Util::PM::Proc'], init_arg => undef );

our $SERVER_PROC;

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

        P->pm->run_proc(
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
    $self->_server(
        sub($hg) {
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
        }
    );

    return;
}

sub scm_upstream ( $self, $root ) {
    if ( -f "$root/.hg/hgrc" ) {
        my $hgrc = P->file->read_text("$root/.hg/hgrc");

        return Pcore::API::SCM::Upstream->new( { uri => $1, local_scm_type => $SCM_TYPE_HG } ) if $hgrc->$* =~ /default\s*=\s*(.+?)$/sm;
    }

    return;
}

# NOTE status + pattern (status *.txt) not works under linux - http://bz.selenic.com/show_bug.cgi?id=4526
sub scm_cmd ( $self, $root, $cb, $cmd ) {
    my $buf = join qq[\x00], $cmd->@*;

    $buf .= "\x00--repository\x00$root" if $root;

    $buf = Encode::encode( $Pcore::WIN_ENC, $buf, Encode::FB_CROAK );

    $self->_server(
        sub ($hg) {
            $hg->stdin->push_write( qq[runcommand\x0A] . pack( 'L>', length $buf ) . $buf );

            my $res = {};

            my $read = sub ( $channel, $data ) {
                if ( $channel ne 'r' ) {
                    chomp $data;

                    decode_utf8( $data, encoding => $Pcore::WIN_ENC );

                    push $res->{$channel}->@*, $data;

                    $self->_read(__SUB__);
                }
                else {
                    my $api_res;

                    if ( exists $res->{e} ) {
                        $api_res = result [ 500, join q[ ], $res->{e}->@* ];
                    }
                    else {
                        $api_res = result 200, $res->{o};
                    }

                    $cb->($api_res);
                }

                return;
            };

            $self->_read($read);

            return;
        }
    );

    return;
}

sub scm_id ( $self, $root, $cb, $args ) {
    $self->scm_cmd(
        $root,
        sub ($res) {
            if ( $res->is_success ) {
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

            $cb->($res);

            return;
        },
        [ qw[log -r . --template], q[{node|short}\n{phase}\n{join(tags,'\x00')}\n{activebookmark}\n{branch}\n{desc}\n{date|rfc3339date}\n{latesttag('re:^v\d+[.]\d+[.]\d+$') % '{tag}\x00{distance}'}] ]
    );

    return;
}

sub scm_init ( $self, $root, $cb, $args = undef ) {
    $self->scm_cmd( undef, $cb, [ qw[init], $root ] );

    return;
}

sub scm_clone ( $self, $root, $cb, $args ) {
    my ( $path, $uri, %args ) = $args->@*;

    my @cmd = qw[clone];

    if ( $args{update} ) {
        push @cmd, '--updaterev', $args{update} if $args{update} ne '1';
    }
    else {
        push @cmd, '--noupdate';
    }

    push @cmd, $uri, $path;

    $self->scm_cmd( undef, $cb, \@cmd );

    return;
}

sub scm_releases ( $self, $root, $cb, $args ) {
    $self->scm_cmd(
        $root,
        sub ($res) {
            if ( $res->is_success ) {
                $res->{data} = [ sort grep {/\Av\d+[.]\d+[.]\d+\z/sm} $res->{data}->@* ];
            }

            $cb->($res);

            return;
        },
        [qw[tags --template {tag}]]
    );

    return;
}

sub scm_is_commited ( $self, $root, $cb, $args ) {
    $self->scm_cmd(
        $root,
        sub ($res) {
            if ( $res->is_success ) {
                $res->{data} = defined $res->{data} ? 0 : 1;
            }

            $cb->($res);

            return;
        },
        [qw[status -mardu --subrepos]]
    );

    return;
}

sub scm_addremove ( $self, $root, $cb, $args ) {
    $self->scm_cmd( $root, $cb, [qw[addremove --subrepos]] );

    return;
}

sub scm_commit ( $self, $root, $cb, $args ) {
    $self->scm_cmd( $root, $cb, [ qw[commit --subrepos -m], $args->@* ] );

    return;
}

sub scm_push ( $self, $root, $cb, $args ) {
    $self->scm_cmd( $root, $cb, [qw[push]] );

    return;
}

sub scm_set_tag ( $self, $root, $cb, $args ) {
    my ( $tag, %args ) = $args->@*;

    $tag = [$tag] if !ref $tag;

    my @cmd = ( 'tag', $tag->@* );

    push @cmd, '--force' if $args{force};

    $self->scm_cmd( $root, $cb, \@cmd );

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    2 | 104, 106, 112        | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    1 | 185                  | ValuesAndExpressions::RequireInterpolationOfMetachars - String *may* require interpolation                     |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::API::SCM::Server::Hg

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
