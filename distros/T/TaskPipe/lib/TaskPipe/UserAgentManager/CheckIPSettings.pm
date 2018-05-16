package TaskPipe::UserAgentManager::CheckIPSettings;

use Moose;
with 'MooseX::ConfigCascade';

=head1 NAME

TaskPipe::UserAgentManager::CheckIPSettings

=head1 DESCRIPTION

Settings for to use to check IP for L<TaskPipe::UserAgentManager>

=head1 METHODS

=over

=item url

The url to use to return originating IP

=cut

has url => (is => 'ro', isa => 'Str', default => 'http://checkip.dyndns.org');

=item regex

The regex to return the IP from the response

=cut

has regex => (is => 'ro', isa => 'Str', default => 'Current IP Address:\s*([\d\.]+)');


=item max_retries

The maximum number of times to retry if the request fails

=cut

has max_retries => (is => 'ro', isa => 'Int', default => 4);


=item retry_delay

The number of seconds to wait between retries if the request fails

=back

=cut

has retry_delay => (is => 'ro', isa => 'Int', default => 1);


=head1 AUTHOR

Tom Gracey <tomgracey@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Tom Gracey 2018

TaskPipe is free software, licensed under

    The GNU Public License Version 3

=cut


__PACKAGE__->meta->make_immutable;
1;
__END__
