package Pcore::Util::Path1::Poll;

use Pcore -role, -const, -export;
use Pcore::Util::Scalar qw[is_plain_coderef];
use Time::HiRes qw[];
use Coro::Signal qw[];

const our $DEFAULT_POLL_INTERVAL => 3;

const our $POLL_CREATED  => 1;
const our $POLL_MODIFIED => 2;
const our $POLL_REMOVED  => 3;

our $EXPORT = { POLL => [qw[$POLL_CREATED $POLL_MODIFIED $POLL_REMOVED]] };

sub poll ( $self, @ ) {
    state $POLL_INTERVAL = $DEFAULT_POLL_INTERVAL;
    state $POLL;
    state $SIGNAL = Coro::Signal->new;
    state $thread;

    my $cb = is_plain_coderef $_[-1] ? pop : ();

    my $root_path = $self->to_abs;

    my $poll = $POLL->{$root_path} = {
        scan_root    => 1,                        # scan root path
        scan_tree    => 1,                        # scan tree if root is dir
        abs          => 0,                        # report absolute paths
        read_dir     => { @_[ 1 .. $#_ ] },
        path         => $root_path,
        interval     => $DEFAULT_POLL_INTERVAL,
        last_checked => 0,
        cb           => $cb,
    };

    $poll->{scan_root} = delete $poll->{read_dir}->{scan_root}                             if exists $poll->{read_dir}->{scan_root};
    $poll->{abs}       = delete $poll->{read_dir}->{abs}                                   if exists $poll->{read_dir}->{abs};
    $poll->{scan_tree} = delete $poll->{read_dir}->{scan_tree}                             if exists $poll->{read_dir}->{scan_tree};
    $poll->{interval}  = delete( $poll->{read_dir}->{interval} ) // $DEFAULT_POLL_INTERVAL if exists $poll->{read_dir}->{interval};
    $poll->{root_len}  = 1 + length $root_path;

    $POLL_INTERVAL = $poll->{interval} if $poll->{interval} < $POLL_INTERVAL;

    # initial scan
    if ( -e $root_path ) {

        # add root path
        $poll->{stat}->{$root_path} = [ Time::HiRes::stat($root_path) ] if $poll->{scan_root};

        $poll->{rel_path}->{$root_path} = '' if !$poll->{abs};

        # add child paths
        if ( $poll->{scan_tree} && -d _ && ( my $paths = $root_path->read_dir( $poll->{read_dir}->%*, abs => 1 ) ) ) {
            for my $path ( $paths->@* ) {
                $poll->{stat}->{$path} = [ Time::HiRes::stat($path) ];

                $poll->{rel_path}->{$path} = substr $path, $poll->{root_len} if !$poll->{abs};
            }
        }
    }

    if ($thread) {
        $SIGNAL->send if $SIGNAL->awaited;

        return;
    }

    $thread = Coro::async {
        while () {
            Coro::AnyEvent::sleep $POLL_INTERVAL;

            for my $poll ( values $POLL->%* ) {
                next if $poll->{last_checked} + $poll->{interval} > time;

                $poll->{last_checked} = time;

                my $stat;

                # scan
                if ( -e $poll->{path} ) {

                    # add root path
                    $stat->{ $poll->{path} } = [ Time::HiRes::stat $poll->{path} ] if $poll->{scan_root};

                    # add child paths
                    if ( $poll->{scan_tree} && -d _ && ( my $paths = $poll->{path}->read_dir( $poll->{read_dir}->%*, abs => 1 ) ) ) {
                        for my $path ( $paths->@* ) {
                            $stat->{$path} = [ Time::HiRes::stat($path) ];
                        }
                    }
                }

                my @changes;

                # scan created / modified paths
                for my $path ( keys $stat->%* ) {

                    # path is already exists
                    if ( exists $poll->{stat}->{$path} ) {

                        # last modify time was changed
                        if ( $poll->{stat}->{$path}->[9] != $stat->{$path}->[9] ) {
                            push @changes, [ $poll->{abs} ? $path : $poll->{rel_path}->{$path}, $POLL_MODIFIED ];
                        }
                    }

                    # new path was created
                    else {
                        if ( !$poll->{abs} ) {

                            # root
                            if ( $poll->{root_len} > length $path ) {
                                $poll->{rel_path}->{$path} = '';
                            }

                            # child
                            else {
                                $poll->{rel_path}->{$path} = substr $path, $poll->{root_len};
                            }

                            push @changes, [ $poll->{rel_path}->{$path}, $POLL_CREATED ];
                        }
                        else {
                            push @changes, [ $path, $POLL_CREATED ];
                        }
                    }

                    $poll->{stat}->{$path} = $stat->{$path};
                }

                # scan removed paths
                for my $path ( keys $poll->{stat}->%* ) {

                    # path was removed
                    if ( !exists $stat->{$path} ) {
                        delete $poll->{stat}->{$path};

                        push @changes, [ $poll->{abs} ? $path : delete $poll->{rel_path}->{$path}, $POLL_REMOVED ];
                    }
                }

                # call callback if has changes
                $poll->{cb}->( \@changes ) if @changes;
            }

            $SIGNAL->wait if !$POLL->%*;
        }
    };

    return;
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 16                   | Subroutines::ProhibitExcessComplexity - Subroutine "poll" with high complexity score (40)                      |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    3 | 113                  | ControlStructures::ProhibitDeepNests - Code structure is deeply nested                                         |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 51, 114              | ValuesAndExpressions::ProhibitEmptyQuotes - Quotes used with a string containing no non-whitespace characters  |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Path1::Poll

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
