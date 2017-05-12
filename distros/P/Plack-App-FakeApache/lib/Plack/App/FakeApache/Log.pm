package Plack::App::FakeApache::Log;

use Moose;

use Apache2::Const -compile => qw(:log);
use APR::Const;

has logger => (
    is => 'rw',
    default => sub { sub { 1 } },
);

sub log_error {
    my ($self, @message) = @_;

    $self->logger->(@message);
}

sub log_serror {
    my ($self, $file, $line, $level, $status, @message) = @_;

    $self->logger->(@message);
}

sub log_rerror {
    my ($self, $file, $line, $level, $status, @message) = @_;

    $self->logger->(@message);
}

sub log_reason {
    my ($self, $message, $filename) = @_;

    $self->logger->($message);
}

my %loglevel = (
    emerg  => Apache2::Const::LOG_EMERG,
    alert  => Apache2::Const::LOG_ALERT,
    crit   => Apache2::Const::LOG_CRIT,
    err    => Apache2::Const::LOG_ERR,
    warn   => Apache2::Const::LOG_WARNING,
    notice => Apache2::Const::LOG_NOTICE,
    info   => Apache2::Const::LOG_INFO,
    debug  => Apache2::Const::LOG_DEBUG,
);

for my $level (keys %loglevel) {
    no strict 'refs';

    *{$level} = sub {
        my ($self, @message) = @_;
        my ($package, $filename, $line) = caller;

        $self->log_serror(
            $filename, $line, $loglevel{$level}, APR::Const::SUCCESS, @message
        );
    }
}

sub LOG_MARK {
    my ($package, $filename, $line) = caller;

    return ($filename, $line);
}

*Apache2::Log::LOG_MARK = \&LOG_MARK;

1;
