package Net::WAMP::RPCWorker;

=encoding utf-8

=head1 NAME

Net::WAMP::RPCWorker

=head1 SYNOPSIS

    if ($worker->caller_can_receive_progress()) {
        $worker->yield_progress( {}, \@args, \%args_kw );
    }

    $worker->error( {}, 'wamp.error.invalid_argument', \@args, \%args_kw );

    $worker->yield( {}, \@args, \%args_kw );

=head1 DESCRIPTION

This object is a convenience for doing RPC calls.

=cut

use strict;
use warnings;

use Types::Serialiser ();

use Net::WAMP::Messages ();

sub new {
    my ($class, $callee, $msg) = @_;

    return bless { _callee => $callee, _msg => $msg }, $class;
}

sub caller_can_receive_progress {
    my ($self) = @_;

    return $self->{'_msg'}->caller_can_receive_progress();
}

sub yield_progress {
    my ($self, $opts_hr) = @_;

    if (!$self->caller_can_receive_progress()) {
        die "Caller didn’t indicate acceptance of progressive results!";
    }

    $self->_not_already_finished();

    local $opts_hr->{'progress'} = $Types::Serialiser::true;
    local $self->{'_sent_YIELD'};   #make this flag not actually set

    return $self->yield($opts_hr, @_[ 2 .. $#_ ]);
}

sub yield {
    my ($self, $opts_hr, @payload) = @_;

    $self->_not_already_finished();

    my $yield = $self->{'_callee'}->send_YIELD(
        $self->{'_msg'}->get('Request'),
        $opts_hr,
        @payload,
    );

    $self->{'_sent_YIELD'} = 1;

    return $yield
}

sub error {
    my ($self, $details_hr, $err_uri, @args) = @_;

    $self->_not_already_finished();

    return $self->{'_callee'}->send_ERROR(
        $self->{'_msg'}->get('Request'),
        $details_hr,
        $err_uri,
        @args,
    );
}

#----------------------------------------------------------------------

sub _not_already_finished {
    my ($self, $msg) = @_;

    die 'Already sent YIELD!' if $self->{'_sent_YIELD'};

    return;
}

1;
