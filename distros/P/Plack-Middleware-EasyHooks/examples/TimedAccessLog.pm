package Plack::Middleware::TimedAccessLog;

use parent qw(Plack::Middleware::EasyHooks Plack::Middleware::AccessLog);
use Time::HiRes;

sub before {
    my ($self, $env) = @_;

    $env->{TimedAccessLog} = {
        time   => Time::HiRes::gettimeofday(),
        length => 0,
    };
}

sub after {
    my ($self, $env, $res) = @_;

    my ($status, $header) = @$res;
    $env->{TimedAccessLog}->{status} = $status;
    $env->{TimedAccessLog}->{header} = $header;
}


sub filter {
    my ($self, $env, $chunk) = @_;

    $env->{TimedAccessLog}->{length} += length($chunk);

    return $chunk;
}

sub finalize {
    my ($self, $env) = @_;

    my $info   = $env->{TimedAccessLog}; 
    my $logger = $self->logger || sub { $env->{'psgi.errors'}->print(@_) };

    $logger->( $self->log_line($info->{status}, $info->{header}, $env, { time => $now - $info->{time}, content_length => $info->{length} }) );
}

1;

__END__

=head1 NAME

Plack::Middleware::TimedAccessLog - Reimplementation of core Plack::Middleware::AccessLog::Timed

=cut


