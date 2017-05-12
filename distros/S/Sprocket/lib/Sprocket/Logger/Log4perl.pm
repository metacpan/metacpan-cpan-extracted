package Sprocket::Logger::Log4perl;

use strict;
use warnings;
use Log::Log4perl;
use Log::Log4perl::Level;

our %levels = (
    0 => 'fatal',
    1 => 'error',
    2 => 'warn',
    3 => 'info',
    4 => 'debug',
);

sub new {
    my ($class,$config) = @_;
    die "Can't open Log4perl config ($config)" unless (ref $config or -r $config);
    Log::Log4perl::init( $config );
    return bless {}, $class;
}

sub put {
    my ($self, $sprocket, $opts) = @_;

    my $lvl = $levels{ $opts->{v} } || $levels{ 4 };

    $self->get_logger->$lvl( $opts->{msg} );
}

sub get_logger {
    my $self = shift;
    return Log::Log4perl::get_logger(@_);
}

1;
