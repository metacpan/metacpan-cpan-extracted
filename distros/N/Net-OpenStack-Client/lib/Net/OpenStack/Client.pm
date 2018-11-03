package Net::OpenStack::Client;
$Net::OpenStack::Client::VERSION = '0.1.4';
use strict;
use warnings;

use parent qw(
    Net::OpenStack::Client::API
    Net::OpenStack::Client::Auth
    Net::OpenStack::Client::Base
    Net::OpenStack::Client::REST
);

# ABSTRACT: OpenStack REST API client

=head1 NAME

Net::OpenStack::Client

=head1 SYNOPSIS

Example usage:
    use Net::OpenStack::Client;
    ...
    my $cl = Net::OpenStack::Client->new(openrc => '/home/admin/.openrc');

For basic reporting:
    use Net::OpenStack::Client;
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($INFO);
    ...
    my $cl = Net::OpenStack::Client->new(
        openrc => '/home/admin/.openrc',
        log => Log::Log4perl->get_logger()
        );

For debugging, including full JSON request / repsonse and headers (so contains sensitive data!):
    use Net::OpenStack::Client;
    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);
    ...
    my $cl = Net::OpenStack::Client->new(
        openrc => '/home/admin/.openrc',
        log => Log::Log4perl->get_logger(),
        debugapi => 1
        );

=head2 Public methods

=over

=item new

Options

=over

=item log

An instance that can be used for logging (with error/warn/info/debug methods)
(e.g. L<LOG::Log4perl>).

=item debugapi

When true, log the request and response body and headers with debug.

=back

If more options are definded, e.g. C<openrc>, they are passed to
passed to L<Net::OpenStack::Client::Auth::login>.
(If no other options are defined, C<login> is not called).

=cut

# return 1 on success
sub _initialize
{
    my ($self, %opts) = @_;

    $self->{log} = delete $opts{log};
    $self->{debugapi} = delete $opts{debugapi};

    # Initialise the REST::Client
    $self->_new_client();

    # Login, get token and gather services
    $self->login(%opts) if scalar keys %opts;

    return 1;
}

=pod

=back

=cut

1;
