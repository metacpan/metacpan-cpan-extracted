# $Id: /mirror/coderepos/lang/perl/Mvalve/trunk/lib/Mvalve/Writer.pm 66313 2008-07-17T04:29:13.361349Z daisuke  $

package Mvalve::Writer;
use Moose;
use Mvalve::Const;
use Mvalve::Types;
use Mvalve::Message;

extends 'Mvalve::Base';

__PACKAGE__->meta->make_immutable;

no Moose;

sub insert {
    my ($self, %args) = @_;

    my $message = $args{message};

    my $qs = $self->queue_set;

    my %data = (
        destination => $message->header( &Mvalve::Const::DESTINATION_HEADER ),
        message => $message->serialize()
    );

    $self->log(
        action      => "enqueue",
        destination => $data{destination},
    );

    # Choose one of the queues, depending on the headers
    my $table;
    if ($message->header( &Mvalve::Const::EMERGENCY_HEADER ) ) {
        $table = $qs->choose_table( 'emergency' );
    } elsif ($message->header( &Mvalve::Const::DURATION_HEADER ) ) {
        return $self->defer(message => $message);
    } else {
        $table = $qs->choose_table();
    }

    Mvalve::trace( "insert message '" . $message->id() . "' to $table" )
        if &Mvalve::Const::MVALVE_TRACE;

    $self->q_insert(
        table => $table,
        data => \%data,
    );
}

1;

__END__

=head1 NAME

Mvalve::Writer - Mvalve Writer

=head1 METHODS

=head2 insert 

Inserts into the normal queue

=cut