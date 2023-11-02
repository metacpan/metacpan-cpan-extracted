package Mojo::WebSocketProxy::RequestLogger;

use strict;
use warnings;
use Object::Pad;

class Mojo::WebSocketProxy::RequestLogger;

use Log::Any qw($log);
use UUID::Tiny;

our $VERSION = '0.15';    ## VERSION

=head1 NAME

Log::Any::Adapter::DERIV - standardised logging to STDERR and JSON file

=head1 SYNOPSIS

use Mojo::WebSocketProxy::RequestLogger;

my $logger = Mojo::WebSocketProxy::RequestLogger->new();

$logger->info('This is an info message');

=head1 DESCRIPTION

Mojo::WebSocketProxy::RequestLogger is a request logger for Mojo::WebSocketProxy.

=head1 METHODS

=head2 DOES

=over 4

=item B<DOES($role)>

Check if an object or class does a particular role.

=back

=head2 META

=over 4

=item B<META()>

Return the meta object for the class.

=back

=head2 new

=over 4

=item B<new()>

Create a new `Mojo::WebSocketProxy::RequestLogger` object.

=back

=cut

field $context;

our $log_handler = sub {
    my ($level, $message, $context, @params) = @_;

    if (scalar @params) {
        return $log->$level($message, @params);
    }

    return $log->$level($message, $context);
};

=head2 set_handler

set the handler for message logging

=cut

sub set_handler {
    my ($self, $custom_handler) = @_;
    $log_handler = $custom_handler;
}

BUILD {
    $context->{correlation_id} = UUID::Tiny::create_UUID_as_string(UUID::Tiny::UUID_V4);
}

=head2 infof

info format message logging

=cut

method infof($message, @params) {
    $log_handler->('infof', $message, $context, @params);
}

=head2 tracef

trace format message logging

=cut

method tracef($message, @params) {
    $log_handler->('tracef', $message, $context, @params);
}

=head2 errorf

error format message logging

=cut

method errorf($message, @params) {
    $log_handler->('errorf', $message, $context, @params);
}

=head2 warnf

warn format message logging

=cut

method warnf($message, @params) {
    $log_handler->('warningf', $message, $context, @params);
}

=head2 debugf

debug format message logging

=cut

method debugf($message, @params) {
    $log_handler->('debugf', $message, $context, @params);
}

=head2 critf

critical format message logging

=cut

method critf($message, @params) {
    $log_handler->('critf', $message, $context, @params);
}

=head2 info

info message logging

=cut

method info($message) {
    $log_handler->('info', $message, $context);
}

=head2 trace

trace message logging

=cut

method trace($message) {
    $log_handler->('trace', $message, $context);
}

=head2 error

error message logging

=cut

method error($message) {
    $log_handler->('error', $message, $context);
}

=head2 warn

warn message logging

=cut

method warn($message) {
    $log_handler->('warning', $message, $context);
}

=head2 debug

debug message logging

=cut

method debug($message) {
    $log_handler->('debug', $message, $context);
}

=head2 crit

crit message logging

=cut

method crit($message) {
    $log_handler->('crit', $message, $context);
}

=head2 get_context

get the value of context

=cut

method get_context() {
    return $context;
}

=head2 add_context_key

add a key in log context hash

=cut

method add_context_key($key, $value) {
    $context->{$key} = $value;
}

=head2 remove_context_key

remove key from context

=cut

method remove_context_key($key) {
    delete $context->{$key};
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>

=head1 COPYRIGHT AND LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.
