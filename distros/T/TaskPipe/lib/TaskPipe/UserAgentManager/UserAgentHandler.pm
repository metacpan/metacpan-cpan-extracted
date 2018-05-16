package TaskPipe::UserAgentManager::UserAgentHandler;

use Moose;
use Module::Runtime 'require_module';
with 'MooseX::ConfigCascade';
with 'TaskPipe::Role::MooseType_UserAgentType';

has settings => (is => 'ro', isa => __PACKAGE__.'::Settings', default => sub{
    my $module = __PACKAGE__.'::Settings';
    require_module( $module );
    $module->new;
});

has ua => (is => 'rw', isa => 'UserAgentType', lazy => 1, builder => 'build_ua');
#has thread_id => (is => 'rw', isa => 'Str');
#has job_id => (is => 'rw', isa => 'Str');
has gm => (is => 'rw', isa => 'TaskPipe::SchemaManager');
has run_info => (is => 'rw', isa => 'TaskPipe::RunInfo', default => sub{
    TaskPipe::RunInfo->new;
});

sub build_ua{
    my $self = shift;

    my $ua = LWP::UserAgent->new;
    $ua->cookie_jar( {} );
    $ua->agent( $self->settings->agent );
    $ua->timeout( $self->settings->timeout );
    foreach my $header_name ( %{$self->settings->headers} ){
        $ua->default_header($header_name => $self->settings->headers->{$header_name} );
    }

    return $ua;
}

sub call{
    my ($self,$method,@params) = @_;

    my $resp = $self->ua->$method(@params);

    return $resp;

}


sub clear_cookies{
    my ($self) = @_;

    $self->ua->cookie_jar({});
}

=head1 NAME

TaskPipe::UserAgentManager::UserAgentHandler - standard useragent handler

=head1 DESCRIPTION

This is the base useragent handler module, which defines the useragent. You can tell L<TaskPipe::Task_Scrape> to use this module, by specifying

    ua_handler_module: TaskPipe::UserAgentManager::UserAgentHandler

in the L<TaskPipe::Task_Scrape::Settings> section of the project config

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut

__PACKAGE__->meta->make_immutable;
1;
