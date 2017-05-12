package Tapper::MCP::Net::Reset::PM211MIP;
our $AUTHORITY = 'cpan:TAPPER';
$Tapper::MCP::Net::Reset::PM211MIP::VERSION = '5.0.6';
use strict;
use warnings;

use LWP::UserAgent;
use Moose;

extends 'Tapper::Base';

sub reset_host
{
        my ($self, $host, $options) = @_;

        $self->log->info("Reboot via Infratec PM211MIP multi-socket outlet");

        my $ip       = $options->{ip};
        my $user     = $options->{user};
        my $passwd   = $options->{passwd};
        my $outletnr = $options->{outletnr}{$host};
        my $uri      = "http://$ip/sw?u=$user&p=$passwd&o=$outletnr&f=";
        my $uri_off  = $uri."off";
        my $uri_on   = $uri."on";

        my $ua = LWP::UserAgent->new;

        $self->log->info("turn off '$host' via $uri_off");
        my $response1 = $ua->get($uri_off)->decoded_content;

        my $sleep = 5;
        $self->log->info("sleep $sleep seconds");
        sleep $sleep;

        $self->log->info("turn on '$host' via $uri_on");
        my $response2 = $ua->get($uri_on)->decoded_content;

        my $error  = $response1 =~ /Done\./ && $response2 =~ /Done\./ ? 0 : 1;
        my $retval = $response1."\n".$response2;
        return ($error, $retval);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Tapper::MCP::Net::Reset::PM211MIP

=head1 DESCRIPTION

This is a plugin for Tapper.

It provides resetting a machine via the ethernet controllable PM211MIP
multi-socket outlet.

=head1 NAME

Tapper::MCP::Net::Reset::PM211MIP - Reset via Infratec PM211MIP multi-socket outlet

=head1

To use it add the following config to your Tapper config file:

 reset_plugin: PM211MIP
 reset_plugin_options:
   ip: 192.168.1.39
   user: admin
   passwd: secret
   outletnr:
     johnconnor: 1
     sarahconnor: 2

This configures Tapper MCP to use the PM211MIP plugin for reset and
gives it the configuration that the host C<johnconnor> is connected on
outlet number 0 and the host C<sarahconnor> on outlet number 1.

=head1 FUNCTIONS

=head2 reset_host ($self, $host, $options)

The primary plugin function.

It is called with the Tapper::MCP::Net object (for Tapper logging),
the hostname to reset and the options from the config file.

=head1 AUTHORS

=over 4

=item *

AMD OSRC Tapper Team <tapper@amd64.org>

=item *

Tapper Team <tapper-ops@amazon.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
