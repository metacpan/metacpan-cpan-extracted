package Net::Libwebsockets::Loop;

use strict;
use warnings;

sub new {
    my ($class) = @_;

    return bless {
        pid => $$,
    }, $class;
}

sub set_lws_context {
    my ($self, $ctx) = @_;

    $self->{'lws_context'} = $ctx;

    #print "======= did set context: $ctx\n";

    $self->{'_set_timer_cr'} = $self->_create_set_timer_cr();

    $self->_do_later( $self->{'_set_timer_cr'} );

    return;
}

sub schedule_destroy_and_finish {
    my ($self, $deferred, $deferred_method, $arg) = @_;

    my $ctx = $self->{'lws_context'};

    $self->_do_later(
        sub {

            # This *MUST* happen from outside LWS, or else
            # LWS doesn’t properly clean up after itself.
            Net::Libwebsockets::_lws_context_destroy($ctx) if $ctx;

            $deferred->$deferred_method($arg);
        },
    );

    return;
}

sub _get_set_timer_cr {
    return $_[0]->{'_set_timer_cr'} || die "no timer cr set!";
}

sub set_timer {
    my ($self) = @_;

    $self->{'_set_timer_cr'}->();
}

sub DESTROY {
    my ($self) = @_;

    $self->_clear_timer();

    if ($$ == $self->{'pid'} && 'DESTRUCT' eq ${^GLOBAL_PHASE}) {
        warn "Destroying $self at global destruction; possible memory leak!\n";
    }

    return;
}

1;
