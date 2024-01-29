#!/usr/bin/perl
use warnings;
use strict;
use feature qw{ say };

{

    package Stream;
    use Moo::Role;

    requires qw{ first state has_state code };

    sub next {
        my ($self) = @_;
        return $self->state( $self->first ) unless $self->has_state;
        return $self->state( $self->code( $self->state ) );
    }
}

{

    package Stream::Sequence::Arithmetic;
    use Moo::Role;
    use MooX::Role::Parameterized;
    with 'Stream';

    role {
        my ( $params, $mop ) = @_;
        $mop->has( state => ( is => 'rw', predicate => 1 ) );
        $mop->method( first => sub { $params->{first} } );
        $mop->method(
            code => sub {
                my ( $self, $previous ) = @_;
                return $previous + $params->{difference};
            }
        );
    };
}

{

    package Stream::TenPlusTen;
    use Moo;

    use MooX::Role::Parameterized::With;
    with 'Stream::Sequence::Arithmetic' => { first => 10, difference => 10 };

}

sub stream_average {
    my ($stream) = @_;
    my $count    = 0;
    my $sum      = 0;
    while (1) {
        ++$count;
        my $n = $stream->next;
        $sum += $n;
        say $count, "\t$n\t$sum / $count\t", $sum / $count;
        sleep 1;
    }
}

stream_average( 'Stream::TenPlusTen'->new() );
