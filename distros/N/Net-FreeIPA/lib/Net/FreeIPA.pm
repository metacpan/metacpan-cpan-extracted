package Net::FreeIPA;
# dzil abstract
# ABSTRACT: Net::FreeIPA is a perl FreeIPA JSON API client class
$Net::FreeIPA::VERSION = '3.0.2';
use strict;
use warnings;

use Net::FreeIPA::DummyLogger;

use parent qw(Net::FreeIPA::Base
              Net::FreeIPA::RPC
              Net::FreeIPA::API
              Net::FreeIPA::Common);

=head1 NAME

Net::FreeIPA is a perl FreeIPA JSON API client class

=head1 SYNOPSIS

'ipa user-find' equivalent using API call and basic result postprocessing.
The connection in this example will (try to) use kerberos authentication.
See L<Net::FreeIPA::RPC::new_client> for authentication details.

    my $fi = Net::FreeIPA->new("host.example.com");

    die("Failed to initialise the rest client") if ! $fi->{rc};

    if($fi->api_user_find("")) {
        print "Found ", scalar @{$fi->{result}}, " users\n";
    } else {
        print "Something went wrong\n";
    }


=head2 Private methods

=over

=item _initialize

Handle the actual initializtion of new. Return 1 on success, undef otherwise.

=over

=item log

An instance that can be used for logging (with error/warn/info/debug methods)
(e.g. L<LOG::Log4perl>).

=item debugapi

When true, log the JSON POST and JSON reply data with debug.

=back

All other arguments and options are passed to L<Net::FreeIPA::RPC::new_client>
during initialisation. (Check the presence of an C<rc> attribute for succesfull
initialisation of the underlying rest client. An error is logged in case of failure.)


=cut

sub _initialize
{
    my ($self, $hostname, %opts) = @_;

    $self->{log} = delete $opts{log} || Net::FreeIPA::DummyLogger->new();

    $self->{debugapi} = delete $opts{debugapi};

    # Pass all other options to new_client
    my $nc = $self->new_client($hostname, %opts) if $hostname;

    # Return 1, $self holds any errors from new_client in answer attribute
    return 1;
}

=pod

=back

=cut

1;
