package TaskPipe::UserAgentManager_ProxyNet;

use Moose;
with 'MooseX::ConfigCascade';
with 'TaskPipe::Role::RunInfo';
extends 'TaskPipe::UserAgentManager';
use Carp;

has max_rand => (is => 'ro', isa => 'Int', default => 4);
has cur_max => (is => 'rw', isa => 'Int', default => 0);
has cur_rno => (is => 'rw', isa => 'Int', default => 0);


sub set_max{
    my $self = shift;
    my $logger = Log::Log4perl->get_logger;
    $self->cur_max( 3 + int(rand( $self->max_rand + 0.5 ) ) );
    $logger->debug("Max requests on this ip set to ".$self->cur_max);
}


sub inc_rno{
    my $self = shift;

    my $logger = Log::Log4perl->get_logger;
    $self->cur_rno( $self->cur_rno + 1 );
    if ( $self->cur_rno >= $self->cur_max ){
        $logger->debug("Changing ip");
        $self->change_ip;
    } else {
        $logger->debug("Not changing IP");
    }
}


sub handle_failed_request{
    my ($self,$resp) = @_;
    my $logger = Log::Log4perl->get_logger;

    if ( ! $resp ){
        $logger->warn("REQUEST FAILED - got no response");
    } else {
        $logger->warn("REQUEST FAILED - got ".$resp->status_line." content was ".$resp->decoded_content." - retrying");
    }

    $self->refresh;
    $self->change_ip;
}


sub before_request{
    my ($self,@params) = @_;

    $self->inc_rno;
}



sub after_request{
    my ($self,$resp) = @_;

    $self->handle_failed_request($resp) unless $resp && $resp->status_line =~ /^200/;
}


=head1 NAME

TaskPipe::UserAgentManager_ProxyNet - base class for proxying useragents

=head1 DESCRIPTION

"Proxynet" useragents are ones that can change IP. If you are creating a useragent that can do this, it is suggested that you inherit from this class. A suggested basic format for your useragent package is as follows:

    package TaskPipe::UserAgentManager_ProxyNet_MyProxySystem;

    use Moose;
    extends 'TaskPipe::UserAgentManager_ProxyNet';

    sub init {
        my ($self) = @_;

        # do any initialisation
    }

    sub change_ip{
        my ($self) = @_;

        # do what is needed
        # to change the proxy ip
    }

    sub before_request{
        my ($self,$method,@param) = @_;

        # do something before each request?
    }

    sub after_request{
        my ($self,$resp,$method,@params) = @_;

        # do something after each request?
    }

    __PACKAGE__->meta->make_immutable;
    1;

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;

1;
