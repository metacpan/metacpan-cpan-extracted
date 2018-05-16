package TaskPipe::UserAgentManager::UserAgentHandler::Settings;

use Moose;

with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::UserAgentManager::UserAgentHandler::Settings

=head1 DESCRIPTION

Settings file for the TaskPipe::UserAgentManager::UserAgentHandler module

=head1 METHODS

=over

=item agent

The useragent string to use

=cut

has agent => (
    is => 'ro', 
    isa => 'Str', 
    default => 'Mozilla/5.0 (Windows NT 6.1; rv:52.0) Gecko/20100101 Firefox/52.0'
);


=item timeout

The request timeout

=cut

has timeout => (is => 'ro', isa => 'Int', default => 60 );


=item headers

The headers to send with the request

=cut

has headers => (is => 'ro', isa => 'HashRef', default => sub{{
    'Accept' => '*/*',
    'Accept-Encoding' => "gzip deflate br",
    'Accept-Language' => "en-USen;q=0.5",
    'Connection' => "keep-alive"
}});


=item request_methods

The methods this useragenthandler can handle

=back

=cut

has request_methods => (is => 'ro', isa => 'ArrayRef', default => sub{[
    'head',
    'get',
    'post',
    'put'
]});

=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;
1;
