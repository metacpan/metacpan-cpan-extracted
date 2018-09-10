package Pcore::Core::CV;

use Pcore -const;

use overload    #
  '&{}' => sub ( $self, @ ) {
    return sub { return $self->send(@_) }
  },
  fallback => 1;

const our $CB       => 0;
const our $IS_READY => 1;
const our $COUNTER  => 2;
const our $ROUSE_CB => 3;
const our $ARGS     => 4;

sub is_ready ($self) { return $self->[$IS_READY] }

sub begin ( $self, $cb = undef ) {
    ++$self->[$COUNTER];

    $self->[$CB] = $cb if @_ > 1;

    return $self;
}

sub end ($self) {
    return $self if --$self->[$COUNTER] > 0;

    my $cb = $self->[$CB];

    defined $cb ? $cb->($self) : $self->send();

    return $self;
}

sub recv ($self) {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]

    # already finished
    if ( $self->[$IS_READY] ) {
        return if !defined $self->[$ARGS];

        my $res = delete $self->[$ARGS];

        return wantarray ? $res->@* : $res->[0];
    }

    return Coro::rouse_wait( $self->[$ROUSE_CB] //= Coro::rouse_cb() );
}

sub send {    ## no critic qw[Subroutines::ProhibitBuiltinHomonyms]
    my $self = shift;

    # already finished
    return if $self->[$IS_READY];

    # mark as finished
    $self->[$IS_READY] = 1;

    # has rouse_cb
    if ( defined $self->[$ROUSE_CB] ) {

        # call rouse_cb
        delete( $self->[$ROUSE_CB] )->(@_);
    }
    else {

        # store args
        $self->[$ARGS] = [@_];
    }

    return;
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Core::CV

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
