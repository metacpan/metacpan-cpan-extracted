package Pcore::Util::Path::Poll;

use Pcore -role, -const, -export;
use Pcore::Util::Path::Poll::Tree;
use Pcore::Util::Path::Poll::File;
use Pcore::Util::Scalar qw[weaken];
use Time::HiRes qw[];

const our $DEFAULT_POLL_INTERVAL => 3;

const our $POLL_CREATED  => 1;
const our $POLL_MODIFIED => 2;
const our $POLL_REMOVED  => 3;

our $EXPORT = { POLL => [qw[$POLL_CREATED $POLL_MODIFIED $POLL_REMOVED]] };

our $POLL_INTERVAL = $DEFAULT_POLL_INTERVAL;
our $POLL          = {};
our $SIGNAL        = Coro::Signal->new;
our $THREAD;

sub poll_tree ( $self, @ ) {
    my $cb = pop;

    my $args = { @_[ 1 .. $#_ ] };

    my $poll = Pcore::Util::Path::Poll::Tree->new( {
        root     => $self->to_abs,
        cb       => $cb,
        interval => delete( $args->{interval} ) // $DEFAULT_POLL_INTERVAL,
        read_dir => $args,
    } );

    return $self->_add_poll($poll);
}

sub poll_file ( $self, @ ) {
    my $cb = pop;

    my $args = { @_[ 1 .. $#_ ] };

    my $poll = Pcore::Util::Path::Poll::File->new( {
        root     => $self->to_abs,
        cb       => $cb,
        interval => $args->{interval} // $DEFAULT_POLL_INTERVAL,
    } );

    return $self->_add_poll($poll);
}

sub _add_poll ( $self, $poll ) {
    $POLL_INTERVAL = $poll->{interval} if $poll->{interval} < $POLL_INTERVAL;

    $POLL->{ $poll->{id} } = $poll;

    weaken $POLL->{ $poll->{id} } if defined wantarray;

    if ($THREAD) {
        $SIGNAL->send if $SIGNAL->awaited;
    }
    else {
        $THREAD = Coro::async {
            while () {
                Coro::sleep $POLL_INTERVAL;

                for my $poll ( values $POLL->%* ) {
                    next if $poll->{last_checked} + $poll->{interval} > time;

                    $poll->{last_checked} = time;

                    $poll->scan;
                }

                $SIGNAL->wait if !$POLL->%*;
            }
        };
    }

    return $poll;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Path::Poll

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
